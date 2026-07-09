#!/usr/bin/env python3
"""Calculate Omniroute subscription payments by API key.

The script reads Omniroute's ``domain_cost_history`` table, groups token costs by
API key, and applies the payment rule used for the shared subscription:

1. Every included key pays a fixed base contribution.
2. The included token-cost total is divided by the included key count; this is
   the token usage covered by the base contribution for every key.
3. For every key, that equal token-cost share is subtracted from its usage.
4. If the base contributions do not cover the subscription, the remaining
   subscription payment is split only between keys whose usage remains positive,
   proportionally to that remaining usage.
"""

from __future__ import annotations

import argparse
import calendar
import datetime as dt
import json
import os
import sqlite3
import subprocess
import sys
from dataclasses import dataclass
from decimal import Decimal, ROUND_DOWN, ROUND_HALF_UP, getcontext
from pathlib import Path
from typing import Any
from zoneinfo import ZoneInfo


# --- Adjustable billing constants -------------------------------------------------

SUBSCRIPTION_USD = Decimal("200")
BASE_CONTRIBUTION_USD = Decimal("10")

# Default period is the previous calendar month in this timezone.
DEFAULT_TIME_ZONE = "Europe/Moscow"

# Active keys without usage still participate in the base split.
INCLUDE_ACTIVE_KEYS_WITHOUT_USAGE = True

# Inactive/revoked keys are included if they have usage in the selected period.
INCLUDE_INACTIVE_KEYS_WITH_USAGE = True

# Remote Omniroute SQLite location. Can also be overridden by CLI/env.
DEFAULT_HOST = os.environ.get("OMNIROUTE_HOST", "whale")
DEFAULT_CONTAINER = os.environ.get("OMNIROUTE_CONTAINER", "omniroute")
DEFAULT_DB_PATH = os.environ.get("OMNIROUTE_DB_PATH", "/app/data/storage.sqlite")


# --- Internal constants -----------------------------------------------------------

getcontext().prec = 28
MONEY = Decimal("0.01")

REMOTE_QUERY_JS = r"""
const Database = require('better-sqlite3');

const dbPath = process.env.DB_PATH || '/app/data/storage.sqlite';
const startMs = Number(process.env.START_MS);
const endMs = Number(process.env.END_MS);

if (!Number.isFinite(startMs) || !Number.isFinite(endMs)) {
  throw new Error('START_MS and END_MS must be finite numbers');
}

const db = new Database(dbPath, { readonly: true });

const keys = db.prepare(`
  SELECT id, name, key_prefix, is_active, revoked_at
  FROM api_keys
  ORDER BY lower(name), id
`).all();

const usage = db.prepare(`
  SELECT
    api_key_id,
    printf('%.12f', SUM(cost)) AS usage_usd,
    COUNT(*) AS cost_events
  FROM domain_cost_history
  WHERE timestamp >= ? AND timestamp < ?
  GROUP BY api_key_id
`).all(startMs, endMs);

console.log(JSON.stringify({ keys, usage }));
"""


@dataclass(frozen=True)
class ApiKey:
    id: str
    name: str
    key_prefix: str | None
    is_active: bool
    revoked_at: str | None

    @property
    def active_for_billing(self) -> bool:
        return self.is_active and self.revoked_at is None


@dataclass(frozen=True)
class Usage:
    usage_usd: Decimal
    cost_events: int


@dataclass(frozen=True)
class BillingRow:
    key: ApiKey
    usage_usd: Decimal
    equal_share_usd: Decimal
    usage_after_share_usd: Decimal
    positive_usage_after_share_usd: Decimal
    extra_usd: Decimal
    payment_usd: Decimal
    cost_events: int


def money(value: Decimal) -> Decimal:
    return value.quantize(MONEY, rounding=ROUND_HALF_UP)


def money_str(value: Decimal) -> str:
    rounded = money(value)
    sign = "-" if rounded < 0 else ""
    return f"{sign}${abs(rounded):,.2f}"


