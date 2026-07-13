#!/usr/bin/env python3
"""Calculate CLIProxyAPI subscription payments from CPA Usage Keeper.

The payment rule matches ``omniroute-payment.py``:

1. Every included key receives an equal base allocation, capped so the total
   base pool cannot exceed the subscription.
2. The fraction of the subscription covered by that base pool determines how
   much of the average usage cost is covered equally for every key.
3. That covered usage-cost share is subtracted from every key's usage.
4. The remaining subscription payment is split between keys whose uncovered
   usage remains positive, proportionally to that remaining usage.

This makes a zero base contribution a pure usage-proportional split, while a
base contribution at or above the equal per-key subscription share produces an
effectively equal split.

Usage and estimated cost come from CPA Usage Keeper's authenticated analysis
API. The script logs in inside the remote keeper container, so the login password
does not leave the container or appear in the local process list.
"""

from __future__ import annotations

import argparse
import calendar
import datetime as dt
import json
import os
import shlex
import subprocess
import sys
from dataclasses import dataclass
from decimal import Decimal, ROUND_DOWN, ROUND_HALF_UP, getcontext
from typing import Any
from urllib.parse import urlencode
from zoneinfo import ZoneInfo


# --- Adjustable billing constants -------------------------------------------------

SUBSCRIPTION_USD = Decimal("200")
BASE_CONTRIBUTION_USD = Decimal("10")
DEFAULT_TIME_ZONE = "Europe/Moscow"

# Active keys without usage still participate in the base split. Historical keys
# no longer returned by Keeper are included if they have usage in the period.
INCLUDE_ACTIVE_KEYS_WITHOUT_USAGE = True
INCLUDE_INACTIVE_KEYS_WITH_USAGE = True

# Remote CPA Usage Keeper location. Can also be overridden by CLI/env.
DEFAULT_HOST = os.environ.get("CLIPROXYAPI_HOST", "whale")
DEFAULT_CONTAINER = os.environ.get("CLIPROXYAPI_KEEPER_CONTAINER", "cliproxyapi-usage-keeper")
DEFAULT_BASE_URL = os.environ.get(
    "CLIPROXYAPI_KEEPER_URL",
    "http://127.0.0.1:8080/usage/api/v1",
)


# --- Internal constants -----------------------------------------------------------

getcontext().prec = 28
MONEY = Decimal("0.01")
FIRST_EVENT_PAGE_SIZE = 20
FIRST_EVENT_VALUES = {"first", "first-event", "first_event"}

REMOTE_SESSION_PREFIX = r"""
set -eu

base_url="${BASE_URL%/}"

if [ -z "${LOGIN_PASSWORD:-}" ]; then
  echo 'CPA Usage Keeper LOGIN_PASSWORD is not set in the container' >&2
  exit 1
fi

escaped_password="$(printf '%s' "$LOGIN_PASSWORD" | sed 's/\\/\\\\/g; s/"/\\"/g')"
if ! login_headers="$(
  wget -S -O /dev/null \
    --header 'Content-Type: application/json' \
    --header 'X-CPA-Usage-Keeper-Request: fetch' \
    --post-data "{\"password\":\"$escaped_password\"}" \
    "$base_url/auth/login" 2>&1
)"; then
  echo 'Failed to log in to CPA Usage Keeper inside the container' >&2
  exit 1
fi

cookie="$(
  printf '%s\n' "$login_headers" \
    | sed -n 's/^[[:space:]]*[Ss]et-[Cc]ookie:[[:space:]]*\([^;]*\).*/\1/p' \
    | head -1 \
    | tr -d '\r'
)"
if [ -z "$cookie" ]; then
  echo 'CPA Usage Keeper login did not return a session cookie' >&2
  exit 1
fi

cleanup() {
  wget -q -O /dev/null \
    --header "Cookie: $cookie" \
    --header 'X-CPA-Usage-Keeper-Request: fetch' \
    --post-data '{}' \
    "$base_url/auth/logout" >/dev/null 2>&1 || true
}
trap cleanup EXIT

fetch() {
  wget -qO- --header "Cookie: $cookie" "$base_url/$1"
}
"""


@dataclass(frozen=True)
class ApiKey:
    id: str
    name: str
    display_key: str | None
    is_active: bool


