#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Query Omniroute completion-token history from whale.

Metric: call_logs.tokens_out, which is Omniroute's persisted copy of
responseBody.usage.completion_tokens.

Usage:
  scripts/omniroute-completion-history.sh [all|largest|stats|json]

Modes:
  all      Print distribution stats and the largest historical response (default)
  largest  Print only largest-response metadata
  stats    Print only distribution stats
  json     Print all collected data as JSON

Environment:
  OMNIROUTE_HOST       SSH host to query (default: whale)
  OMNIROUTE_CONTAINER  Podman container name (default: omniroute)
  OMNIROUTE_DB_PATH    SQLite path inside container (default: /app/data/storage.sqlite)
USAGE
}

mode="${1:-all}"
case "$mode" in
  all | largest | stats | json) ;;
  -h | --help | help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

host="${OMNIROUTE_HOST:-whale}"
container="${OMNIROUTE_CONTAINER:-omniroute}"
db_path="${OMNIROUTE_DB_PATH:-/app/data/storage.sqlite}"

remote_cmd=(sudo podman exec -i "$container" env "DB_PATH=$db_path" "MODE=$mode" node)
ssh "$host" "$(printf '%q ' "${remote_cmd[@]}")" <<'NODE'
const Database = require('better-sqlite3');

const mode = process.env.MODE || 'all';
const dbPath = process.env.DB_PATH || '/app/data/storage.sqlite';
const db = new Database(dbPath, { readonly: true });

const generationPaths = [
  '/api/v1/responses',
  '/v1/responses',
  '/api/v1/chat/completions',
];

const placeholders = generationPaths.map(() => '?').join(',');
const scopeWhere = `
  status = 200
  AND tokens_out IS NOT NULL
  AND path IN (${placeholders})
  AND COALESCE(model, '') NOT IN ('model-sync', 'connection-test')
`;

const rows = db
  .prepare(`
    SELECT timestamp, model, requested_model, provider, tokens_out AS completion_tokens
    FROM call_logs
    WHERE ${scopeWhere}
    ORDER BY tokens_out ASC
  `)
  .all(...generationPaths);

const values = rows.map((row) => row.completion_tokens);
const n = values.length;
const sum = values.reduce((acc, value) => acc + value, 0);

function percent(count, total = n) {
  return total ? (100 * count) / total : 0;
}

function quantile(p) {
  if (!n) return null;
  return values[Math.ceil(p * n) - 1];
}

function fmtInt(value) {
  return value == null ? 'n/a' : Math.round(value).toLocaleString('en-US');
}

function fmtFloat(value, digits = 2) {
  return value == null ? 'n/a' : Number(value).toFixed(digits);
}

function fmtPercent(value) {
  return `${fmtFloat(value, 4)}%`;
}

function fmtTimestamp(value) {
  return value || 'n/a';
}

function fmtDuration(ms) {
  if (ms == null) return 'n/a';
  const totalSeconds = ms / 1000;
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds - minutes * 60;
  if (minutes > 0) return `${minutes}m ${seconds.toFixed(1)}s`;
  return `${seconds.toFixed(1)}s`;
}

function printTable(headers, rowsToPrint) {
  const allRows = [headers, ...rowsToPrint];
  const widths = headers.map((_, column) =>
    Math.max(...allRows.map((row) => String(row[column]).length)),
  );
  const render = (row) =>
    row.map((cell, column) => String(cell).padEnd(widths[column], ' ')).join('  ');
  console.log(render(headers));
  console.log(widths.map((width) => '-'.repeat(width)).join('  '));
  for (const row of rowsToPrint) console.log(render(row));
}

const scope = db
  .prepare(`
    SELECT
      COUNT(*) AS n,
      MIN(timestamp) AS min_timestamp,
      MAX(timestamp) AS max_timestamp,
      AVG(tokens_out) AS average_completion_tokens
    FROM call_logs
    WHERE ${scopeWhere}
  `)
  .get(...generationPaths);

const thresholdValues = [
  131072,
  65536,
  32768,
  24576,
  20000,
  16384,
  12288,
  8192,
  6144,
  4096,
  2048,
  1024,
  512,
];

const thresholds = thresholdValues.map((threshold) => {
  const count = values.filter((value) => value > threshold).length;
  return { threshold, count, percent: percent(count) };
});

