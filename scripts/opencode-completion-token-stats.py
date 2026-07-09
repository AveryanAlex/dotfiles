#!/usr/bin/env python3
"""Print opencode usage completion token statistics.

This reads opencode's SQLite history databases and computes model usage-style
completion tokens as:

    completion_tokens = message.data.tokens.output + message.data.tokens.reasoning

Per-request stats group all assistant responses after a user message until the
next user message in the same session. Tool result text is intentionally not
included here, because provider `usage.completion_tokens` does not include tool
results returned by the client.
"""

from __future__ import annotations

import argparse
import collections
import json
import math
import re
import sqlite3
from pathlib import Path
from typing import Any, Iterable


DEFAULT_DBS = [
    Path.home() / ".local/share/opencode/opencode.db",
    Path.home() / ".local/share/opencode/opencode-stable.db",
]

DEFAULT_THRESHOLDS = [128000, 96000, 64000, 48000, 32000, 24000, 16000, 12000, 8000, 4000, 2000, 1000]


def percentile(values: list[int], p: float) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    if len(ordered) == 1:
        return float(ordered[0])
    k = (len(ordered) - 1) * p / 100
    floor = math.floor(k)
    ceil = math.ceil(k)
    if floor == ceil:
        return float(ordered[floor])
    return ordered[floor] * (ceil - k) + ordered[ceil] * (k - floor)


def summarize(values: Iterable[int], thresholds: list[int]) -> dict[str, Any]:
    vals = list(values)
    return {
        "n": len(vals),
        "sum": sum(vals),
        "mean": (sum(vals) / len(vals)) if vals else 0,
        "median": percentile(vals, 50),
        "p75": percentile(vals, 75),
        "p90": percentile(vals, 90),
        "p95": percentile(vals, 95),
        "p99": percentile(vals, 99),
        "p999": percentile(vals, 99.9),
        "max": max(vals) if vals else 0,
        "thresholds": {threshold: sum(value > threshold for value in vals) for threshold in thresholds},
    }


def fmt_int(value: Any) -> str:
    if value is None:
        return ""
    return f"{int(round(float(value))):,}"


def completion_tokens(message_data: dict[str, Any]) -> tuple[int, int, int]:
    tokens = message_data.get("tokens")
    if not isinstance(tokens, dict):
        return 0, 0, 0
    output = tokens.get("output")
    reasoning = tokens.get("reasoning")
    output_int = int(output) if isinstance(output, int | float) else 0
    reasoning_int = int(reasoning) if isinstance(reasoning, int | float) else 0
    return output_int + reasoning_int, output_int, reasoning_int


def model_name(message_data: dict[str, Any]) -> str:
    model = message_data.get("modelID") or message_data.get("model") or "unknown"
    return str(model)


def parse_thresholds(value: str) -> list[int]:
    thresholds = []
    for raw in value.split(","):
        raw = raw.strip().lower()
        if not raw:
            continue
        multiplier = 1
        if raw.endswith("k"):
            multiplier = 1000
            raw = raw[:-1]
        thresholds.append(int(float(raw) * multiplier))
    return sorted(set(thresholds), reverse=True)


def excluded_sessions_for_titles(db_path: Path, patterns: list[re.Pattern[str]]) -> set[str]:
    if not patterns:
        return set()
    excluded: set[str] = set()
    with sqlite3.connect(db_path) as connection:
        for session_id, title in connection.execute("SELECT id, title FROM session"):
            title = title or ""
            if any(pattern.search(title) for pattern in patterns):
                excluded.add(session_id)
    return excluded