@dataclass(frozen=True)
class Usage:
    usage_usd: Decimal
    requests: int


@dataclass(frozen=True)
class BillingRow:
    key: ApiKey
    usage_usd: Decimal
    equal_share_usd: Decimal
    usage_after_share_usd: Decimal
    positive_usage_after_share_usd: Decimal
    base_usd: Decimal
    extra_usd: Decimal
    payment_usd: Decimal
    requests: int


@dataclass(frozen=True)
class Boundary:
    value: dt.datetime
    api_value: str
    date_only: bool


@dataclass(frozen=True)
class FirstEvent:
    id: str
    timestamp: str
    api_key: str
    model: str


def money(value: Decimal) -> Decimal:
    return value.quantize(MONEY, rounding=ROUND_HALF_UP)


def money_str(value: Decimal) -> str:
    rounded = money(value)
    sign = "-" if rounded < 0 else ""
    return f"{sign}${abs(rounded):,.2f}"


def decimal_from_json(value: Any) -> Decimal:
    if value is None:
        return Decimal("0")
    if isinstance(value, Decimal):
        return value
    return Decimal(str(value))


def parse_usd(value: str) -> Decimal:
    try:
        amount = Decimal(value.strip().removeprefix("$"))
    except Exception as error:
        raise argparse.ArgumentTypeError(f"invalid USD amount: {value}") from error
    if amount < 0:
        raise argparse.ArgumentTypeError(f"USD amount must be non-negative: {value}")
    return amount


def add_months(value: dt.datetime, months: int) -> dt.datetime:
    month_index = value.month - 1 + months
    year = value.year + month_index // 12
    month = month_index % 12 + 1
    day = min(value.day, calendar.monthrange(year, month)[1])
    return value.replace(year=year, month=month, day=day)


def parse_datetime(value: str, tz: ZoneInfo) -> dt.datetime:
    normalized = value.strip()
    if normalized.endswith("Z"):
        normalized = normalized[:-1] + "+00:00"
    try:
        parsed = dt.datetime.fromisoformat(normalized)
    except ValueError as error:
        raise argparse.ArgumentTypeError(f"invalid ISO datetime: {value}") from error
    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=tz)
    return parsed.astimezone(tz)


def parse_boundary(value: str, tz: ZoneInfo, *, end: bool) -> Boundary:
    raw = value.strip()
    if not raw:
        raise argparse.ArgumentTypeError("empty date/time value")

    keyword = raw.casefold()
    if keyword in {"today", "yesterday"}:
        date_value = dt.datetime.now(tz).date()
        if keyword == "yesterday":
            date_value -= dt.timedelta(days=1)
    else:
        try:
            date_value = dt.date.fromisoformat(raw)
        except ValueError:
            date_value = None

    if date_value is not None:
        time_value = dt.time.max if end else dt.time.min
        return Boundary(
            value=dt.datetime.combine(date_value, time_value, tzinfo=tz),
            api_value=date_value.isoformat(),
            date_only=True,
        )

    parsed = parse_datetime(raw, tz)
    return Boundary(value=parsed, api_value=parsed.isoformat(), date_only=False)


def default_period(tz: ZoneInfo) -> tuple[Boundary, Boundary]:
    current_month_start = dt.datetime.now(tz).date().replace(day=1)
    previous_month_end = current_month_start - dt.timedelta(days=1)
    previous_month_start = previous_month_end.replace(day=1)
    return (
        parse_boundary(previous_month_start.isoformat(), tz, end=False),
        parse_boundary(previous_month_end.isoformat(), tz, end=True),
    )


def period_from_args(args: argparse.Namespace) -> tuple[Boundary | None, Boundary, ZoneInfo]:
    tz = ZoneInfo(args.time_zone)

    if args.date_from is None and args.date_through is None:
        default_start, default_through = default_period(tz)
        return default_start, default_through, tz

    through = parse_boundary(args.date_through or "yesterday", tz, end=True)

    start: Boundary | None
    if args.date_from is None:
        start_value = add_months(
            dt.datetime.combine(through.value.date(), dt.time.min, tzinfo=tz),
            -1,
        )
        start = Boundary(start_value, start_value.isoformat(), False)
    elif args.date_from.strip().casefold() in FIRST_EVENT_VALUES:
        start = None
    else:
        start = parse_boundary(args.date_from, tz, end=False)

    if start is not None and through.value < start.value:
        raise SystemExit(
            f"--through must not be before --from: {through.value.isoformat()} < {start.value.isoformat()}"
        )

    return start, through, tz