const buckets = [
  [0, 512],
  [513, 1024],
  [1025, 2048],
  [2049, 4096],
  [4097, 8192],
  [8193, 16384],
  [16385, 32768],
  [32769, 65536],
  [65537, 131072],
  [131073, Infinity],
].map(([min, max]) => {
  const count = values.filter((value) => value >= min && value <= max).length;
  return {
    range: max === Infinity ? `${min}+` : `${min}-${max}`,
    count,
    percent: percent(count),
  };
});

const stats = {
  min: values[0] ?? null,
  p10: quantile(0.1),
  p25: quantile(0.25),
  median: quantile(0.5),
  average: n ? sum / n : null,
  p75: quantile(0.75),
  p90: quantile(0.9),
  p95: quantile(0.95),
  p99: quantile(0.99),
  p995: quantile(0.995),
  p999: quantile(0.999),
  max: values[n - 1] ?? null,
};

const byModel = db
  .prepare(`
    SELECT
      model,
      COUNT(*) AS n,
      AVG(tokens_out) AS average,
      MAX(tokens_out) AS max,
      SUM(tokens_out > 8192) AS gt8k,
      SUM(tokens_out > 16384) AS gt16k,
      SUM(tokens_out > 32768) AS gt32k
    FROM call_logs
    WHERE ${scopeWhere}
    GROUP BY model
    ORDER BY n DESC
  `)
  .all(...generationPaths);

const largest = db
  .prepare(`
    SELECT
      id,
      timestamp,
      method,
      path,
      status,
      model,
      requested_model,
      provider,
      duration,
      tokens_in,
      tokens_out AS completion_tokens,
      tokens_cache_read,
      COALESCE(tokens_cache_creation, 0) AS tokens_cache_creation,
      tokens_reasoning,
      tokens_compressed,
      cache_source,
      source_format,
      target_format,
      api_key_name,
      combo_name,
      combo_step_id,
      combo_execution_key,
      error_summary,
      detail_state,
      artifact_relpath,
      artifact_size_bytes,
      has_request_body,
      has_response_body,
      has_pipeline_details
    FROM call_logs
    WHERE ${scopeWhere}
    ORDER BY tokens_out DESC
    LIMIT 1
  `)
  .get(...generationPaths);

const rank = largest
  ? db
      .prepare(`
        SELECT
          COUNT(*) AS n,
          SUM(CASE WHEN tokens_out > ? THEN 1 ELSE 0 END) AS above,
          SUM(CASE WHEN tokens_out >= ? THEN 1 ELSE 0 END) AS at_or_above
        FROM call_logs
        WHERE ${scopeWhere}
      `)
      .get(largest.completion_tokens, largest.completion_tokens, ...generationPaths)
  : null;

const top10 = db
  .prepare(`
    SELECT
      timestamp,
      model,
      requested_model,
      provider,
      duration,
      tokens_in,
      tokens_out AS completion_tokens,
      tokens_reasoning,
      tokens_cache_read,
      COALESCE(tokens_cache_creation, 0) AS tokens_cache_creation,
      detail_state,
      artifact_relpath,
      has_request_body,
      has_response_body
    FROM call_logs
    WHERE ${scopeWhere}
    ORDER BY tokens_out DESC
    LIMIT 10
  `)
  .all(...generationPaths);

const data = {
  metric: 'call_logs.tokens_out / responseBody.usage.completion_tokens',
  scope: {
    request_count: scope.n,
    min_timestamp: scope.min_timestamp,
    max_timestamp: scope.max_timestamp,
    filter:
      'status=200, generation endpoints, exclude model-sync/connection-test',
  },
  stats,
  thresholds_gt: thresholds,
  buckets,
  by_model: byModel,
  largest,
  largest_rank: rank,
  top10,
};

