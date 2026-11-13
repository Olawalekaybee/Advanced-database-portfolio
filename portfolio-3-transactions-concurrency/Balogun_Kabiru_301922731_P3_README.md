# Portfolio 3: Transactions and Concurrency

Student: Balogun Kabiru | Student ID: 301922731 | Case study: AOWLYF Dynamics Energy Services

This portfolio uses the PostgreSQL database from Portfolio 1 to show how a token purchase behaves as a transaction. A token purchase changes three things together: it reduces the customer's wallet balance, records the token purchase, and adds kWh to the meter.

## Files

| File | What it shows |
|---|---|
| [Balogun_Kabiru_301922731_P3_Commit.sql](Balogun_Kabiru_301922731_P3_Commit.sql) | A successful token purchase that is committed |
| [Balogun_Kabiru_301922731_P3_Rollback.sql](Balogun_Kabiru_301922731_P3_Rollback.sql) | A failed purchase that is rolled back, leaving no partial changes |
| [Balogun_Kabiru_301922731_P3_Concurrency.md](Balogun_Kabiru_301922731_P3_Concurrency.md) | Two windows buying against the same wallet, the lost update, and the fix |
| [screenshots/](screenshots/) | Output from each demo |

## What was tested

1. **Commit.** I bought 10 kWh for 687.40 from wallet 2. The wallet fell from 1,563.00 to 875.60, the meter rose from 80 to 90 kWh, and a purchase row was added, all at once.
2. **Rollback (atomicity).** I tried a purchase of 6,874.00 with too little money. The wallet's `CHECK (balance >= 0)` rejected it, the transaction aborted, and `ROLLBACK` left every table unchanged.
3. **Lost update (isolation problem).** In two windows I read the same wallet balance of 26,000.00 and sold 20,000.00 of electricity from each. The wallet fell by only 20,000.00, but two purchases were issued, so 20,000.00 of electricity was given away.
4. **Row locking (fix).** With `SELECT ... FOR UPDATE`, the second window waited for the first to commit, then saw the new balance of 6,000.00, and I rolled it back. Only one purchase was issued.

## Concepts demonstrated

- **Atomicity:** demo 2, where the whole purchase succeeds or none of it does.
- **Consistency:** the wallet and meter constraints (CHECK, UNIQUE) reject invalid states.
- **Isolation:** demos 3 and 4, where concurrent transactions interfere until row locking is used.
- **Durability:** committed purchases remain after the transaction ends.

## How to run

1. Create the database and load `Balogun_Kabiru_301922731_P1_Schema.sql` and `Balogun_Kabiru_301922731_P1_SampleData.sql` from `portfolio-1-database-design` (one folder up), in that order.
2. Connect with `psql -U postgres -d aowlyf_energy` and run `Balogun_Kabiru_301922731_P3_Commit.sql`, then `Balogun_Kabiru_301922731_P3_Rollback.sql`.
3. Follow `Balogun_Kabiru_301922731_P3_Concurrency.md` in two terminal windows.

Run `Balogun_Kabiru_301922731_P3_Commit.sql` only once on a fresh database, because its token code must be unique. To repeat it, reload `Balogun_Kabiru_301922731_P1_Schema.sql` and `Balogun_Kabiru_301922731_P1_SampleData.sql` first.

## Limits

- The concurrency demo was run by hand in two psql windows, not with a load-testing tool.
- Only the default isolation level (READ COMMITTED) was used.

## Evidence

- [Balogun_Kabiru_301922731_P3_Commit.png](screenshots/Balogun_Kabiru_301922731_P3_Commit.png)
- [Balogun_Kabiru_301922731_P3_Rollback.png](screenshots/Balogun_Kabiru_301922731_P3_Rollback.png)
- [Balogun_Kabiru_301922731_P3_LostUpdate.png](screenshots/Balogun_Kabiru_301922731_P3_LostUpdate.png)
- [Balogun_Kabiru_301922731_P3_SessionsWaiting.png](screenshots/Balogun_Kabiru_301922731_P3_SessionsWaiting.png)
- [Balogun_Kabiru_301922731_P3_ConcurrencyResult.png](screenshots/Balogun_Kabiru_301922731_P3_ConcurrencyResult.png)