def split_skip_keys(values: list[str]) -> set[str]:
    skipped: set[str] = set()
    for value in values:
        for item in value.split(","):
            item = item.strip()
            if item:
                skipped.add(item.casefold())
    return skipped


def key_matches_skip(key: ApiKey, skipped: set[str]) -> bool:
    candidates = [key.id, key.name]
    if key.display_key:
        candidates.append(key.display_key)
    return any(candidate.casefold() in skipped for candidate in candidates)


def endpoint(path: str, params: dict[str, Any] | None = None) -> str:
    if not params:
        return path
    return f"{path}?{urlencode(params)}"


def load_remote_json(
    *,
    host: str,
    container: str,
    base_url: str,
    endpoints: list[str],
) -> list[Any]:
    fetch_commands = ["printf '['"]
    for index, request_endpoint in enumerate(endpoints):
        if index:
            fetch_commands.append("printf ','")
        fetch_commands.append(f"fetch {shlex.quote(request_endpoint)}")
    fetch_commands.extend(["printf ']\\n'", ""])
    remote_script = REMOTE_SESSION_PREFIX + "\n".join(fetch_commands)

    remote_command = shlex.join(
        [
            "sudo",
            "podman",
            "exec",
            "-i",
            container,
            "env",
            f"BASE_URL={base_url.rstrip('/')}",
            "sh",
        ]
    )
    command = ["ssh", host, remote_command]
    result = subprocess.run(
        command,
        input=remote_script,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        raise SystemExit(
            "Failed to query CPA Usage Keeper over SSH.\n"
            f"Command: ssh {host} {remote_command}\n"
            f"stdout:\n{result.stdout}\n"
            f"stderr:\n{result.stderr}"
        )

    try:
        payload = json.loads(result.stdout, parse_float=Decimal)
    except json.JSONDecodeError as error:
        raise SystemExit(f"CPA Usage Keeper returned non-JSON output:\n{result.stdout}") from error
    if not isinstance(payload, list) or len(payload) != len(endpoints):
        raise SystemExit("CPA Usage Keeper returned an unexpected response count")
    return payload


def discover_first_event(
    *,
    host: str,
    container: str,
    base_url: str,
    through: Boundary,
    tz: ZoneInfo,
) -> tuple[Boundary, FirstEvent]:
    current_month_start = dt.datetime.now(tz).replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    retention_start = add_months(current_month_start, -1)
    if through.value < retention_start:
        raise SystemExit(
            "CPA Usage Keeper only exposes custom event searches from the first day of the previous month; "
            f"the requested end is before {retention_start.date().isoformat()}"
        )

    params = {
        "range": "custom",
        "start": retention_start.date().isoformat(),
        "end": through.api_value,
        "page": 1,
        "page_size": FIRST_EVENT_PAGE_SIZE,
    }
    first_page = load_remote_json(
        host=host,
        container=container,
        base_url=base_url,
        endpoints=[endpoint("usage/events", params)],
    )[0]

    total_count = int(first_page.get("total_count") or 0)
    total_pages = int(first_page.get("total_pages") or 0)
    if total_count <= 0 or total_pages <= 0:
        raise SystemExit("No CPA Usage Keeper events found in the requested period")

    last_page = first_page
    if total_pages != 1:
        params["page"] = total_pages
        last_page = load_remote_json(
            host=host,
            container=container,
            base_url=base_url,
            endpoints=[endpoint("usage/events", params)],
        )[0]

    events = last_page.get("events") or []
    if not events:
        raise SystemExit("CPA Usage Keeper returned an empty final event page")
    event = events[-1]
    timestamp = str(event.get("timestamp") or "")
    if not timestamp:
        raise SystemExit("CPA Usage Keeper's first event has no timestamp")

    boundary = Boundary(
        value=parse_datetime(timestamp, tz),
        api_value=timestamp,
        date_only=False,
    )
    return boundary, FirstEvent(
        id=str(event.get("id") or ""),
        timestamp=timestamp,
        api_key=str(event.get("api_key") or "unknown"),
        model=str(event.get("model") or "unknown"),
    )


def parse_keeper_payload(
    keys_payload: dict[str, Any],
    analysis_payload: dict[str, Any],
) -> tuple[list[ApiKey], dict[str, Usage]]:
    keys = [
        ApiKey(
            id=str(item["id"]),
            name=str(item.get("keyAlias") or item.get("label") or item.get("displayKey") or item["id"]),
            display_key=str(item["displayKey"]) if item.get("displayKey") else None,
            is_active=True,
        )
        for item in keys_payload.get("items", [])
    ]

    cost_breakdown = analysis_payload.get("cost_breakdown") or {}
    if not bool(cost_breakdown.get("cost_available")):
        raise SystemExit("CPA Usage Keeper cannot calculate complete costs for this period; check model pricing")

    usage: dict[str, Usage] = {}
    historical_names: dict[str, str] = {}
    missing_cost_labels: list[str] = []
    for item in analysis_payload.get("api_key_composition", []):
        key_id = str(item.get("key") or "")
        if not key_id:
            continue
        label = str(item.get("label") or key_id)
        if not bool(item.get("cost_available")):
            missing_cost_labels.append(label)
            continue
        usage[key_id] = Usage(
            usage_usd=decimal_from_json(item.get("cost_usd")),
            requests=int(item.get("requests") or 0),
        )
        historical_names[key_id] = label

    if missing_cost_labels:
        raise SystemExit(
            "CPA Usage Keeper has API keys with unavailable costs: " + ", ".join(sorted(missing_cost_labels))
        )

    known_key_ids = {key.id for key in keys}
    for key_id in sorted(set(usage) - known_key_ids):
        keys.append(
            ApiKey(
                id=key_id,
                name=historical_names.get(key_id, f"unknown:{key_id}"),
                display_key=None,
                is_active=False,
            )
        )

    return keys, usage


def include_key(key: ApiKey, usage: Usage | None) -> bool:
    if INCLUDE_ACTIVE_KEYS_WITHOUT_USAGE and key.is_active:
        return True
    if INCLUDE_INACTIVE_KEYS_WITH_USAGE and usage is not None and usage.usage_usd != 0:
        return True
    return False


def allocate_cents(total: Decimal, weights: dict[str, Decimal]) -> dict[str, Decimal]:
    if total <= 0 or not weights:
        return {key_id: Decimal("0") for key_id in weights}

    weight_total = sum(weights.values(), Decimal("0"))
    if weight_total <= 0:
        return {key_id: Decimal("0") for key_id in weights}

    total_cents = int((total * 100).quantize(Decimal("1"), rounding=ROUND_HALF_UP))
    allocation: dict[str, int] = {}
    fractions: list[tuple[Decimal, str]] = []

    for key_id, weight in weights.items():
        exact_cents = Decimal(total_cents) * weight / weight_total
        whole_cents = int(exact_cents.to_integral_value(rounding=ROUND_DOWN))
        allocation[key_id] = whole_cents
        fractions.append((exact_cents - whole_cents, key_id))

    remaining_cents = total_cents - sum(allocation.values())
    for _fraction, key_id in sorted(fractions, reverse=True)[:remaining_cents]:
        allocation[key_id] += 1

    return {key_id: Decimal(cents) / 100 for key_id, cents in allocation.items()}


def allocate_equal_cents(total: Decimal, key_ids: list[str]) -> dict[str, Decimal]:
    if total <= 0 or not key_ids:
        return {key_id: Decimal("0") for key_id in key_ids}

    total_cents = int((total * 100).quantize(Decimal("1"), rounding=ROUND_HALF_UP))
    cents_per_key, remainder = divmod(total_cents, len(key_ids))
    return {
        key_id: Decimal(cents_per_key + (1 if index < remainder else 0)) / 100
        for index, key_id in enumerate(key_ids)
    }


def calculate_bill(
    keys: list[ApiKey],
    usage_by_key: dict[str, Usage],
    skipped: set[str],
    subscription_usd: Decimal,
    base_contribution_usd: Decimal,
) -> dict[str, Any]:
    included_keys: list[ApiKey] = []
    excluded_keys: list[ApiKey] = []
    matched_skips: set[str] = set()

    for key in keys:
        usage = usage_by_key.get(key.id)
        if key_matches_skip(key, skipped):
            excluded_keys.append(key)
            matched_skips.update(
                candidate.casefold()
                for candidate in [key.id, key.name, key.display_key or ""]
                if candidate.casefold() in skipped
            )
            continue
        if include_key(key, usage):
            included_keys.append(key)

    if not included_keys:
        raise SystemExit("No keys left in the payment calculation after applying filters")

    key_count = len(included_keys)
    total_usage_usd = sum(
        (usage_by_key.get(key.id, Usage(Decimal("0"), 0)).usage_usd for key in included_keys),
        Decimal("0"),
    )
    subscription_total_usd = money(subscription_usd)
    average_usage_usd = total_usage_usd / key_count
    requested_base_total_usd = base_contribution_usd * key_count
    target_base_total_usd = min(requested_base_total_usd, subscription_total_usd)
    bases = allocate_equal_cents(target_base_total_usd, [key.id for key in included_keys])
    base_total_usd = sum(bases.values(), Decimal("0"))
    base_coverage_fraction = (
        base_total_usd / subscription_total_usd if subscription_total_usd > 0 else Decimal("0")
    )
    equal_share_usd = average_usage_usd * base_coverage_fraction
    remaining_subscription_usd = subscription_total_usd - base_total_usd

    weights: dict[str, Decimal] = {}
    intermediate: dict[str, tuple[Decimal, Decimal, int]] = {}
    for key in included_keys:
        usage = usage_by_key.get(key.id, Usage(Decimal("0"), 0))
        usage_after_share = usage.usage_usd - equal_share_usd
        positive_after_share = max(usage_after_share, Decimal("0"))
        intermediate[key.id] = (usage.usage_usd, usage_after_share, usage.requests)
        if positive_after_share > 0:
            weights[key.id] = positive_after_share

    extras = allocate_cents(remaining_subscription_usd, weights)
    unallocated_usd = money(remaining_subscription_usd) if remaining_subscription_usd > 0 and not weights else Decimal("0")

    rows = []
    for key in included_keys:
        usage_usd, usage_after_share, requests = intermediate[key.id]
        positive_after_share = max(usage_after_share, Decimal("0"))
        base_usd = bases.get(key.id, Decimal("0"))
        extra_usd = extras.get(key.id, Decimal("0"))
        rows.append(
            BillingRow(
                key=key,
                usage_usd=usage_usd,
                equal_share_usd=equal_share_usd,
                usage_after_share_usd=usage_after_share,
                positive_usage_after_share_usd=positive_after_share,
                base_usd=base_usd,
                extra_usd=extra_usd,
                payment_usd=base_usd + extra_usd,
                requests=requests,
            )
        )

    skipped_usage_usd = sum(
        (usage_by_key.get(key.id, Usage(Decimal("0"), 0)).usage_usd for key in excluded_keys),
        Decimal("0"),
    )
    unmatched_skips = sorted(skipped - matched_skips)

    return {
        "rows": sorted(rows, key=lambda row: (-money(row.payment_usd), -row.usage_usd, row.key.name.casefold())),
        "excluded_keys": excluded_keys,
        "skipped_usage_usd": skipped_usage_usd,
        "unmatched_skips": unmatched_skips,
        "key_count": key_count,
        "total_usage_usd": total_usage_usd,
        "average_usage_usd": average_usage_usd,
        "equal_share_usd": equal_share_usd,
        "base_coverage_fraction": float(base_coverage_fraction),
        "requested_base_total_usd": requested_base_total_usd,
        "base_total_usd": base_total_usd,
        "remaining_subscription_usd": remaining_subscription_usd,
        "unallocated_usd": unallocated_usd,
        "total_payment_usd": sum((row.payment_usd for row in rows), Decimal("0")),
        "extra_total_usd": sum((row.extra_usd for row in rows), Decimal("0")),
    }


def table(headers: list[str], rows: list[list[str]]) -> str:
    all_rows = [headers, *rows]
    widths = [max(len(row[index]) for row in all_rows) for index in range(len(headers))]

    def render(row: list[str]) -> str:
        return "  ".join(cell.ljust(widths[index]) for index, cell in enumerate(row))

    return "\n".join([render(headers), render(["-" * width for width in widths]), *(render(row) for row in rows)])


def print_text_report(
    result: dict[str, Any],
    *,
    source: str,
    range_start: str,
    range_end: str,
    subscription_usd: Decimal,
    base_contribution_usd: Decimal,
    first_event: FirstEvent | None,
) -> None:
    rows: list[BillingRow] = result["rows"]
    print("CLIProxyAPI Usage Keeper payment calculation")
    print(f"Source: {source}")
    print(f"Period: {range_start} <= timestamp <= {range_end}")
    if first_event is not None:
        print(
            f"First event: {first_event.timestamp} "
            f"(id {first_event.id}, key {first_event.api_key}, model {first_event.model})"
        )
    print(f"Included keys: {result['key_count']}")
    print(f"Subscription: {money_str(subscription_usd)}")
    print(
        "Requested base pool: "
        f"{money_str(base_contribution_usd)} × {result['key_count']} = "
        f"{money_str(result['requested_base_total_usd'])}"
    )
    print(
        f"Effective base pool: {money_str(result['base_total_usd'])} "
        f"({result['base_coverage_fraction'] * 100:.2f}% of subscription)"
    )
    print(f"Estimated usage cost in included keys: {money_str(result['total_usage_usd'])}")
    print(f"Average usage cost per key: {money_str(result['average_usage_usd'])}")
    print(f"Usage-cost share covered by the base pool: {money_str(result['equal_share_usd'])}")
    print(f"Subscription remainder distributed by positive remaining usage: {money_str(result['remaining_subscription_usd'])}")
    if result["requested_base_total_usd"] > subscription_usd:
        print("Requested base pool was capped at the subscription total")
    if result["unallocated_usd"] > 0:
        print(f"WARNING: no key has positive remaining usage; unallocated: {money_str(result['unallocated_usd'])}")
    if result["excluded_keys"]:
        names = ", ".join(key.name for key in result["excluded_keys"])
        print(f"Skipped keys: {names} (usage cost {money_str(result['skipped_usage_usd'])})")
    if result["unmatched_skips"]:
        print(
            f"WARNING: skip patterns did not match any key: {', '.join(result['unmatched_skips'])}",
            file=sys.stderr,
        )
    print()

    print(
        table(
            ["key", "usage cost", "minus covered", "positive", "base", "extra", "payment", "requests"],
            [
                [
                    row.key.name,
                    money_str(row.usage_usd),
                    money_str(row.usage_after_share_usd),
                    money_str(row.positive_usage_after_share_usd),
                    money_str(row.base_usd),
                    money_str(row.extra_usd),
                    money_str(row.payment_usd),
                    f"{row.requests:,}",
                ]
                for row in rows
            ],
        )
    )
    print()
    print(f"Extra allocated: {money_str(result['extra_total_usd'])}")
    print(f"Total to collect: {money_str(result['total_payment_usd'])}")


def json_decimal(value: Any) -> Any:
    if isinstance(value, Decimal):
        return str(money(value))
    if isinstance(value, ApiKey):
        return {
            "id": value.id,
            "name": value.name,
            "display_key": value.display_key,
            "is_active": value.is_active,
        }
    if isinstance(value, BillingRow):
        return {
            "key": json_decimal(value.key),
            "usage_usd": json_decimal(value.usage_usd),
            "equal_share_usd": json_decimal(value.equal_share_usd),
            "usage_after_share_usd": json_decimal(value.usage_after_share_usd),
            "positive_usage_after_share_usd": json_decimal(value.positive_usage_after_share_usd),
            "base_usd": json_decimal(value.base_usd),
            "extra_usd": json_decimal(value.extra_usd),
            "payment_usd": json_decimal(value.payment_usd),
            "requests": value.requests,
        }
    if isinstance(value, FirstEvent):
        return {
            "id": value.id,
            "timestamp": value.timestamp,
            "api_key": value.api_key,
            "model": value.model,
        }
    raise TypeError(f"Object of type {type(value).__name__} is not JSON serializable")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Calculate CLIProxyAPI subscription payments from CPA Usage Keeper.",
        epilog=(
            "Date-only --through values are inclusive. Example: "
            "scripts/cliproxyapi-payment.py --from first --through yesterday"
        ),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--from",
        dest="date_from",
        help="Start date/time, inclusive. Use 'first' for the first queryable keeper event.",
    )
    parser.add_argument(
        "--through",
        "--to",
        dest="date_through",
        help="End date/time, inclusive. Accepts 'today' and 'yesterday'.",
    )
    parser.add_argument(
        "--skip-key",
        action="append",
        default=[],
        metavar="NAME_OR_ID",
        help="Exclude API key from the payment calculation. Can be repeated or comma-separated.",
    )
    parser.add_argument("--time-zone", default=DEFAULT_TIME_ZONE, help="Timezone for date-only arguments and defaults.")
    parser.add_argument("--host", default=DEFAULT_HOST, help="SSH host with the CPA Usage Keeper container.")
    parser.add_argument("--container", default=DEFAULT_CONTAINER, help="CPA Usage Keeper container name on the SSH host.")
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL, help="Keeper API base URL as seen inside the container.")
    parser.add_argument(
        "--subscription-usd",
        "--subscription",
        "--price",
        type=parse_usd,
        default=SUBSCRIPTION_USD,
        help="Subscription price to collect.",
    )
    parser.add_argument(
        "--base-contribution-usd",
        type=parse_usd,
        default=BASE_CONTRIBUTION_USD,
        help="Requested equal base amount per key before distributing the remainder; capped at the subscription.",
    )
    parser.add_argument("--json", action="store_true", help="Print machine-readable JSON instead of a text table.")
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    start, through, tz = period_from_args(args)

    first_event = None
    if start is None:
        start, first_event = discover_first_event(
            host=args.host,
            container=args.container,
            base_url=args.base_url,
            through=through,
            tz=tz,
        )

    if through.value < start.value:
        raise SystemExit(
            f"--through must not be before --from: {through.value.isoformat()} < {start.value.isoformat()}"
        )

    analysis_start = start
    if first_event is not None:
        # Keeper's Analysis endpoint omits the opening partial hour when a
        # custom start is not hour-aligned. Discovery proved there are no
        # earlier events, so querying from the containing hour is equivalent
        # to querying from the first event and keeps that opening hour.
        hour_start = start.value.replace(minute=0, second=0, microsecond=0)
        analysis_start = Boundary(hour_start, hour_start.isoformat(), False)

    analysis_params = {
        "range": "custom",
        "start": analysis_start.api_value,
        "end": through.api_value,
    }
    keys_payload, analysis_payload = load_remote_json(
        host=args.host,
        container=args.container,
        base_url=args.base_url,
        endpoints=[
            "usage/api-keys",
            endpoint("usage/analysis", analysis_params),
        ],
    )
    keys, usage = parse_keeper_payload(keys_payload, analysis_payload)
    result = calculate_bill(
        keys=keys,
        usage_by_key=usage,
        skipped=split_skip_keys(args.skip_key),
        subscription_usd=args.subscription_usd,
        base_contribution_usd=args.base_contribution_usd,
    )

    source = f"{args.host}:{args.container}:{args.base_url}"
    range_start = first_event.timestamp if first_event is not None else str(
        analysis_payload.get("range_start") or start.api_value
    )
    range_end = str(analysis_payload.get("range_end") or through.api_value)

    if args.json:
        print(
            json.dumps(
                {
                    "source": source,
                    "period": {"from": range_start, "through": range_end},
                    "first_event": first_event,
                    "subscription_usd": args.subscription_usd,
                    "base_contribution_usd": args.base_contribution_usd,
                    "keeper_total_cost_usd": decimal_from_json(
                        (analysis_payload.get("cost_breakdown") or {}).get("total_cost_usd")
                    ),
                    **result,
                },
                ensure_ascii=False,
                indent=2,
                default=json_decimal,
            )
        )
    else:
        print_text_report(
            result,
            source=source,
            range_start=range_start,
            range_end=range_end,
            subscription_usd=args.subscription_usd,
            base_contribution_usd=args.base_contribution_usd,
            first_event=first_event,
        )


if __name__ == "__main__":
    main()
