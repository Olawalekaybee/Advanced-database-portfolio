
# Advanced Database Systems Portfolio (MIT 8103)

Student: Balogun Kabiru | Student ID: 301922731 | MIVA Open University

## 1. Selected case study

AOWLYF Dynamics Energy Services is a simulated electricity distribution company. Its regional offices serve Lagos, Kano and Ogun states. Prepaid electricity reaches customers through smart meters, each of which sends a reading to a central platform every fifteen minutes. Every reading records the energy consumed in kilowatt-hours, the voltage, the current and the time it was taken.

The database is used by customers, field technicians, billing officers, regional managers and system administrators. Each user has unique login details and signs in through a role-based login and administration page.

The database holds user accounts, customer records and the premises linked to each customer. It also stores meters and their consumption readings, tariff bands, prepaid wallets, token purchases with their payments, fault alerts and technician work orders.

Its key operations are registering customers and installing meters, recording readings as they arrive, topping up a wallet and generating a token, and deducting credit as electricity is consumed. The system also detects abnormal consumption or outages, dispatches a technician to resolve the problem, authenticates users, and produces regional consumption reports.

## 2. Repository structure

| Folder                               | Activity                                |
| ------------------------------------ | --------------------------------------- |
| portfolio-1-database-design          | Database design and modelling           |
| portfolio-2-query-optimisation       | Query processing and optimisation       |
| portfolio-3-transactions-concurrency | Transactions and concurrency            |
| portfolio-4-nosql                    | NoSQL and advanced data models          |
| portfolio-5-distributed-cloud        | Distributed and cloud database exercise |

## 3. How each activity was implemented and tested

### Portfolio 1: Database design and modelling

**Folder:** `portfolio-1-database-design`

In this portfolio I model the AOWLYF Dynamics Energy Services database in PostgreSQL 18. It has 13 tables covering users, customers, premises, meters, readings, prepaid wallets, payments, token purchases, fault alerts and technician work orders.

#### Files

| File                 | What it contains                                                                        |
| -------------------- | --------------------------------------------------------------------------------------- |
| `case-study.md`    | The case study statement                                                                |
| `entities.md`      | Every entity with its attributes, keys, relationships and constraints                   |
| `er-diagram.md`    | The ER diagram (Mermaid)                                                                |
| `schema.sql`       | Creates all 13 tables with primary keys, foreign keys, UNIQUE, NOT NULL and CHECK rules |
| `sample-data.sql`  | Invented sample rows for every table                                                    |
| `normalisation.md` | Normalisation from a flat record to 3NF and BCNF                                        |
| `screenshots/`     | ER diagram on GitHub, tables in psql, and constraint errors                             |

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

- [er-diagram-github.png](portfolio-1-database-design/screenshots/er-diagram-github.png): the ER diagram rendering on GitHub
- [psql-tables.png](portfolio-1-database-design/screenshots/psql-tables.png): all 13 tables created
- [psql-constraint-errors.png](portfolio-1-database-design/screenshots/psql-constraint-errors.png): an invalid region and a negative balance both rejected

### Portfolio 2: Query processing and optimisation

**Folder:** `portfolio-2-query-optimisation`

In this portfolio I look at how an index changes the way PostgreSQL runs a query. It builds a separate table, `reading_big`, with 500,000 meter readings (50 meters, one reading every 15 minutes) and compares four query plans using `EXPLAIN (ANALYZE, BUFFERS)`. The Portfolio 1 tables are not touched.

#### Files

| File                      | What it contains                                               |
| ------------------------- | -------------------------------------------------------------- |
| `01_index_demo.sql`     | Builds `reading_big`, then runs the four plans               |
| `02_report_queries.sql` | Three report queries on the Portfolio 1 tables, with two plans |
| `query-analysis.md`     | The results and my explanation of them                         |
| `screenshots/`          | The query plans and the report query results                   |

#### What was tested

| Situation                                      | Query plan        | Execution time |
| ---------------------------------------------- | ----------------- | -------------- |
| Without an index                               | Parallel Seq Scan | 208.864 ms     |
| Composite index on `(meter_id, recorded_at)` | Index Scan        | 0.573 ms       |
| Filter written as `date(recorded_at) = ...`  | Bitmap Heap Scan  | 4.394 ms       |
| Same day written as a date range               | Index Scan        | 0.102 ms       |

Report queries on the real tables (`02_report_queries.sql`):

