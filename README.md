# Advanced Database Systems Portfolio (MIT 8103)

Student: Balogun Kabiru | Student ID: 301922731 | MIVA Open University

## 1. Selected case study

AOWLYF Dynamics Energy Services is a simulated electricity distribution company. Its regional offices serve Lagos, Kano and Ogun states. Prepaid electricity reaches customers through smart meters, each of which sends a reading to a central platform every fifteen minutes. Every reading records the energy consumed in kilowatt-hours, the voltage, the current and the time it was taken.

The database is used by customers, field technicians, billing officers, regional managers and system administrators. Each user has unique login details and signs in through a role-based login and administration page.

The database holds user accounts, customer records and the premises linked to each customer. It also stores meters and their consumption readings, tariff bands, prepaid wallets, token purchases with their payments, fault alerts and technician work orders.

Its key operations are registering customers and installing meters, recording readings as they arrive, topping up a wallet and generating a token, and deducting credit as electricity is consumed. The system also detects abnormal consumption or outages, dispatches a technician to resolve the problem, authenticates users, and produces regional consumption reports.

## 2. Repository structure

| Folder | Activity |
|---|---|
| portfolio-1-database-design | Database design and modelling |
| portfolio-2-query-optimisation | Query processing and optimisation |
| portfolio-3-transactions-concurrency | Transactions and concurrency |
| portfolio-4-nosql | NoSQL and advanced data models |
| portfolio-5-distributed-cloud | Distributed and cloud database exercise |

## 3. How each activity was implemented and tested

### Portfolio 1: Database design and modelling

**Folder:** `portfolio-1-database-design`

This portfolio models the AOWLYF Dynamics Energy Services database in PostgreSQL 18. It has 13 tables covering users, customers, premises, meters, readings, prepaid wallets, payments, token purchases, fault alerts and technician work orders.

#### Files

| File | What it contains |
|---|---|
| `case-study.md` | The case study statement |
| `entities.md` | Every entity with its attributes, keys, relationships and constraints |
| `er-diagram.md` | The ER diagram (Mermaid) |
| `schema.sql` | Creates all 13 tables with primary keys, foreign keys, UNIQUE, NOT NULL and CHECK rules |
| `sample-data.sql` | Invented sample rows for every table |
| `normalisation.md` | Normalisation from a flat record to 3NF and BCNF |
| `screenshots/` | ER diagram on GitHub, tables in psql, and constraint errors |

#### Key design decisions

- A wallet holds money. Buying a token debits the wallet and adds kWh to the meter's balance.
- Customers and staff share one `user_account` table. Each has a separate profile table.
- Payments (money in) and token purchases (units issued) are separate tables.
- `token_purchase` keeps its own rate, so a later tariff change does not alter old purchases.

#### How to run

1. Create a database: `CREATE DATABASE aowlyf_energy;` and connect to it.
2. Run `schema.sql`, then `sample-data.sql`.
3. Check with `\dt`. It should list 13 tables.

#### Limits of this portfolio

- The rule that a work order goes only to a technician is not enforced in the schema.
- Updating wallet and meter balances in a single transaction is covered in Portfolio 3.

#### Evidence

- `screenshots/er-diagram-github.png`: the ER diagram rendering on GitHub
- `screenshots/psql-tables.png`: all 13 tables created
- `screenshots/psql-constraint-errors.png`: an invalid region and a negative balance both rejected

### Portfolio 2: Query processing and optimisation

**Folder:** `portfolio-2-query-optimisation`

This portfolio shows how an index changes the way PostgreSQL runs a query. It builds a separate table, `reading_big`, with 500,000 meter readings (50 meters, one reading every 15 minutes) and compares four query plans using `EXPLAIN (ANALYZE, BUFFERS)`. The Portfolio 1 tables are not touched.

#### Files

| File | What it contains |
|---|---|
| `01_index_demo.sql` | Builds `reading_big`, then runs the four plans |
| `query-analysis.md` | The results and my explanation of them |
| `screenshots/` | The four query plans |

#### What was tested

| Situation | Query plan | Execution time |
|---|---|---|
| Without an index | Parallel Seq Scan | 208.864 ms |
| Composite index on `(meter_id, recorded_at)` | Index Scan | 0.573 ms |
| Filter written as `date(recorded_at) = ...` | Bitmap Heap Scan | 4.394 ms |
| Same day written as a date range | Index Scan | 0.102 ms |

#### How to run

From the repository root, connect with `psql -U postgres -d aowlyf_energy`, then run `\pset pager off` followed by `\i portfolio-2-query-optimisation/01_index_demo.sql`.

#### Limits

- Each plan was run once on one machine, so the exact times will differ elsewhere. The pattern is what matters.
- The data is generated and evenly spread, not real meter data.

#### Evidence

- `screenshots/plan-before-index.png`
- `screenshots/plan-after-index.png`
- `screenshots/plan-function.png`
- `screenshots/plan-range.png`

### Portfolio 3: Transactions and concurrency

**Folder:** `portfolio-3-transactions-concurrency`

This portfolio uses the PostgreSQL database from Portfolio 1 to show how a token purchase behaves as a transaction. A token purchase changes three things together: it reduces the customer's wallet balance, records the token purchase, and adds kWh to the meter.