def markdown_table(headers: list[str], rows: list[list[Any]]) -> str:
    lines = ["| " + " | ".join(headers) + " |", "| " + " | ".join("---" for _ in headers) + " |"]
    lines.extend("| " + " | ".join(str(cell) for cell in row) + " |" for row in rows)
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Print opencode completion_tokens stats by request and model.")
    parser.add_argument(
        "--db",
        action="append",
        type=Path,
        help="SQLite opencode DB path. Can be repeated. Defaults to the normal and stable opencode DBs.",
    )
    parser.add_argument("--exclude-session", action="append", default=[], help="Session ID to exclude. Can be repeated.")
    parser.add_argument(
        "--exclude-title-regex",
        action="append",
        default=[],
        help="Exclude sessions whose title matches this regex. Can be repeated.",
    )
    parser.add_argument(
        "--thresholds",
        default=",".join(str(threshold) for threshold in DEFAULT_THRESHOLDS),
        help="Comma-separated thresholds. Supports k suffix, e.g. 128k,64k,32k.",
    )
    parser.add_argument("--drop-empty", action="store_true", help="Drop user requests with no assistant completion tokens.")
    args = parser.parse_args()

    db_paths = args.db or [path for path in DEFAULT_DBS if path.exists()]
    if not db_paths:
        raise SystemExit("No opencode DBs found. Pass --db /path/to/opencode.db")

    thresholds = parse_thresholds(args.thresholds)
    title_patterns = [re.compile(pattern) for pattern in args.exclude_title_regex]

    responses_by_model: dict[str, list[int]] = collections.defaultdict(list)
    responses_output_reasoning_by_model: dict[str, list[int]] = collections.defaultdict(lambda: [0, 0])
    requests: list[dict[str, Any]] = []

    message_count = 0
    user_turn_count = 0
    assistant_response_count = 0
    session_ids: set[tuple[str, str]] = set()
    excluded_sessions_total: set[tuple[str, str]] = set()

    for db_path in db_paths:
        db_path = db_path.expanduser()
        excluded_sessions = set(args.exclude_session) | excluded_sessions_for_titles(db_path, title_patterns)
        excluded_sessions_total.update((db_path.name, session_id) for session_id in excluded_sessions)

        with sqlite3.connect(db_path) as connection:
            placeholders = ",".join("?" for _ in excluded_sessions)
            where = f"WHERE session_id NOT IN ({placeholders})" if excluded_sessions else ""
            query = f"""
                SELECT id, session_id, time_created, data
                FROM message
                {where}
                ORDER BY session_id, time_created, id
            """

            current_session_id: str | None = None
            current_request: dict[str, Any] | None = None

            for message_id, session_id, _time_created, raw_data in connection.execute(query, tuple(excluded_sessions)):
                message_count += 1
                session_ids.add((db_path.name, session_id))

                data = json.loads(raw_data)
                role = data.get("role")

                if session_id != current_session_id:
                    if current_request is not None:
                        requests.append(current_request)
                    current_session_id = session_id
                    current_request = None

                if role == "user":
                    user_turn_count += 1
                    if current_request is not None:
                        requests.append(current_request)
                    current_request = {
                        "db": db_path.name,
                        "session_id": session_id,
                        "user_message_id": message_id,
                        "completion": 0,
                        "output": 0,
                        "reasoning": 0,
                        "assistant_messages": 0,
                        "by_model": collections.Counter(),
                    }
                    continue

                if role != "assistant":
                    continue

                assistant_response_count += 1
                completion, output, reasoning = completion_tokens(data)
                model = model_name(data)

                responses_by_model[model].append(completion)
                responses_output_reasoning_by_model[model][0] += output
                responses_output_reasoning_by_model[model][1] += reasoning

                if current_request is not None:
                    current_request["completion"] = int(current_request["completion"]) + completion
                    current_request["output"] = int(current_request["output"]) + output
                    current_request["reasoning"] = int(current_request["reasoning"]) + reasoning
                    current_request["assistant_messages"] = int(current_request["assistant_messages"]) + 1
                    current_request["by_model"][model] += completion  # type: ignore[index]

            if current_request is not None:
                requests.append(current_request)

    if args.drop_empty:
        requests = [request for request in requests if int(request["completion"]) > 0]

    request_values = [int(request["completion"]) for request in requests]
    request_summary = summarize(request_values, thresholds)

    requests_by_primary_model: dict[str, list[int]] = collections.defaultdict(list)
    mixed_request_count = 0
    empty_request_count = 0
    for request in requests:
        by_model = request["by_model"]
        assert isinstance(by_model, collections.Counter)
        positive_models = [model for model, tokens in by_model.items() if tokens > 0]
        if not by_model:
            primary_model = "none"
            empty_request_count += 1
        else:
            primary_model = max(by_model.items(), key=lambda item: item[1])[0]
            if len(positive_models) > 1:
                mixed_request_count += 1
        requests_by_primary_model[primary_model].append(int(request["completion"]))

    print("# opencode completion_tokens stats")
    print()
    print("completion_tokens = tokens.output + tokens.reasoning")
    print("Per request = all assistant responses after one user message until the next user message.")
    print("Tool results are not included; they are not model usage completion_tokens.")
    print()
    print("DBs:")
    for db_path in db_paths:
        print(f"- {db_path.expanduser()}")
    if excluded_sessions_total:
        print(f"Excluded sessions: {len(excluded_sessions_total):,}")
    print()
    print(
        "Dataset: "
        f"{len(requests):,} requests, "
        f"{len(session_ids):,} sessions, "
        f"{message_count:,} messages, "
        f"{user_turn_count:,} user turns, "
        f"{assistant_response_count:,} assistant responses, "
        f"{mixed_request_count:,} mixed-model requests, "
        f"{empty_request_count:,} empty requests"
    )
    print()

    print("## Overall per request")
    print()
    print(
        markdown_table(
            ["Stat", "completion_tokens"],
            [
                ["Median", fmt_int(request_summary["median"])],
                ["Mean", fmt_int(request_summary["mean"])],
                ["P75", fmt_int(request_summary["p75"])],
                ["P90", fmt_int(request_summary["p90"])],
                ["P95", fmt_int(request_summary["p95"])],
                ["P99", fmt_int(request_summary["p99"])],
                ["P99.9", fmt_int(request_summary["p999"])],
                ["Max", fmt_int(request_summary["max"])],
            ],
        )
    )
    print()
    threshold_counts = request_summary["thresholds"]
    assert isinstance(threshold_counts, dict)
    print(
        markdown_table(
            ["Limit", "Count", "%"],
            [
                [f">{threshold:,}", f"{threshold_counts[threshold]:,}", f"{threshold_counts[threshold] / len(requests) * 100:.3f}%"]
                for threshold in thresholds
            ],
        )
    )
    print()

    print("## By model, per request")
    print()
    request_rows: list[list[Any]] = []
    for model, values in sorted(requests_by_primary_model.items(), key=lambda item: len(item[1]), reverse=True):
        if model == "none":
            continue
        model_summary = summarize(values, thresholds)
        model_thresholds = model_summary["thresholds"]
        assert isinstance(model_thresholds, dict)
        request_rows.append(
            [
                model,
                f"{model_summary['n']:,}",
                fmt_int(model_summary["mean"]),
                fmt_int(model_summary["median"]),
                fmt_int(model_summary["p95"]),
                fmt_int(model_summary["p99"]),
                fmt_int(model_summary["max"]),
                f"{model_thresholds.get(128000, 0):,}",
                f"{model_thresholds.get(64000, 0):,}",
                f"{model_thresholds.get(32000, 0):,}",
                f"{model_thresholds.get(16000, 0):,}",
            ]
        )
    print(
        markdown_table(
            ["Model", "Requests", "Mean", "Median", "P95", "P99", "Max", ">128k", ">64k", ">32k", ">16k"],
            request_rows,
        )
    )
    print()

    print("## By model, per individual assistant response")
    print()
    response_rows: list[list[Any]] = []
    for model, values in sorted(responses_by_model.items(), key=lambda item: len(item[1]), reverse=True):
        model_summary = summarize(values, thresholds)
        model_thresholds = model_summary["thresholds"]
        assert isinstance(model_thresholds, dict)
        output_sum, reasoning_sum = responses_output_reasoning_by_model[model]
        response_rows.append(
            [
                model,
                f"{model_summary['n']:,}",
                fmt_int(model_summary["sum"]),
                fmt_int(model_summary["mean"]),
                fmt_int(model_summary["median"]),
                fmt_int(model_summary["p95"]),
                fmt_int(model_summary["p99"]),
                fmt_int(model_summary["max"]),
                f"{model_thresholds.get(32000, 0):,}",
                f"{model_thresholds.get(16000, 0):,}",
                f"{output_sum:,}",
                f"{reasoning_sum:,}",
            ]
        )
    print(
        markdown_table(
            [
                "Model",
                "Responses",
                "Total completion",
                "Mean",
                "Median",
                "P95",
                "P99",
                "Max",
                ">32k",
                ">16k",
                "output_sum",
                "reasoning_sum",
            ],
            response_rows,
        )
    )


if __name__ == "__main__":
    main()