| Situation                                                           | Estimated cost | Execution time |
| ------------------------------------------------------------------- | -------------- | -------------- |
| Regional consumption query, planner's own choice (sequential scans) | 42.13          | 0.194 ms       |
| Same query with sequential scans switched off for the session       | 53.31          | 0.457 ms       |

With so few rows, forcing indexes made the query slower. The index only pays off on the large table in the first demo.

#### How to run

From the repository root, connect with `psql -U postgres -d aowlyf_energy`, then run `\pset pager off` followed by `\i portfolio-2-query-optimisation/01_index_demo.sql`. For the report queries, load `schema.sql` and `sample-data.sql` from `portfolio-1-database-design` first, then run `\i portfolio-2-query-optimisation/02_report_queries.sql`.

#### Limits

- Each plan was run once on one machine, so the exact times will differ elsewhere. The pattern is what matters.
- The data in the first demo is generated and evenly spread, not real meter data.
- The report queries run on very small sample data, so their timings only show which plan the planner chooses.

#### Evidence

- [plan-before-index.png](portfolio-2-query-optimisation/screenshots/plan-before-index.png)
- [plan-after-index.png](portfolio-2-query-optimisation/screenshots/plan-after-index.png)
- [plan-function.png](portfolio-2-query-optimisation/screenshots/plan-function.png)
- [plan-range.png](portfolio-2-query-optimisation/screenshots/plan-range.png)
- [query-results.png](portfolio-2-query-optimisation/screenshots/query-results.png)
- [plan-small-tables.png](portfolio-2-query-optimisation/screenshots/plan-small-tables.png)
- [plan-seqscan-off.png](portfolio-2-query-optimisation/screenshots/plan-seqscan-off.png)

### Portfolio 3: Transactions and concurrency

**Folder:** `portfolio-3-transactions-concurrency`

This portfolio uses the PostgreSQL database from Portfolio 1 to show how a token purchase behaves as a transaction. A token purchase changes three things together: it reduces the customer's wallet balance, records the token purchase, and adds kWh to the meter.

#### Files

| File                        | What it shows                                                            |
| --------------------------- | ------------------------------------------------------------------------ |
| `01_commit.sql`           | A successful token purchase that is committed                            |
| `02_rollback.sql`         | A failed purchase that is rolled back, leaving no partial changes        |
| `03_concurrency_steps.md` | Two windows buying against the same wallet, the lost update, and the fix |
| `screenshots/`            | Output from each demo                                                    |

#### What was tested

1. **Commit.** I bought 10 kWh for 687.40 from wallet 2. The wallet fell from 1,563.00 to 875.60, the meter rose from 80 to 90 kWh, and a purchase row was added, all at once.
2. **Rollback (atomicity).** I tried a purchase of 6,874.00 with too little money. The wallet's `CHECK (balance >= 0)` rejected it, the transaction aborted, and `ROLLBACK` left every table unchanged.
3. **Lost update (isolation problem).** In two windows I read the same wallet balance of 26,000.00 and sold 20,000.00 of electricity from each. The wallet fell by only 20,000.00, but two purchases were issued, so 20,000.00 of electricity was given away.
4. **Row locking (fix).** With `SELECT ... FOR UPDATE`, the second window waited for the first to commit, then saw the new balance of 6,000.00, and I rolled it back. Only one purchase was issued.

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

- [demo1-commit.png](portfolio-3-transactions-concurrency/screenshots/demo1-commit.png)
- [demo2-rollback.png](portfolio-3-transactions-concurrency/screenshots/demo2-rollback.png)
- [demo3-lost-update.png](portfolio-3-transactions-concurrency/screenshots/demo3-lost-update.png)
- [demo3-for-update-waiting.png](portfolio-3-transactions-concurrency/screenshots/demo3-for-update-waiting.png)
- [demo3-for-update-result.png](portfolio-3-transactions-concurrency/screenshots/demo3-for-update-result.png)

### Portfolio 4: NoSQL and advanced data models

**Folder:** `portfolio-4-nosql`

This portfolio adds two NoSQL stores to the same AOWLYF case study. MongoDB Atlas (document model) holds daily meter telemetry and device events. Neo4j Aura (graph model) holds how customers, premises, meters, faults and technicians connect. PostgreSQL stays the system of record for money and customer data. I explain the design and my reasons in `nosql-design.md`.

#### Files

