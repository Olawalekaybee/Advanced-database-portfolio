-- SQL version of the Neo4j design question (Cypher query 2), on the
-- Portfolio 1 tables, for comparison. Run in aowlyf_energy.
SELECT rg.region_name,
       mf.meter_number AS faulty_meter,
       mo.meter_number AS other_meter,
       string_agg(DISTINCT s.first_name || ' ' || s.last_name, ', ') AS technicians
FROM meter mf
JOIN premises pf   ON pf.premises_id = mf.premises_id
JOIN region rg     ON rg.region_id   = pf.region_id
JOIN premises po   ON po.region_id   = pf.region_id
JOIN meter mo      ON mo.premises_id = po.premises_id
                  AND mo.meter_id  <> mf.meter_id
LEFT JOIN fault_alert fa  ON fa.meter_id   = mo.meter_id
LEFT JOIN work_order wo   ON wo.alert_id   = fa.alert_id
                         AND wo.status    <> 'cancelled'
LEFT JOIN staff_profile s ON s.staff_id    = wo.assigned_staff_id
WHERE mf.status = 'faulty'
GROUP BY rg.region_name, mf.meter_number, mo.meter_number;
