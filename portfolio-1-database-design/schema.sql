
-- AOWLYF Dynamics Energy Services : Portfolio 1 schema (PostgreSQL)
-- Student ID: 301922731
-- Run order: parent tables first, then child tables.
-- Re-runnable: the DROP block removes old tables first.
-- =====================================================================

DROP TABLE IF EXISTS work_order, fault_alert, token_purchase, payment,
    wallet, reading, meter, premises, staff_profile, customer,
    user_account, tariff_band, region CASCADE;

-- ---------- Reference tables ----------

CREATE TABLE region (
    region_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    region_name  VARCHAR(50) NOT NULL UNIQUE
                 CHECK (region_name IN ('Lagos', 'Kano', 'Ogun'))
);

CREATE TABLE tariff_band (
    tariff_band_id  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    band_name       VARCHAR(50)   NOT NULL UNIQUE,
    rate_per_kwh    NUMERIC(10,4) NOT NULL CHECK (rate_per_kwh > 0),
    effective_from  DATE          NOT NULL
);

-- ---------- Users ----------

CREATE TABLE user_account (
    user_id        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username       VARCHAR(60)  NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL,   -- hash only, never the password
    role           VARCHAR(30)  NOT NULL
                   CHECK (role IN ('customer', 'technician', 'billing_officer',
                                   'regional_manager', 'sys_admin')),
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE customer (
    customer_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id       INT          NOT NULL UNIQUE
                  REFERENCES user_account(user_id) ON DELETE RESTRICT,
    first_name    VARCHAR(60)  NOT NULL,
    last_name     VARCHAR(60)  NOT NULL,
    email         VARCHAR(120) NOT NULL UNIQUE,
    phone_number  VARCHAR(20)  NOT NULL
);

CREATE TABLE staff_profile (
    staff_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     INT          NOT NULL UNIQUE
                REFERENCES user_account(user_id) ON DELETE RESTRICT,
    region_id   INT          NOT NULL
                REFERENCES region(region_id) ON DELETE RESTRICT,
    first_name  VARCHAR(60)  NOT NULL,
    last_name   VARCHAR(60)  NOT NULL,
    job_title   VARCHAR(80)  NOT NULL
);

-- ---------- Premises and meters ----------

CREATE TABLE premises (
    premises_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id     INT NOT NULL
                    REFERENCES customer(customer_id) ON DELETE RESTRICT,
    address         VARCHAR(255) NOT NULL,
    region_id       INT NOT NULL
                    REFERENCES region(region_id) ON DELETE RESTRICT,
    tariff_band_id  INT NOT NULL
                    REFERENCES tariff_band(tariff_band_id) ON DELETE RESTRICT
);

CREATE TABLE meter (
    meter_id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    meter_number      VARCHAR(30) NOT NULL UNIQUE,
    premises_id       INT NOT NULL
                      REFERENCES premises(premises_id) ON DELETE RESTRICT,
    installation_date DATE NOT NULL,
    removal_date      DATE,
    status            VARCHAR(20) NOT NULL
                      CHECK (status IN ('active', 'replaced', 'faulty')),
    unit_balance_kwh  NUMERIC(12,4) NOT NULL DEFAULT 0
                      CHECK (unit_balance_kwh >= 0),
    CHECK (removal_date IS NULL OR removal_date >= installation_date)
);

CREATE TABLE reading (
    reading_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    meter_id      INT NOT NULL
                  REFERENCES meter(meter_id) ON DELETE RESTRICT,
    kwh_consumed  NUMERIC(10,4) NOT NULL CHECK (kwh_consumed >= 0),
    voltage       NUMERIC(7,2)  NOT NULL CHECK (voltage >= 0),
    current_amps  NUMERIC(7,2)  NOT NULL CHECK (current_amps >= 0),
    recorded_at   TIMESTAMPTZ   NOT NULL,
    UNIQUE (meter_id, recorded_at)
);

-- ---------- Money ----------

CREATE TABLE wallet (
    wallet_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id   INT NOT NULL UNIQUE
                  REFERENCES customer(customer_id) ON DELETE RESTRICT,
    balance       NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
    last_updated  TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE TABLE payment (
    payment_id      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    wallet_id       INT NOT NULL
                    REFERENCES wallet(wallet_id) ON DELETE RESTRICT,
    reference_code  VARCHAR(60) NOT NULL UNIQUE,
    amount          NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    payment_method  VARCHAR(20) NOT NULL
                    CHECK (payment_method IN ('card', 'bank_transfer', 'ussd')),
    status          VARCHAR(20) NOT NULL
                    CHECK (status IN ('pending', 'successful', 'failed')),
    paid_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE token_purchase (
    purchase_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    wallet_id       INT NOT NULL
                    REFERENCES wallet(wallet_id) ON DELETE RESTRICT,
    meter_id        INT NOT NULL
                    REFERENCES meter(meter_id) ON DELETE RESTRICT,
    kwh_units       NUMERIC(12,4) NOT NULL CHECK (kwh_units > 0),
    rate_per_kwh    NUMERIC(10,4) NOT NULL CHECK (rate_per_kwh > 0),
    amount_debited  NUMERIC(14,2) NOT NULL CHECK (amount_debited > 0),
    token_code      VARCHAR(30) NOT NULL UNIQUE,
    purchased_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (amount_debited = ROUND(kwh_units * rate_per_kwh, 2))
);

-- ---------- Faults and maintenance ----------

CREATE TABLE fault_alert (
    alert_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    meter_id     INT NOT NULL
                 REFERENCES meter(meter_id) ON DELETE RESTRICT,
    alert_type   VARCHAR(30) NOT NULL
                 CHECK (alert_type IN ('outage', 'abnormal_consumption', 'tampering')),
    detected_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    status       VARCHAR(20) NOT NULL DEFAULT 'open'
                 CHECK (status IN ('open', 'investigating', 'resolved'))
);

CREATE TABLE work_order (
    work_order_id      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    alert_id           INT NOT NULL
                       REFERENCES fault_alert(alert_id) ON DELETE RESTRICT,
    assigned_staff_id  INT NOT NULL
                       REFERENCES staff_profile(staff_id) ON DELETE RESTRICT,
    status             VARCHAR(20) NOT NULL DEFAULT 'pending'
                       CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at       TIMESTAMPTZ,
    CHECK (completed_at IS NULL OR completed_at >= created_at)
);