# Portfolio 2: Query processing and optimisation

## What I tested

The Portfolio 1 tables hold only a handful of rows, so any plan on them would be a sequential scan whatever I did. To see an index matter, `01_index_demo.sql` builds a separate table, `reading_big`, with 50 meters and 10,000 readings each (one every 15 minutes), 500,000 rows in total. The Portfolio 1 tables are not touched.

The query asks for the average consumption of meter 7 over one week:

```sql
SELECT avg(kwh_consumed) FROM reading_big
WHERE meter_id = 7
  AND recorded_at >= '2026-10-01' AND recorded_at < '2026-10-08';
```

I ran it with `EXPLAIN (ANALYZE, BUFFERS)` four times. The setup was PostgreSQL 18.6 on my own laptop, one run per plan.

## Results

| # | Situation | Plan | Cost estimate | Execution time |
|---|-----------|------|---------------|----------------|
| 1 | No index | Parallel Seq Scan | 8323.79 | 208.864 ms |
| 2 | Index on (meter_id, recorded_at) | Index Scan | 1163.91 | 0.573 ms |
| 3 | Same index, but `date(recorded_at) = '2026-10-01'` | Bitmap Heap Scan | 4091.74 | 4.394 ms |
| 4 | Same index, one day written as a range | Index Scan | 166.45 | 0.102 ms |

Screenshots: `screenshots/plan-before-index.png`, `plan-after-index.png`, `plan-function.png`, `plan-range.png`.

## 1. Before and after the index

Without an index, PostgreSQL had to read every row of the table. The plan shows `Rows Removed by Filter: 166443` in each of three workers, which is about 499,000 rows read and thrown away to find the 672 that belong to meter 7 in that week.

After `CREATE INDEX idx_reading_big_meter_time ON reading_big (meter_id, recorded_at)`, the plan changed to an Index Scan and the time dropped from 208.864 ms to 0.573 ms, roughly 360 times faster. The estimated cost fell from 8323.79 to 1163.91 as well. The order of the columns matters: the index first narrows to meter 7, and inside that meter the readings are already sorted by time, so the date range is one continuous slice.

## 2. A function on the column stops the index being used properly

In plan 3 I wrote the filter as `date(recorded_at) = '2026-10-01'`. The index stores `recorded_at`, not `date(recorded_at)`, so PostgreSQL cannot use the time part of the index. It could only use `meter_id = 7`, which pulled in all 10,000 rows of that meter, and then it checked each row against the date. The plan shows this as `Rows Removed by Filter: 9904`, and the time was 4.394 ms.

In plan 4 I asked for the same day as a range (`recorded_at >= '2026-10-01' AND recorded_at < '2026-10-02'`). Now both columns appear in the `Index Cond`, only the 96 matching rows are read, and the time was 0.102 ms. That is about 43 times faster for the same answer. A filter written so the bare column can be compared is called sargable; wrapping the column in a function makes it non-sargable.

## 3. Estimated against actual rows

The planner chooses a plan from estimated row counts, which come from table statistics collected by `ANALYZE`.

| Plan | Estimated rows | Actual rows |
|------|----------------|-------------|
| 1 | 291 per worker (about 873) | 224 per worker (672) |
| 2 | 707 | 672 |
| 3 | 51 | 96 |
| 4 | 91 | 96 |

The estimates are close but not exact, because statistics are a summary of the data, not the data itself. They are good enough to pick the right plan here. If the statistics were old, for example after a large load of readings without running `ANALYZE`, the estimates could be far off and the planner could pick a poor plan.

## 4. Limits of this test

- Each plan was run once on one machine, so the exact milliseconds will differ on another computer. The pattern (scan, then index, then function versus range) is what the test shows.
- Timings after the first run benefit from data already being in memory (`shared hit` in the buffers line), which is why they are so small.
- The data is generated, with evenly spread readings. Real meter data may be less even.
- An index is not free. It takes disk space and must be updated on every insert, and the meters send a reading every 15 minutes, so on a very busy table I would only keep the indexes I need.