#### Files

| File | What it shows |
|---|---|
| `01_commit.sql` | A successful token purchase that is committed |
| `02_rollback.sql` | A failed purchase that is rolled back, leaving no partial changes |
| `03_concurrency_steps.md` | Two windows buying against the same wallet, the lost update, and the fix |
| `screenshots/` | Output from each demo |

#### What was tested

1. **Commit.** Wallet 2 bought 10 kWh for 687.40. The wallet fell from 1,563.00 to 875.60, the meter rose from 80 to 90 kWh, and a purchase row was added, all at once.
2. **Rollback (atomicity).** A purchase of 6,874.00 was attempted with too little money. The wallet's `CHECK (balance >= 0)` rejected it, the transaction was aborted, and `ROLLBACK` left every table unchanged.
3. **Lost update (isolation problem).** Two windows each read a wallet balance of 26,000.00 and each sold 20,000.00 of electricity. The wallet fell by only 20,000.00 but two purchases were issued, so 20,000.00 of electricity was given away.
4. **Row locking (fix).** With `SELECT ... FOR UPDATE`, the second window waited for the first to commit, then saw the new balance of 6,000.00 and rolled back. Only one purchase was issued.

#### Concepts demonstrated

- **Atomicity:** demo 2, where the whole purchase succeeds or none of it does.
- **Consistency:** the wallet and meter constraints (CHECK, UNIQUE) reject invalid states.
- **Isolation:** demos 3 and 4, where concurrent transactions interfere until row locking is used.
- **Durability:** committed purchases remain after the transaction ends.

#### How to run

1. Create the database and load `schema.sql` and `sample-data.sql` from `portfolio-1-database-design`, in that order.
2. Connect with `psql -U postgres -d aowlyf_energy` and run `01_commit.sql`, then `02_rollback.sql`.
3. Follow `03_concurrency_steps.md` in two terminal windows.

Run `01_commit.sql` only once on a fresh database, because its token code must be unique. To repeat it, reload `schema.sql` and `sample-data.sql` first.

#### Limits

- The concurrency demo was run by hand in two psql windows, not with a load-testing tool.
- Only the default isolation level (READ COMMITTED) was used.

#### Evidence

- `screenshots/demo1-commit.png`
- `screenshots/demo2-rollback.png`
- `screenshots/demo3-lost-update.png`
- `screenshots/demo3-for-update-waiting.png`
- `screenshots/demo3-for-update-result.png`

### Portfolio 4: NoSQL and advanced data models

[to be completed]

### Portfolio 5: Distributed and cloud database exercise

**Folder:** `portfolio-5-distributed-cloud`

This portfolio describes how the AOWLYF database would be distributed across servers for Lagos, Kano and Ogun, and demonstrates sharding by region in PostgreSQL.

#### Files

| File | What it contains |
|---|---|
| `distributed-design.md` | Sharding, replication, CAP choice per table and a failure scenario |
| `01_partition_by_region.sql` | A demonstration of partitioning readings by `region_id` |
| `screenshots/` | Output of the demonstration |

#### What was tested

1. Readings were copied into a table partitioned by region, and each row landed in its region's partition.
2. A query for Kano readings scanned only the Kano partition.
3. A query without the region scanned all three partitions.

#### How to run

Load `schema.sql` and `sample-data.sql` from `portfolio-1-database-design`, connect with `psql -U postgres -d aowlyf_energy`, then run `01_partition_by_region.sql`.

#### Limits

- The demonstration runs on one server, so the partitions are not on separate machines.
- Replication, failover and cloud deployment are design discussion only and were not built.

#### Evidence

- `screenshots/partition-rows.png`
- `screenshots/explain-kano.png`
- `screenshots/explain-all.png`

## 4. Individual technical reflection

[added at the end]

## 5. References

[added as I go]

## 6. AI Use Declaration

**Tool used:** Claude (Anthropic).

**What it was used for so far:**
- Explaining course concepts (database design, normalisation, transactions, distributed databases) as a study aid.
- Helping draft the entity list structure, the Mermaid ER diagram, `schema.sql`, `sample-data.sql`, the SQL demo scripts for transactions and the sharding demonstration.
- Drafting `01_index_demo.sql` and the starting structure of `query-analysis.md`, built from the plans and timings I produced myself.
- Drafting the starting structure of `normalisation.md`, `distributed-design.md` and the README layout, built from my own explanations and answers, which I then reviewed and edited.

**How I verified the output:**
- I ran `schema.sql`, `sample-data.sql` and every demo script myself in PostgreSQL 18 and kept screenshots of the results.
- I tested that invalid data is rejected (an unknown region and a negative wallet balance).
- I carried out the two-window concurrency demo by hand and recorded the lost update and the row-locking fix.
- I ran the partitioning demonstration and checked from the query plans that only the Kano partition is scanned for a Kano query.
- I ran `01_index_demo.sql` myself, captured the four query plans, and checked that the index and the date-range rewrite made the queries faster, while the `date()` version did not use the index fully.
- I answered the normalisation, distributed-systems and design questions in my own words before the write-ups were finalised, and checked them against my schema and my results.

[this declaration will be updated as Portfolio 4 and the final documentation are completed]