function printStats() {
  console.log('Omniroute completion-token history');
  console.log(`Metric: ${data.metric}`);
  console.log(`Scope: ${fmtInt(scope.n)} successful generation requests`);
  console.log(`Range: ${fmtTimestamp(scope.min_timestamp)} -> ${fmtTimestamp(scope.max_timestamp)}`);
  console.log('');
  printTable(
    ['stat', 'tokens'],
    [
      ['min', fmtInt(stats.min)],
      ['p10', fmtInt(stats.p10)],
      ['p25', fmtInt(stats.p25)],
      ['median', fmtInt(stats.median)],
      ['average', fmtFloat(stats.average, 2)],
      ['p75', fmtInt(stats.p75)],
      ['p90', fmtInt(stats.p90)],
      ['p95', fmtInt(stats.p95)],
      ['p99', fmtInt(stats.p99)],
      ['p99.5', fmtInt(stats.p995)],
      ['p99.9', fmtInt(stats.p999)],
      ['max', fmtInt(stats.max)],
    ],
  );
  console.log('');
  printTable(
    ['limit', 'requests_above', 'percent_above'],
    thresholds.map((row) => [`>${fmtInt(row.threshold)}`, fmtInt(row.count), fmtPercent(row.percent)]),
  );
  console.log('');
  printTable(
    ['bucket', 'requests', 'percent'],
    buckets.map((row) => [row.range, fmtInt(row.count), fmtPercent(row.percent)]),
  );
}

function printLargest() {
  if (!largest) {
    console.log('No matching Omniroute completion-token rows found.');
    return;
  }

  const durationSeconds = largest.duration == null ? null : largest.duration / 1000;
  const outputRate = durationSeconds ? largest.completion_tokens / durationSeconds : null;
  const uncachedPrompt =
    largest.tokens_in == null
      ? null
      : largest.tokens_in -
        (largest.tokens_cache_read || 0) -
        (largest.tokens_cache_creation || 0);
  const totalTokens =
    largest.tokens_in == null ? null : largest.tokens_in + largest.completion_tokens;
  const above32k = largest.completion_tokens > 32768 ? largest.completion_tokens - 32768 : 0;

  console.log('Largest Omniroute response by usage.completion_tokens');
  console.log(`Timestamp:          ${largest.timestamp}`);
  console.log(`Endpoint:           ${largest.method} ${largest.path}`);
  console.log(`Status:             ${largest.status}`);
  console.log(`Model:              ${largest.model} (${largest.requested_model})`);
  console.log(`Provider:           ${largest.provider}`);
  console.log(`API key name:       ${largest.api_key_name || 'n/a'}`);
  console.log(`Completion tokens:  ${fmtInt(largest.completion_tokens)}`);
  console.log(`Reasoning tokens:   ${fmtInt(largest.tokens_reasoning)}`);
  console.log(`Prompt tokens:      ${fmtInt(largest.tokens_in)}`);
  console.log(`Cache read tokens:  ${fmtInt(largest.tokens_cache_read)}`);
  console.log(`Cache create toks:  ${fmtInt(largest.tokens_cache_creation)}`);
  console.log(`Uncached prompt:    ${fmtInt(uncachedPrompt)}`);
  console.log(`Total tokens:       ${fmtInt(totalTokens)}`);
  console.log(`Duration:           ${fmtInt(largest.duration)} ms (${fmtDuration(largest.duration)})`);
  console.log(`Output rate:        ${fmtFloat(outputRate, 2)} completion tokens/sec`);
  console.log(`Detail state:       ${largest.detail_state || 'n/a'}`);
  console.log(`Artifact:           ${largest.artifact_relpath || 'none'}`);
  console.log(`Bodies retained:    request=${largest.has_request_body ? 'yes' : 'no'}, response=${largest.has_response_body ? 'yes' : 'no'}`);
  if (rank) {
    console.log(`Historical rank:    #1 of ${fmtInt(rank.n)} (${fmtInt(rank.above)} above, ${fmtInt(rank.at_or_above)} at/above)`);
  }
  console.log(`Above 32k by:       ${fmtInt(above32k)} tokens`);
  console.log('');
  console.log('Top 10 historical responses:');
  printTable(
    ['completion', 'timestamp', 'model', 'duration', 'prompt', 'reasoning', 'cache_read', 'details'],
    top10.map((row) => [
      fmtInt(row.completion_tokens),
      row.timestamp,
      row.model,
      fmtDuration(row.duration),
      fmtInt(row.tokens_in),
      fmtInt(row.tokens_reasoning),
      fmtInt(row.tokens_cache_read),
      row.artifact_relpath ? 'artifact' : row.detail_state || 'none',
    ]),
  );
}

if (mode === 'json') {
  console.log(JSON.stringify(data, null, 2));
} else if (mode === 'stats') {
  printStats();
} else if (mode === 'largest') {
  printLargest();
} else {
  printStats();
  console.log('');
  printLargest();
}
NODE
