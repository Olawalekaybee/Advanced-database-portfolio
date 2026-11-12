---
noteId: "97b839d0dea111f1af14e3682d930608"
tags: []

---

# Demo 3: concurrency (two windows, same wallet)

This demo tests what happens when two purchases hit the same wallet at the same moment. Wallet 4 holds 26,000.00, and two purchases of 20,000.00 each arrive together. Only one of them can really be afforded.

I opened two terminals in VS Code (split terminal) and started psql in each:

    psql -U postgres -d aowlyf_energy

I call them Window A and Window B. The steps below are in the exact order I ran them, switching windows as shown.

## Part 1: the problem (no locking)

I reset the data first, in Window A:

    \i portfolio-1-database-design/Balogun_Kabiru_301922731_P1_Schema.sql
    \i portfolio-1-database-design/Balogun_Kabiru_301922731_P1_SampleData.sql

| Step | Window | What I ran |
|---|---|---|
| 1 | A | `BEGIN;` |
| 2 | A | `SELECT balance FROM wallet WHERE wallet_id = 4;` (shows 26000.00) |
| 3 | B | `BEGIN;` |
| 4 | B | `SELECT balance FROM wallet WHERE wallet_id = 4;` (also shows 26000.00) |
| 5 | A | `UPDATE wallet SET balance = 6000.00 WHERE wallet_id = 4;` |
| 6 | A | `INSERT INTO token_purchase (wallet_id, meter_id, kwh_units, rate_per_kwh, amount_debited, token_code) VALUES (4, 4, 200, 100, 20000.00, 'AAAA-0001');` |
| 7 | A | `COMMIT;` |
| 8 | B | `UPDATE wallet SET balance = 6000.00 WHERE wallet_id = 4;` |
| 9 | B | `INSERT INTO token_purchase (wallet_id, meter_id, kwh_units, rate_per_kwh, amount_debited, token_code) VALUES (4, 4, 200, 100, 20000.00, 'BBBB-0001');` |
| 10 | B | `COMMIT;` |

Then I checked, in either window:

    SELECT balance FROM wallet WHERE wallet_id = 4;
    SELECT token_code, amount_debited FROM token_purchase WHERE wallet_id = 4;

Result: the wallet fell by only 20,000.00 (26,000.00 to 6,000.00), but two purchases of 20,000.00 were issued. Both windows read the old balance, and the second write overwrote the first. This is a **lost update**, and 20,000.00 worth of electricity was given away.

Screenshot: [Balogun_Kabiru_301922731_P3_LostUpdate.png](screenshots/Balogun_Kabiru_301922731_P3_LostUpdate.png).

## Part 2: the fix (row locking with FOR UPDATE)

I reset again in Window A with the same two `\i` lines, then ran:

| Step | Window | What I ran |
|---|---|---|
| 1 | A | `BEGIN;` |
| 2 | A | `SELECT balance FROM wallet WHERE wallet_id = 4 FOR UPDATE;` (26000.00, and the row is now locked) |
| 3 | B | `BEGIN;` |
| 4 | B | `SELECT balance FROM wallet WHERE wallet_id = 4 FOR UPDATE;` (it **waits**, nothing appears) |
| 5 | A | `UPDATE wallet SET balance = balance - 20000.00 WHERE wallet_id = 4;` |
| 6 | A | `INSERT INTO token_purchase (wallet_id, meter_id, kwh_units, rate_per_kwh, amount_debited, token_code) VALUES (4, 4, 200, 100, 20000.00, 'AAAA-0001');` |
| 7 | A | `COMMIT;` |
| 8 | B | Window B now unfreezes and shows balance **6000.00**. |
| 9 | B | Only 6,000.00 is left, which is less than 20,000.00, so I stopped the purchase with `ROLLBACK;` |

Result: the wallet is 6,000.00 and only one new purchase exists. In a real system the second customer would be told "insufficient funds". Screenshots: Window B waiting ([Balogun_Kabiru_301922731_P3_SessionsWaiting.png](screenshots/Balogun_Kabiru_301922731_P3_SessionsWaiting.png)) and the result ([Balogun_Kabiru_301922731_P3_ConcurrencyResult.png](screenshots/Balogun_Kabiru_301922731_P3_ConcurrencyResult.png)).

## What this shows

- **The problem:** two transactions read the same balance and both wrote a result based on it, so one update was lost.
- **The control:** `SELECT ... FOR UPDATE` locks the row. The second transaction waits, then sees the updated balance. This is pessimistic locking.
- **Link to ACID:** this demo is about the **I** (isolation). The earlier rollback demo ([Balogun_Kabiru_301922731_P3_Rollback.png](screenshots/Balogun_Kabiru_301922731_P3_Rollback.png)) is about the **A** (atomicity).
- **Limit:** I only used the default isolation level, READ COMMITTED. I did not test REPEATABLE READ or SERIALIZABLE.