| File                        | What it contains                                                                   |
| --------------------------- | ---------------------------------------------------------------------------------- |
| `nosql-design.md`         | Document and graph models, why they suit the data, graph compared with SQL, limits |
| `01_meter_telemetry.json` | Four sample documents, one per meter per day, with embedded readings               |
| `02_device_events.json`   | Four device events with different fields                                           |
| `03_mongodb_queries.js`   | MongoDB queries, aggregation and index with explain plan                           |
| `04_neo4j_load.cypher`    | Builds the graph (31 nodes, 32 relationships)                                      |
| `05_neo4j_queries.cypher` | Graph queries, including the design question and a shortest path                   |
| `06_sql_equivalent.sql`   | The design question written in SQL, for comparison                                 |
| `screenshots/`            | Results from both databases                                                        |

#### What was tested

1. **MongoDB.** I read one meter's day as a single document, totalled kWh per region (Lagos 6.22, Kano 0.57, the same as Portfolio 2), searched for low voltage (it finds AOW-KN-0005), and stored device events with different fields in one collection.
2. **MongoDB index.** I ran the same query before and after a compound index on `meter_number` and `date`. A collection scan of 4 documents became an index scan of 1.
3. **Neo4j.** For a faulty meter, I found the other meters in its region and the technicians who worked on them (Kano, AOW-KN-0005, AOW-KN-0002, Sani Abdullahi). I also listed the affected customers, counted work orders per technician, and found the shortest path from a customer to a technician.

#### How to run

1. MongoDB Atlas: create a free cluster, create the database `aowlyf_nosql` with the collections `meter_telemetry` and `device_events`, and insert the two JSON files. Run the queries in `03_mongodb_queries.js` in the Data Explorer.
2. Neo4j Aura: create a free instance, open Query, run `04_neo4j_load.cypher` once as a single statement, then run the queries in `05_neo4j_queries.cypher` one at a time.
3. Optional: run `06_sql_equivalent.sql` in `aowlyf_energy` to compare with the graph result.

Connection strings, passwords and the Aura credentials file are not stored in this repository.

#### Limits

- The data is a small sample from Portfolio 1, and the three databases are not kept in sync automatically.
- Both cloud databases are on free tiers. An Aura Free instance is deleted after 30 days of inactivity, so the Cypher scripts are how the graph is rebuilt.
- At this size SQL and the graph give the same answer. The graph's advantage appears with deeper questions, and I did not test at real scale.

#### Evidence

- MongoDB: [mongo-find-meter-day.png](portfolio-4-nosql/screenshots/mongo-find-meter-day.png), [mongo-aggregation-region.png](portfolio-4-nosql/screenshots/mongo-aggregation-region.png), [mongo-low-voltage.png](portfolio-4-nosql/screenshots/mongo-low-voltage.png), [mongo-device-events.png](portfolio-4-nosql/screenshots/mongo-device-events.png), [mongo-explain-before.png](portfolio-4-nosql/screenshots/mongo-explain-before.png), [mongo-index-created.png](portfolio-4-nosql/screenshots/mongo-index-created.png), [mongo-explain.png](portfolio-4-nosql/screenshots/mongo-explain.png)
- Neo4j: [neo4j-load-result.png](portfolio-4-nosql/screenshots/neo4j-load-result.png), [neo4j-graph-overview.png](portfolio-4-nosql/screenshots/neo4j-graph-overview.png), [neo4j-design-question.png](portfolio-4-nosql/screenshots/neo4j-design-question.png), [neo4j-affected-customers.png](portfolio-4-nosql/screenshots/neo4j-affected-customers.png), [neo4j-workload.png](portfolio-4-nosql/screenshots/neo4j-workload.png), [neo4j-shortest-path.png](portfolio-4-nosql/screenshots/neo4j-shortest-path.png)

### Portfolio 5: Distributed and cloud database exercise

**Folder:** `portfolio-5-distributed-cloud`

In this portfolio I describe how the AOWLYF database would be spread across servers for Lagos, Kano and Ogun, and I demonstrate sharding by region in PostgreSQL.

#### Files

| File                           | What it contains                                                   |
| ------------------------------ | ------------------------------------------------------------------ |
| `distributed-design.md`      | Sharding, replication, CAP choice per table and a failure scenario |
| `01_partition_by_region.sql` | A demonstration of partitioning readings by `region_id`          |
| `screenshots/`               | Output of the demonstration                                        |

#### What was tested

1. I copied the readings into a table partitioned by region and checked that each row landed in its region's partition.
2. I ran a query for Kano readings and confirmed from the plan that only the Kano partition is scanned.
3. I ran a query without the region and confirmed that all three partitions are scanned.

#### How to run

Load `schema.sql` and `sample-data.sql` from `portfolio-1-database-design`, connect with `psql -U postgres -d aowlyf_energy`, then run `01_partition_by_region.sql`.

