-- =====================================================================
-- AOWLYF Dynamics Energy Services : Portfolio 2, demo 2
-- Report queries on the real Portfolio 1 tables, with their plans.
-- Run in aowlyf_energy after Balogun_Kabiru_301922731_P1_Schema.sql and Balogun_Kabiru_301922731_P1_SampleData.sql.
-- Student ID: 301922731
-- =====================================================================

\pset pager off

-- ---------------------------------------------------------------------
-- Query 1: regional consumption report for one day.
-- Joins reading -> meter -> premises -> region and groups by region.
-- ---------------------------------------------------------------------
SELECT rg.region_name,
       count(*)                      AS readings,
       round(sum(r.kwh_consumed), 4) AS total_kwh,
       round(avg(r.voltage), 2)      AS avg_voltage
FROM reading r
JOIN meter m    ON m.meter_id    = r.meter_id
JOIN premises p ON p.premises_id = m.premises_id
JOIN region rg  ON rg.region_id  = p.region_id
WHERE r.recorded_at >= '2026-11-10' AND r.recorded_at < '2026-11-11'
GROUP BY rg.region_name
ORDER BY total_kwh DESC;

-- ---------------------------------------------------------------------
-- Query 2: token purchase history for each customer, with the meter
-- that received the units and the wallet balance that is left.
-- ---------------------------------------------------------------------
SELECT c.first_name || ' ' || c.last_name AS customer,
       m.meter_number,
       tp.kwh_units,
       tp.rate_per_kwh,
       tp.amount_debited,
       w.balance AS wallet_balance_now
FROM token_purchase tp
JOIN wallet   w ON w.wallet_id   = tp.wallet_id
JOIN customer c ON c.customer_id = w.customer_id
JOIN meter    m ON m.meter_id    = tp.meter_id
ORDER BY c.last_name, tp.purchased_at;

-- ---------------------------------------------------------------------
-- Query 3: faults that are not resolved, with the technician working
-- on each one. LEFT JOIN keeps alerts that have no work order yet, and
-- the work order filter ignores cancelled orders.
-- ---------------------------------------------------------------------
SELECT fa.alert_id,
       m.meter_number,
       fa.alert_type,
       fa.status AS alert_status,
       s.first_name || ' ' || s.last_name AS technician,
       wo.status AS work_order_status
FROM fault_alert fa
JOIN meter m ON m.meter_id = fa.meter_id
LEFT JOIN work_order wo
       ON wo.alert_id = fa.alert_id AND wo.status <> 'cancelled'
LEFT JOIN staff_profile s ON s.staff_id = wo.assigned_staff_id
WHERE fa.status <> 'resolved'
ORDER BY fa.alert_id;

-- ---------------------------------------------------------------------
-- Execution plan for Query 1. The tables hold only a few rows, so the
-- planner is expected to read the small tables sequentially, because
-- reading a whole table is cheaper than using an index at this size.
-- ---------------------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT rg.region_name,
       count(*), round(sum(r.kwh_consumed), 4), round(avg(r.voltage), 2)
FROM reading r
JOIN meter m    ON m.meter_id    = r.meter_id
JOIN premises p ON p.premises_id = m.premises_id
JOIN region rg  ON rg.region_id  = p.region_id
WHERE r.recorded_at >= '2026-11-10' AND r.recorded_at < '2026-11-11'
GROUP BY rg.region_name;

-- ---------------------------------------------------------------------
-- The same plan with sequential scans switched off for this session
-- only, to see what the planner would do if forced to use indexes and
-- how its cost estimate compares. RESET puts the setting back.
-- ---------------------------------------------------------------------
SET enable_seqscan = off;

EXPLAIN (ANALYZE, BUFFERS)
SELECT rg.region_name,
       count(*), round(sum(r.kwh_consumed), 4), round(avg(r.voltage), 2)
FROM reading r
JOIN meter m    ON m.meter_id    = r.meter_id
JOIN premises p ON p.premises_id = m.premises_id
JOIN region rg  ON rg.region_id  = p.region_id
WHERE r.recorded_at >= '2026-11-10' AND r.recorded_at < '2026-11-11'
GROUP BY rg.region_name;

RESET enable_seqscan;