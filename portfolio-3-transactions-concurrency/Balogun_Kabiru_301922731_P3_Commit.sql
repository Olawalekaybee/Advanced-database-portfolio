-- Portfolio 3, demo 1: a successful token purchase (COMMIT)
-- Customer 2 (wallet 2, meter 2) buys 10 kWh at 68.74 = 687.40

SELECT 'BEFORE' AS stage,
       (SELECT balance FROM wallet WHERE wallet_id = 2)          AS wallet_balance,
       (SELECT unit_balance_kwh FROM meter WHERE meter_id = 2)   AS meter_kwh,
       (SELECT count(*) FROM token_purchase WHERE wallet_id = 2) AS purchases;

BEGIN;
UPDATE wallet SET balance = balance - 687.40, last_updated = now()
 WHERE wallet_id = 2;
INSERT INTO token_purchase (wallet_id, meter_id, kwh_units, rate_per_kwh, amount_debited, token_code)
VALUES (2, 2, 10.0000, 68.7400, 687.40, '9999-0000-0000-0000-0001');
UPDATE meter SET unit_balance_kwh = unit_balance_kwh + 10.0000
 WHERE meter_id = 2;
COMMIT;

SELECT 'AFTER' AS stage,
       (SELECT balance FROM wallet WHERE wallet_id = 2)          AS wallet_balance,
       (SELECT unit_balance_kwh FROM meter WHERE meter_id = 2)   AS meter_kwh,
       (SELECT count(*) FROM token_purchase WHERE wallet_id = 2) AS purchases;