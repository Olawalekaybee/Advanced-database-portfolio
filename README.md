
# MIT 8103 Advanced Database Systems Portfolio

Name: Balogun Kabiru

Student ID: 301922731

Institution: MIVA Open University, Master of Information Technology

Final summary: see `Balogun_Kabiru_301922731_FinalSummary.pdf`.

## Case study

AOWLYF Dynamics Energy Services is a simulated electricity distribution company. Its regional offices serve Lagos, Kano and Ogun states. Prepaid electricity reaches customers through smart meters, each of which sends a reading to a central platform every fifteen minutes. Every reading records the energy consumed in kilowatt-hours, the voltage, the current and the time it was taken.

The database is used by customers, field technicians, billing officers, regional managers and system administrators. Each user has unique login details and signs in through a role-based login and administration page.

The database holds user accounts, customer records and the premises linked to each customer. It also stores meters and their consumption readings, tariff bands, prepaid wallets, token purchases with their payments, fault alerts and technician work orders.

Its key operations are registering customers and installing meters, recording readings as they arrive, topping up a wallet and generating a token, and deducting credit as electricity is consumed. The system also detects abnormal consumption or outages, dispatches a technician to resolve the problem, authenticates users, and produces regional consumption reports.

## Portfolio folders

Each folder has its own README with the design, how to run the scripts, the results, the limits and links to the screenshots.

- [Portfolio 1: Database Design and Modelling](portfolio-1-database-design/Balogun_Kabiru_301922731_P1_README.md)
- [Portfolio 2: Query Processing and Optimisation](portfolio-2-query-optimisation/Balogun_Kabiru_301922731_P2_README.md)
- [Portfolio 3: Transactions and Concurrency](portfolio-3-transactions-concurrency/Balogun_Kabiru_301922731_P3_README.md)
- [Portfolio 4: NoSQL and Advanced Data Models](portfolio-4-nosql/Balogun_Kabiru_301922731_P4_README.md)
- [Portfolio 5: Distributed and Cloud Database Exercise](portfolio-5-distributed-cloud/Balogun_Kabiru_301922731_P5_README.md)

| Folder | Main result |
|---|---|
| portfolio-1-database-design | 13-table PostgreSQL schema in 3NF with keys and CHECK rules, tested with invalid inserts |
| portfolio-2-query-optimisation | A composite index cut a query from 208.864 ms to 0.573 ms on 500,000 rows; on small tables forced indexes were slower |
| portfolio-3-transactions-concurrency | Commit, rollback, a lost update between two sessions, and the fix with `SELECT ... FOR UPDATE` |
| portfolio-4-nosql | MongoDB telemetry and events (COLLSCAN to IXSCAN with a compound index) and a Neo4j graph (31 nodes, 32 relationships) |
| portfolio-5-distributed-cloud | Partitioning readings by region, with a CAP choice for each table; replication is a design only |

## How to run

Load `portfolio-1-database-design/Balogun_Kabiru_301922731_P1_Schema.sql` and then `Balogun_Kabiru_301922731_P1_SampleData.sql` in a PostgreSQL database named `aowlyf_energy`. The scripts in the other folders run on top of that data. Each portfolio README gives the exact steps. Connection strings and passwords are not stored in this repository.

## Individual technical reflection

The design decision I am most confident about is keeping wallets and token purchases as separate tables in PostgreSQL. A wallet holds money, and a token purchase records the units loaded onto a meter, so keeping them apart keeps the financial records clear and traceable. In Portfolio 3 I saw why this matters. When two transactions updated the same wallet at once, one update was lost until I used `SELECT ... FOR UPDATE`.

The hardest part was getting the queries and screenshots to show the right evidence. In MongoDB I first created two single-field indexes instead of one compound index. I had to delete them and create the correct one before the explain plan changed from a collection scan to an index scan. I got through it by checking each result against what I expected and running it again.

