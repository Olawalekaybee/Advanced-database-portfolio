-- Portfolio 2, demo 1: how an index changes a query plan
-- Run in aowlyf_energy. This creates its own large table, so the
-- Portfolio 1 tables are not touched.
-- 50 meters x 10,000 readings (one every 15 minutes) = 500,000 rows.

DROP TABLE IF EXISTS reading_big;

CREATE TABLE reading_big (
    reading_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    meter_id      INT           NOT NULL,
    kwh_consumed  NUMERIC(10,4) NOT NULL,
    voltage       NUMERIC(7,2)  NOT NULL,
    recorded_at   TIMESTAMPTZ   NOT NULL
);

INSERT INTO reading_big (meter_id, kwh_consumed, voltage, recorded_at)
SELECT m,
       round((random() * 0.5 + 0.1)::numeric, 4),
       round((random() * 10 + 225)::numeric, 2),
       timestamptz '2026-08-01 00:00:00+01' + (n * interval '15 minutes')
FROM generate_series(1, 50) AS m,
     generate_series(0, 9999) AS n;

-- Give the optimiser fresh statistics (the cost model depends on them).
ANALYZE reading_big;

-- The query: one meter's usage for one week.

-- 1. BEFORE the index: expect a sequential scan of all rows.
EXPLAIN (ANALYZE, BUFFERS)
SELECT avg(kwh_consumed)
FROM reading_big
WHERE meter_id = 7
  AND recorded_at >= '2026-10-01' AND recorded_at < '2026-10-08';

-- 2. Create an index that matches the WHERE clause.
CREATE INDEX idx_reading_big_meter_time
    ON reading_big (meter_id, recorded_at);
ANALYZE reading_big;

-- 3. AFTER the index: expect an index (or bitmap) scan.
EXPLAIN (ANALYZE, BUFFERS)
SELECT avg(kwh_consumed)
FROM reading_big
WHERE meter_id = 7
  AND recorded_at >= '2026-10-01' AND recorded_at < '2026-10-08';

-- 4. A query written so that the index cannot be used
--    (a function on the column hides it from the index).
EXPLAIN (ANALYZE, BUFFERS)
SELECT avg(kwh_consumed)
FROM reading_big
WHERE meter_id = 7
  AND date(recorded_at) = '2026-10-01';

-- 5. The same question rewritten as a range, which can use the index.
EXPLAIN (ANALYZE, BUFFERS)
SELECT avg(kwh_consumed)
FROM reading_big
WHERE meter_id = 7
  AND recorded_at >= '2026-10-01' AND recorded_at < '2026-10-02';