def decimal_from_db(value: Any) -> Decimal:
    if value is None:
        return Decimal("0")
    return Decimal(str(value))


def parse_usd(value: str) -> Decimal:
    try:
        amount = Decimal(value.strip().removeprefix("$"))
    except Exception as error:
        raise argparse.ArgumentTypeError(f"invalid USD amount: {value}") from error
    if amount < 0:
        raise argparse.ArgumentTypeError(f"USD amount must be non-negative: {value}")
    return amount


def datetime_to_epoch_ms(value: dt.datetime) -> int:
    return int(value.timestamp() * 1000)


def add_months(value: dt.datetime, months: int) -> dt.datetime:
    month_index = value.month - 1 + months
    year = value.year + month_index // 12
    month = month_index % 12 + 1
    day = min(value.day, calendar.monthrange(year, month)[1])
    return value.replace(year=year, month=month, day=day)


def default_period(tz: ZoneInfo) -> tuple[dt.datetime, dt.datetime]:
    now = dt.datetime.now(tz)
    current_month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    return add_months(current_month_start, -1), current_month_start


def parse_datetime(value: str, tz: ZoneInfo) -> dt.datetime:
    raw = value.strip()
    if not raw:
        raise argparse.ArgumentTypeError("empty datetime value")

    try:
        parsed_date = dt.date.fromisoformat(raw)
    except ValueError:
        parsed_date = None

    if parsed_date is not None:
        return dt.datetime.combine(parsed_date, dt.time.min, tzinfo=tz)

    normalized = raw[:-1] + "+00:00" if raw.endswith("Z") else raw
    try:
        parsed = dt.datetime.fromisoformat(normalized)
    except ValueError as error:
        raise argparse.ArgumentTypeError(f"invalid ISO date/datetime: {value}") from error

    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=tz)
    return parsed.astimezone(tz)


def period_from_args(args: argparse.Namespace) -> tuple[dt.datetime, dt.datetime]:
    tz = ZoneInfo(args.time_zone)

    if args.date_from is None and args.date_to is None:
        start, end = default_period(tz)
    elif args.date_from is not None and args.date_to is not None:
        start = parse_datetime(args.date_from, tz)
        end = parse_datetime(args.date_to, tz)
    elif args.date_from is not None:
        start = parse_datetime(args.date_from, tz)
        end = dt.datetime.now(tz)
    else:
        assert args.date_to is not None
        end = parse_datetime(args.date_to, tz)
        start = add_months(end, -1)

    if end <= start:
        raise SystemExit(f"--to must be after --from: {start.isoformat()} >= {end.isoformat()}")

    return start, end


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
    if key.key_prefix:
        candidates.append(key.key_prefix)
    return any(candidate.casefold() in skipped for candidate in candidates)


def parse_payload(payload: dict[str, Any]) -> tuple[list[ApiKey], dict[str, Usage]]:
    keys = [
        ApiKey(
            id=str(row["id"]),
            name=str(row.get("name") or row["id"]),
            key_prefix=str(row["key_prefix"]) if row.get("key_prefix") else None,
            is_active=bool(row.get("is_active")),
            revoked_at=str(row["revoked_at"]) if row.get("revoked_at") else None,
        )
        for row in payload["keys"]
    ]

    usage: dict[str, Usage] = {}
    for row in payload["usage"]:
        api_key_id = str(row["api_key_id"])
        usage[api_key_id] = Usage(
            usage_usd=decimal_from_db(row.get("usage_usd")),
            cost_events=int(row.get("cost_events") or 0),
        )

    return keys, usage


