-- Portfolio 3, demo 2: a failed token purchase (ROLLBACK)
-- Customer 2 tries to buy 100 kWh (6,874.00) but the wallet holds far less.
-- The wallet CHECK (balance >= 0) rejects the first UPDATE, so nothing is kept.

SELECT 'BEFORE' AS stage,
       (SELECT balance FROM wallet WHERE wallet_id = 2)          AS wallet_balance,
       (SELECT unit_balance_kwh FROM meter WHERE meter_id = 2)   AS meter_kwh,
       (SELECT count(*) FROM token_purchase WHERE wallet_id = 2) AS purchases;

BEGIN;
UPDATE wallet SET balance = balance - 6874.00, last_updated = now()
 WHERE wallet_id = 2;
-- The statement above fails, so the transaction is aborted. Later statements are ignored.
INSERT INTO token_purchase (wallet_id, meter_id, kwh_units, rate_per_kwh, amount_debited, token_code)
VALUES (2, 2, 100.0000, 68.7400, 6874.00, '9999-0000-0000-0000-0002');
UPDATE meter SET unit_balance_kwh = unit_balance_kwh + 100.0000
 WHERE meter_id = 2;
ROLLBACK;

SELECT 'AFTER' AS stage,
       (SELECT balance FROM wallet WHERE wallet_id = 2)          AS wallet_balance,
       (SELECT unit_balance_kwh FROM meter WHERE meter_id = 2)   AS meter_kwh,
       (SELECT count(*) FROM token_purchase WHERE wallet_id = 2) AS purchases;