Two results surprised me. An index cut one query from 208.864 ms to 0.573 ms on 500,000 rows. On the small Portfolio 1 tables, though, forcing indexes made the report query slower (0.457 ms against 0.194 ms), so whether an index helps depends on the size of the data and the shape of the query. Wrapping a column in `date()` also made a query slower even though the index existed.

If this were a real system, the first thing I would add is a process to keep PostgreSQL, MongoDB and Neo4j updated automatically. For now I load the other two stores by hand from the PostgreSQL sample, so they could drift apart. PostgreSQL stays the system of record for wallets and token purchases because these records are customers' money and must always be accurate. Its transaction controls prevent duplicate purchases and wrong balances when many customers buy at the same time.

## References

- MIVA Open University (2026). *MIT 8103 Advanced Database Systems*, course text (Study Sessions 1, 2, 4 and 5) and lecture slides.
- PostgreSQL Global Development Group. PostgreSQL documentation: EXPLAIN, Using EXPLAIN, Indexes, Transaction Isolation, Explicit Locking, Table Partitioning. https://www.postgresql.org/docs/ (accessed November 2026).
- MongoDB, Inc. MongoDB Manual: Aggregation, Indexes, Explain results. https://www.mongodb.com/docs/manual/ (accessed November 2026).
- Neo4j, Inc. Cypher Manual and Neo4j Aura documentation. https://neo4j.com/docs/ (accessed November 2026).
- Mermaid. Entity relationship diagram syntax, used for the ER diagram. https://mermaid.js.org/syntax/entityRelationshipDiagram.html (accessed November 2026).

All sample data in this repository (customers, meters, readings, payments and staff) is fictional and was created for this portfolio. No real customer data was used.

## AI Use Declaration

**Tool used:** Claude (Anthropic).

**What I used it for:**
- Explaining course concepts (database design, normalisation, transactions, distributed databases, NoSQL and graph databases) as a study aid.
- Drafting the starting version of the entity list, the Mermaid ER diagram, `Balogun_Kabiru_301922731_P1_Schema.sql`, `Balogun_Kabiru_301922731_P1_SampleData.sql`, the transaction demo scripts and the partitioning demo.
- Drafting `Balogun_Kabiru_301922731_P2_Optimisation.sql` and `Balogun_Kabiru_301922731_P2_Queries.sql`, the MongoDB sample data and queries, the Neo4j Cypher scripts and the SQL comparison query.
- Helping me structure `Balogun_Kabiru_301922731_P1_Normalisation.md`, `Balogun_Kabiru_301922731_P2_Analysis.md`, `Balogun_Kabiru_301922731_P4_Design.md`, `Balogun_Kabiru_301922731_P5_Design.md`, this README and the final document, using my own answers, results and explanations.

**How I checked the output:**
- I ran `Balogun_Kabiru_301922731_P1_Schema.sql`, `Balogun_Kabiru_301922731_P1_SampleData.sql` and every demo script myself in PostgreSQL 18 and kept screenshots of the results.
- I tested that invalid data is rejected (an unknown region and a negative wallet balance).
- I ran the two-window concurrency demo by hand and recorded the lost update and the row-locking fix.
- I ran the partitioning demo and checked from the query plans that only the Kano partition is scanned for a Kano query.
- I ran `Balogun_Kabiru_301922731_P2_Optimisation.sql` and `Balogun_Kabiru_301922731_P2_Queries.sql`, captured the query plans and results, and checked that the index and the date-range rewrite made the queries faster, while the `date()` version did not use the index fully.
- I created the MongoDB Atlas cluster and the Neo4j Aura instance myself, loaded the data, ran every query and kept screenshots. I checked that the MongoDB regional totals match my PostgreSQL results from Portfolio 2, and that the SQL version of the graph question returns the same row as the graph query.
- I answered the normalisation, distributed-systems and design questions in my own words before the write-ups were finalised, and checked them against my schema and my results.
