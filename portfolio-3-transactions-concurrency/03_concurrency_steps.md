# Demo 3: concurrency (two windows, same wallet)

Wallet 4 holds 26,000.00. Two customers' purchases of 20,000.00 each are processed at the same time. Only one of them can really afford it.

Open two terminals in VS Code (use the split terminal button) and start psql in each:

    psql -U postgres -d aowlyf_energy

Call them Window A and Window B. Do the steps in the exact order shown, switching windows as indicated.

## Part 1: the problem (no locking)

Reset first (in Window A):

    \i portfolio-1-database-design/schema.sql
    \i portfolio-1-database-design/sample-data.sql

| Step | Window | Type this |
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

Check (either window):

    SELECT balance FROM wallet WHERE wallet_id = 4;
    SELECT token_code, amount_debited FROM token_purchase WHERE wallet_id = 4;

Result: the wallet fell by only 20,000.00 (26,000.00 to 6,000.00), but two purchases of 20,000.00 were issued. Both windows read the old balance, and the second write overwrote the first. This is a **lost update**. 20,000.00 worth of electricity was given away.

Take a screenshot of the check output.

## Part 2: the fix (row locking with FOR UPDATE)

Reset again (in Window A) with the same two `\i` lines as above. Then:

| Step | Window | Type this |
|---|---|---|
| 1 | A | `BEGIN;` |
| 2 | A | `SELECT balance FROM wallet WHERE wallet_id = 4 FOR UPDATE;` (26000.00, and the row is now locked) |
| 3 | B | `BEGIN;` |
| 4 | B | `SELECT balance FROM wallet WHERE wallet_id = 4 FOR UPDATE;` (it **waits**, nothing appears) |
| 5 | A | `UPDATE wallet SET balance = balance - 20000.00 WHERE wallet_id = 4;` |
| 6 | A | `INSERT INTO token_purchase (wallet_id, meter_id, kwh_units, rate_per_kwh, amount_debited, token_code) VALUES (4, 4, 200, 100, 20000.00, 'AAAA-0001');` |
| 7 | A | `COMMIT;` |
| 8 | B | Window B now unfreezes and shows balance **6000.00**. |
| 9 | B | B sees only 6,000.00 left, which is less than 20,000.00, so it stops: `ROLLBACK;` |

Check: the wallet is 6,000.00 and only one new purchase exists. The second customer is told "insufficient funds". Take a screenshot of Window B waiting (step 4) and of the result in step 8.

## What to write in your portfolio

- Problem: two transactions read the same balance and both wrote a result based on it (lost update).
- Control mechanism: `SELECT ... FOR UPDATE` locks the row, so the second transaction waits and then sees the updated balance. This is pessimistic locking and gives isolation.
- Link to ACID: this demonstrates the **I** (isolation). The earlier rollback demo shows the **A** (atomicity).