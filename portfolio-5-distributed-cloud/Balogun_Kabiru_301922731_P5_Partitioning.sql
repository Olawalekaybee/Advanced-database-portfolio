-- Portfolio 5, demo 1: horizontal fragmentation (sharding idea) by region
-- Run in aowlyf_energy after Balogun_Kabiru_301922731_P1_Schema.sql and Balogun_Kabiru_301922731_P1_SampleData.sql.
-- region_id is the shard key: Lagos = 1, Kano = 2, Ogun = 3.
-- This is a single-server demonstration of the same idea used to place
-- each region's data on its own server.

DROP TABLE IF EXISTS reading_by_region;

CREATE TABLE reading_by_region (
    reading_id    BIGINT        NOT NULL,
    meter_id      INT           NOT NULL,
    region_id     INT           NOT NULL,
    kwh_consumed  NUMERIC(10,4) NOT NULL CHECK (kwh_consumed >= 0),
    voltage       NUMERIC(7,2)  NOT NULL CHECK (voltage >= 0),
    current_amps  NUMERIC(7,2)  NOT NULL CHECK (current_amps >= 0),
    recorded_at   TIMESTAMPTZ   NOT NULL,
    PRIMARY KEY (reading_id, region_id)
) PARTITION BY LIST (region_id);

CREATE TABLE reading_lagos PARTITION OF reading_by_region FOR VALUES IN (1);
CREATE TABLE reading_kano  PARTITION OF reading_by_region FOR VALUES IN (2);
CREATE TABLE reading_ogun  PARTITION OF reading_by_region FOR VALUES IN (3);

-- Copy the existing readings, adding each meter's region.
INSERT INTO reading_by_region
SELECT r.reading_id, r.meter_id, p.region_id,
       r.kwh_consumed, r.voltage, r.current_amps, r.recorded_at
FROM reading r
JOIN meter m    ON m.meter_id    = r.meter_id
JOIN premises p ON p.premises_id = m.premises_id;

-- 1. Where did each row go?
SELECT tableoid::regclass AS stored_in, region_id, count(*) AS readings
FROM reading_by_region
GROUP BY 1, 2
ORDER BY 2;

-- 2. A Kano query touches only the Kano partition (partition pruning).
EXPLAIN
SELECT * FROM reading_by_region WHERE region_id = 2;

-- 3. A query without the shard key has to look in every partition.
EXPLAIN
SELECT * FROM reading_by_region WHERE meter_id = 1;