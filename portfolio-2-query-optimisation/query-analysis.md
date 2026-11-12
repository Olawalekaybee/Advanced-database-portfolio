---
noteId: "6ecf8991de9e11f1af14e3682d930608"
tags: []

---

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

Screenshots: [plan-before-index.png](screenshots/plan-before-index.png), [plan-after-index.png](screenshots/plan-after-index.png), [plan-function.png](screenshots/plan-function.png), [plan-range.png](screenshots/plan-range.png).

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

---

# Part B: report queries on the Portfolio 1 tables

`01_index_demo.sql` used a large generated table. `02_report_queries.sql` runs three realistic report queries on the actual Portfolio 1 tables and sample data, so the same case study is used throughout.

## The queries and what they return

| # | Query | Tables joined | Result |
|---|-------|---------------|--------|
| 1 | Regional consumption for 10 November | reading, meter, premises, region | Lagos: 6 readings, 6.2200 kWh, average 228.80 V. Kano: 5 readings, 0.5700 kWh, average 138.56 V |
| 2 | Token purchase history per customer | token_purchase, wallet, customer, meter | 4 purchases, each with the meter, units, rate, amount debited and the wallet balance that is left |
| 3 | Unresolved faults and their technician | fault_alert, meter, work_order, staff_profile | Alert 1 (outage on AOW-KN-0005) with technician Sani Abdullahi, and alert 2 (abnormal consumption on AOW-LG-0004) with no technician yet |

Two things in the results are worth noting:

- **Kano's average voltage is low (138.56 V).** Meter AOW-KN-0005 reported 0 V during its outage, and those zero readings pull the regional average down. A real report would either exclude zero-voltage readings from the average or flag them as outages.
- **Query 3 uses a LEFT JOIN on purpose.** Alert 2 has no work order, so an ordinary JOIN would drop it. The LEFT JOIN keeps it and shows a blank technician, which is exactly the alert someone needs to dispatch. The `status <> 'cancelled'` condition sits in the join so the earlier cancelled work order for alert 1 is ignored without removing alert 1.

## Plan for Query 1 with the planner's own choice

| Measure | Value |
|---|---|
| Estimated cost | 42.13 |
| Execution time | 0.194 ms |
| Buffers read | 46 |

The planner scanned `reading` and `meter` sequentially, joined them with a hash join, and then looked up `premises` and `region` through their primary-key indexes (`premises_pkey`, `region_pkey`). The `reading` filter kept 11 rows out of 11, because every reading in the sample data falls on 10 November.

## Plan with sequential scans switched off

I then ran `SET enable_seqscan = off` for the session and repeated the query. The planner was forced to use indexes, and it chose a Bitmap Heap Scan on `reading` through the `reading_meter_id_recorded_at_key` index and an index scan on `meter` as well.

| Measure | Planner's choice | Seq scans off |
|---|---|---|
| Estimated cost | 42.13 | 53.31 |
| Execution time | 0.194 ms | 0.457 ms |
| Buffers read | 46 | 71 |

Forcing the indexes made the query slower and more expensive, about 2.4 times slower in time and about 27 percent higher in estimated cost. The tables hold only a few rows, so reading a whole table is cheaper than walking an index and then fetching rows. The planner's original choice was correct, and the estimated costs ranked the two plans in the same order as the real timings.

The index it used in the forced plan starts with `meter_id`, but this query filters only on `recorded_at`. That is a poor fit for the index, which is another reason it is not the better plan.

## What this adds to Part A

Part A showed an index helping when a table has 500,000 rows. Part B shows the reverse: with a few rows, the sequential scan wins, and forcing an index costs more. Together they show that indexing should be decided from the size of the data and the shape of the query, not applied everywhere. For the real system, readings arrive every 15 minutes from every meter, so the readings table is the one that will grow large and benefit from the `(meter_id, recorded_at)` index, while small tables such as `region` and `tariff_band` do not need extra ones.

## Limits

- The sample data is tiny, so these timings are fractions of a millisecond and are not a reliable benchmark. The point is which plan the planner chooses and why.
- `enable_seqscan = off` was used only to compare plans. It was reset straight afterwards and is not a setting to leave on.


Screenshots for Part B: [query-results.png](screenshots/query-results.png), [plan-small-tables.png](screenshots/plan-small-tables.png), [plan-seqscan-off.png](screenshots/plan-seqscan-off.png).
