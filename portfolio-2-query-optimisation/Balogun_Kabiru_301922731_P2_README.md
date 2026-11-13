# Portfolio 2: Query Processing and Optimisation

Student: Balogun Kabiru | Student ID: 301922731 | Case study: AOWLYF Dynamics Energy Services

In this portfolio I look at how an index changes the way PostgreSQL runs a query. It builds a separate table, `reading_big`, with 500,000 meter readings (50 meters, one reading every 15 minutes) and compares four query plans using `EXPLAIN (ANALYZE, BUFFERS)`. The Portfolio 1 tables are not touched.

## Files

| File | What it contains |
|---|---|
| [Balogun_Kabiru_301922731_P2_Optimisation.sql](Balogun_Kabiru_301922731_P2_Optimisation.sql) | Builds `reading_big`, then runs the four plans |
| [Balogun_Kabiru_301922731_P2_Queries.sql](Balogun_Kabiru_301922731_P2_Queries.sql) | Three report queries on the Portfolio 1 tables, with two plans |
| [Balogun_Kabiru_301922731_P2_Analysis.md](Balogun_Kabiru_301922731_P2_Analysis.md) | The results and my explanation of them |
| [screenshots/](screenshots/) | The query plans and the report query results |

## What was tested

| Situation | Query plan | Execution time |
|---|---|---|
| Without an index | Parallel Seq Scan | 208.864 ms |
| Composite index on `(meter_id, recorded_at)` | Index Scan | 0.573 ms |
| Filter written as `date(recorded_at) = ...` | Bitmap Heap Scan | 4.394 ms |
| Same day written as a date range | Index Scan | 0.102 ms |

Report queries on the real tables (`Balogun_Kabiru_301922731_P2_Queries.sql`):

| Situation | Estimated cost | Execution time |
|---|---|---|
| Regional consumption query, planner's own choice (sequential scans) | 42.13 | 0.194 ms |
| Same query with sequential scans switched off for the session | 53.31 | 0.457 ms |

With so few rows, forcing indexes made the query slower. The index only pays off on the large table in the first demo.

## How to run

From the repository root, connect with `psql -U postgres -d aowlyf_energy`, then run `\pset pager off` followed by `\i portfolio-2-query-optimisation/Balogun_Kabiru_301922731_P2_Optimisation.sql`. For the report queries, load `Balogun_Kabiru_301922731_P1_Schema.sql` and `Balogun_Kabiru_301922731_P1_SampleData.sql` from `portfolio-1-database-design` (one folder up) first, then run `\i portfolio-2-query-optimisation/Balogun_Kabiru_301922731_P2_Queries.sql`.

## Limits

- Each plan was run once on one machine, so the exact times will differ elsewhere. The pattern is what matters.
- The data in the first demo is generated and evenly spread, not real meter data.
- The report queries run on very small sample data, so their timings only show which plan the planner chooses.

## Evidence

- [Balogun_Kabiru_301922731_P2_BeforeIndex.png](screenshots/Balogun_Kabiru_301922731_P2_BeforeIndex.png)
- [Balogun_Kabiru_301922731_P2_AfterIndex.png](screenshots/Balogun_Kabiru_301922731_P2_AfterIndex.png)
- [Balogun_Kabiru_301922731_P2_FunctionPlan.png](screenshots/Balogun_Kabiru_301922731_P2_FunctionPlan.png)
- [Balogun_Kabiru_301922731_P2_RangePlan.png](screenshots/Balogun_Kabiru_301922731_P2_RangePlan.png)
- [Balogun_Kabiru_301922731_P2_QueryResults.png](screenshots/Balogun_Kabiru_301922731_P2_QueryResults.png)
- [Balogun_Kabiru_301922731_P2_SmallTablesPlan.png](screenshots/Balogun_Kabiru_301922731_P2_SmallTablesPlan.png)
- [Balogun_Kabiru_301922731_P2_SeqscanOffPlan.png](screenshots/Balogun_Kabiru_301922731_P2_SeqscanOffPlan.png)
