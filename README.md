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

#### Limits

- The concurrency demo was run by hand in two psql windows, not with a load-testing tool.
- Only the default isolation level (READ COMMITTED) was used.

#### Evidence

- `screenshots/demo1-commit.png`
- `screenshots/demo2-rollback.png`
- `screenshots/demo3-lost-update.png`
- `screenshots/demo3-for-update-waiting.png`
- `screenshots/demo3-for-update-result.png`

## 4. Individual technical reflection

[added at the end]

## 5. References

[added as I go]

## 6. AI Use Declaration

[tool used, what it was used for, and how I verified the output]