def load_remote_usage(
    *,
    host: str,
    container: str,
    db_path: str,
    start_ms: int,
    end_ms: int,
) -> tuple[list[ApiKey], dict[str, Usage]]:
    command = [
        "ssh",
        host,
        "sudo",
        "podman",
        "exec",
        "-i",
        container,
        "env",
        f"DB_PATH={db_path}",
        f"START_MS={start_ms}",
        f"END_MS={end_ms}",
        "node",
    ]

    result = subprocess.run(
        command,
        input=REMOTE_QUERY_JS,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        raise SystemExit(
            "Failed to query Omniroute over SSH.\n"
            f"Command: {' '.join(command)}\n"
            f"stdout:\n{result.stdout}\n"
            f"stderr:\n{result.stderr}"
        )

    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise SystemExit(f"Omniroute query returned non-JSON output:\n{result.stdout}") from error
    return parse_payload(payload)


def load_local_usage(db_path: Path, start_ms: int, end_ms: int) -> tuple[list[ApiKey], dict[str, Usage]]:
    with sqlite3.connect(db_path) as connection:
        connection.row_factory = sqlite3.Row
        keys = [
            ApiKey(
                id=str(row["id"]),
                name=str(row["name"] or row["id"]),
                key_prefix=str(row["key_prefix"]) if row["key_prefix"] else None,
                is_active=bool(row["is_active"]),
                revoked_at=str(row["revoked_at"]) if row["revoked_at"] else None,
            )
            for row in connection.execute(
                """
                SELECT id, name, key_prefix, is_active, revoked_at
                FROM api_keys
                ORDER BY lower(name), id
                """
            )
        ]

        usage = {
            str(row["api_key_id"]): Usage(
                usage_usd=decimal_from_db(row["usage_usd"]),
                cost_events=int(row["cost_events"]),
            )
            for row in connection.execute(
                """
                SELECT
                  api_key_id,
                  printf('%.12f', SUM(cost)) AS usage_usd,
                  COUNT(*) AS cost_events
                FROM domain_cost_history
                WHERE timestamp >= ? AND timestamp < ?
                GROUP BY api_key_id
                """,
                (start_ms, end_ms),
            )
        }

    return keys, usage


def include_key(key: ApiKey, usage: Usage | None, include_all_keys: bool) -> bool:
    if include_all_keys:
        return True
    if INCLUDE_ACTIVE_KEYS_WITHOUT_USAGE and key.active_for_billing:
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


def calculate_bill(
    keys: list[ApiKey],
    usage_by_key: dict[str, Usage],
    skipped: set[str],
    include_all_keys: bool,
    subscription_usd: Decimal,
    base_contribution_usd: Decimal,
) -> dict[str, Any]:
    known_key_ids = {key.id for key in keys}
    all_keys = list(keys)

    for missing_key_id in sorted(set(usage_by_key) - known_key_ids):
        all_keys.append(
            ApiKey(
                id=missing_key_id,
                name=f"unknown:{missing_key_id[:8]}",
                key_prefix=None,
                is_active=False,
                revoked_at="missing-from-api_keys",
            )
        )

    included_keys: list[ApiKey] = []
    excluded_keys: list[ApiKey] = []
    matched_skips: set[str] = set()

    for key in all_keys:
        usage = usage_by_key.get(key.id)
        if key_matches_skip(key, skipped):
            excluded_keys.append(key)
            matched_skips.update(
                candidate.casefold()
                for candidate in [key.id, key.name, key.key_prefix or ""]
                if candidate.casefold() in skipped
            )
            continue
        if include_key(key, usage, include_all_keys):
            included_keys.append(key)

    if not included_keys:
        raise SystemExit("No keys left in the payment calculation after applying filters")

    key_count = len(included_keys)
    total_usage_usd = sum((usage_by_key.get(key.id, Usage(Decimal("0"), 0)).usage_usd for key in included_keys), Decimal("0"))
    equal_share_usd = total_usage_usd / key_count
    base_total_usd = base_contribution_usd * key_count
    remaining_subscription_usd = max(subscription_usd - base_total_usd, Decimal("0"))

    weights: dict[str, Decimal] = {}
    intermediate: dict[str, tuple[Decimal, Decimal, int]] = {}
    for key in included_keys:
        usage = usage_by_key.get(key.id, Usage(Decimal("0"), 0))
        usage_after_share = usage.usage_usd - equal_share_usd
        positive_after_share = max(usage_after_share, Decimal("0"))
        intermediate[key.id] = (usage.usage_usd, usage_after_share, usage.cost_events)
        if positive_after_share > 0:
            weights[key.id] = positive_after_share

    extras = allocate_cents(remaining_subscription_usd, weights)
    unallocated_usd = money(remaining_subscription_usd) if remaining_subscription_usd > 0 and not weights else Decimal("0")

    rows = []
    for key in included_keys:
        usage_usd, usage_after_share, cost_events = intermediate[key.id]
        positive_after_share = max(usage_after_share, Decimal("0"))
        extra_usd = extras.get(key.id, Decimal("0"))
        rows.append(
            BillingRow(
                key=key,
                usage_usd=usage_usd,
                equal_share_usd=equal_share_usd,
                usage_after_share_usd=usage_after_share,
                positive_usage_after_share_usd=positive_after_share,
                extra_usd=extra_usd,
                payment_usd=base_contribution_usd + extra_usd,
                cost_events=cost_events,
            )
        )

    skipped_usage_usd = sum((usage_by_key.get(key.id, Usage(Decimal("0"), 0)).usage_usd for key in excluded_keys), Decimal("0"))
    unmatched_skips = sorted(skipped - matched_skips)

    return {
        "rows": sorted(rows, key=lambda row: (-money(row.payment_usd), -row.usage_usd, row.key.name.casefold())),
        "excluded_keys": excluded_keys,
        "skipped_usage_usd": skipped_usage_usd,
        "unmatched_skips": unmatched_skips,
        "key_count": key_count,
        "total_usage_usd": total_usage_usd,
        "equal_share_usd": equal_share_usd,
        "base_total_usd": base_total_usd,
        "remaining_subscription_usd": remaining_subscription_usd,
        "unallocated_usd": unallocated_usd,
        "total_payment_usd": sum((base_contribution_usd + row.extra_usd for row in rows), Decimal("0")),
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
    start: dt.datetime,
    end: dt.datetime,
    source: str,
    subscription_usd: Decimal,
    base_contribution_usd: Decimal,
) -> None:
    rows: list[BillingRow] = result["rows"]
    print("Omniroute payment calculation")
    print(f"Source: {source}")
    print(f"Period: {start.isoformat()} <= timestamp < {end.isoformat()}")
    print(f"Included keys: {result['key_count']}")
    print(f"Subscription: {money_str(subscription_usd)}")
    print(
        "Base contribution: "
        f"{money_str(base_contribution_usd)} × {result['key_count']} = {money_str(result['base_total_usd'])}"
    )
    print(f"Token cost in included keys: {money_str(result['total_usage_usd'])}")
    print(f"Token-cost share subtracted from every key: {money_str(result['equal_share_usd'])}")
    print(f"Subscription remainder distributed by positive remaining usage: {money_str(result['remaining_subscription_usd'])}")
    if result["base_total_usd"] > subscription_usd:
        print(f"Base contribution exceeds subscription by: {money_str(result['base_total_usd'] - subscription_usd)}")
    if result["unallocated_usd"] > 0:
        print(f"WARNING: no key has positive remaining usage; unallocated: {money_str(result['unallocated_usd'])}")
    if result["excluded_keys"]:
        names = ", ".join(key.name for key in result["excluded_keys"])
        print(f"Skipped keys: {names} (usage {money_str(result['skipped_usage_usd'])})")
    if result["unmatched_skips"]:
        print(f"WARNING: skip patterns did not match any key: {', '.join(result['unmatched_skips'])}", file=sys.stderr)
    print()

    print(
        table(
            ["key", "usage", "minus share", "positive", "extra", "payment", "events"],
            [
                [
                    row.key.name,
                    money_str(row.usage_usd),
                    money_str(row.usage_after_share_usd),
                    money_str(row.positive_usage_after_share_usd),
                    money_str(row.extra_usd),
                    money_str(row.payment_usd),
                    str(row.cost_events),
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
            "key_prefix": value.key_prefix,
            "is_active": value.is_active,
            "revoked_at": value.revoked_at,
        }
    if isinstance(value, BillingRow):
        return {
            "key": json_decimal(value.key),
            "usage_usd": json_decimal(value.usage_usd),
            "equal_share_usd": json_decimal(value.equal_share_usd),
            "usage_after_share_usd": json_decimal(value.usage_after_share_usd),
            "positive_usage_after_share_usd": json_decimal(value.positive_usage_after_share_usd),
            "extra_usd": json_decimal(value.extra_usd),
            "payment_usd": json_decimal(value.payment_usd),
            "cost_events": value.cost_events,
        }
    raise TypeError(f"Object of type {type(value).__name__} is not JSON serializable")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Calculate Omniroute subscription payments by API key.",
        epilog="If --from/--to are omitted, the script uses the previous calendar month.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--from", dest="date_from", help="Start date/time, inclusive. Example: 2026-05-01")
    parser.add_argument("--to", dest="date_to", help="End date/time, exclusive. Example: 2026-06-01")
    parser.add_argument(
        "--skip-key",
        action="append",
        default=[],
        metavar="NAME_OR_ID",
        help="Exclude API key from the payment calculation. Can be repeated or comma-separated.",
    )
    parser.add_argument("--time-zone", default=DEFAULT_TIME_ZONE, help="Timezone for date-only arguments and defaults.")
    parser.add_argument("--host", default=DEFAULT_HOST, help="SSH host with the Omniroute container.")
    parser.add_argument("--container", default=DEFAULT_CONTAINER, help="Podman container name on the SSH host.")
    parser.add_argument("--db-path", default=DEFAULT_DB_PATH, help="SQLite DB path inside the container.")
    parser.add_argument("--db", type=Path, help="Read a local SQLite DB instead of querying the remote container.")
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
        help="Fixed amount paid by every included key before distributing the remainder.",
    )
    parser.add_argument("--all-keys", action="store_true", help="Include every api_keys row, even inactive keys without usage.")
    parser.add_argument("--json", action="store_true", help="Print machine-readable JSON instead of a text table.")
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    start, end = period_from_args(args)
    start_ms = datetime_to_epoch_ms(start)
    end_ms = datetime_to_epoch_ms(end)

    if args.db is not None:
        keys, usage = load_local_usage(args.db.expanduser(), start_ms, end_ms)
        source = str(args.db.expanduser())
    else:
        keys, usage = load_remote_usage(
            host=args.host,
            container=args.container,
            db_path=args.db_path,
            start_ms=start_ms,
            end_ms=end_ms,
        )
        source = f"{args.host}:{args.container}:{args.db_path}"

    result = calculate_bill(
        keys=keys,
        usage_by_key=usage,
        skipped=split_skip_keys(args.skip_key),
        include_all_keys=args.all_keys,
        subscription_usd=args.subscription_usd,
        base_contribution_usd=args.base_contribution_usd,
    )

    if args.json:
        print(
            json.dumps(
                {
                    "source": source,
                    "period": {"from": start.isoformat(), "to": end.isoformat(), "from_ms": start_ms, "to_ms": end_ms},
                    "subscription_usd": args.subscription_usd,
                    "base_contribution_usd": args.base_contribution_usd,
                    **result,
                },
                ensure_ascii=False,
                indent=2,
                default=json_decimal,
            )
        )
    else:
        print_text_report(result, start, end, source, args.subscription_usd, args.base_contribution_usd)


if __name__ == "__main__":
    main()