#### Limits

- The demonstration runs on one server, so the partitions are not on separate machines.
- Replication, failover and cloud deployment are design discussion only and were not built.

#### Evidence

- [partition-rows.png](portfolio-5-distributed-cloud/screenshots/partition-rows.png)
- [explain-kano.png](portfolio-5-distributed-cloud/screenshots/explain-kano.png)
- [explain-all.png](portfolio-5-distributed-cloud/screenshots/explain-all.png)

## 4. Individual technical reflection

The design decision I am most confident about is keeping wallets and token purchases as separate tables in PostgreSQL. A wallet holds money, and a token purchase records the units loaded onto a meter, so keeping them apart keeps the financial records clear and traceable. In Portfolio 3 I saw why this matters. When two transactions updated the same wallet at once, one update was lost until I used `SELECT ... FOR UPDATE`.

The hardest part was getting the queries and screenshots to show the right evidence. In MongoDB I first created two single-field indexes instead of one compound index. I had to delete them and create the correct one before the explain plan changed from a collection scan to an index scan. I got through it by checking each result against what I expected and running it again.

Two results surprised me. An index cut one query from 208.864 ms to 0.573 ms on 500,000 rows. On the small Portfolio 1 tables, though, forcing indexes made the report query slower (0.457 ms against 0.194 ms), so whether an index helps depends on the size of the data and the shape of the query. Wrapping a column in `date()` also made a query slower even though the index existed.

If this were a real system, the first thing I would add is a process to keep PostgreSQL, MongoDB and Neo4j updated automatically. For now I load the other two stores by hand from the PostgreSQL sample, so they could drift apart. PostgreSQL stays the system of record for wallets and token purchases because these records are customers' money and must always be accurate. Its transaction controls prevent duplicate purchases and wrong balances when many customers buy at the same time.

## 5. References

- MIVA Open University (2026). *MIT 8103 Advanced Database Systems*, course text (Study Sessions 1, 2, 4 and 5) and lecture slides.
- MIVA Open University (2026). *MIT 8103 First Semester Continuous Assessment, September Cohort*, assignment brief.
- PostgreSQL Global Development Group. PostgreSQL documentation: EXPLAIN, Using EXPLAIN, Indexes, Transaction Isolation, Explicit Locking, Table Partitioning. https://www.postgresql.org/docs/ (accessed November 2026).
- MongoDB, Inc. MongoDB Manual: Aggregation, Indexes, Explain results. https://www.mongodb.com/docs/manual/ (accessed November 2026).
- Neo4j, Inc. Cypher Manual and Neo4j Aura documentation. https://neo4j.com/docs/ (accessed November 2026).

## 6. AI Use Declaration

**Tool used:** Claude (Anthropic).

**What I used it for:**

- Explaining course concepts (database design, normalisation, transactions, distributed databases, NoSQL and graph databases) as a study aid.
- Drafting the starting version of the entity list, the Mermaid ER diagram, `schema.sql`, `sample-data.sql`, the transaction demo scripts and the partitioning demo.
- Drafting `01_index_demo.sql` and `02_report_queries.sql`, the MongoDB sample data and queries, the Neo4j Cypher scripts and the SQL comparison query.
- Helping me structure `normalisation.md`, `query-analysis.md`, `nosql-design.md`, `distributed-design.md`, this README and the final document, using my own answers, results and explanations.
- Step-by-step guidance for setting up PostgreSQL tooling, MongoDB Atlas and Neo4j Aura, and for Git and GitHub.

**How I checked the output:**

- I ran `schema.sql`, `sample-data.sql` and every demo script myself in PostgreSQL 18 and kept screenshots of the results.
- I tested that invalid data is rejected (an unknown region and a negative wallet balance).
- I ran the two-window concurrency demo by hand and recorded the lost update and the row-locking fix.
- I ran the partitioning demo and checked from the query plans that only the Kano partition is scanned for a Kano query.
- I ran `01_index_demo.sql` and `02_report_queries.sql`, captured the query plans and results, and checked that the index and the date-range rewrite made the queries faster, while the `date()` version did not use the index fully.
- I created the MongoDB Atlas cluster and the Neo4j Aura instance myself, loaded the data, ran every query and kept screenshots. I checked that the MongoDB regional totals match my PostgreSQL results from Portfolio 2, and that the SQL version of the graph question returns the same row as the graph query.
- I answered the normalisation, distributed-systems and design questions in my own words before the write-ups were finalised, and checked them against my schema and my results.
- The reflection above is based on my own answers, and I can explain every file in this repository.
