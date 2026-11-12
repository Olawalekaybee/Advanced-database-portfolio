---
noteId: "6ece9f30de9e11f1af14e3682d930608"
tags: []

---

# Portfolio 1: Entity List

AOWLYF Dynamics Energy Services. Student ID: 301922731.

## Summary

| Entity | Primary key | Foreign keys |
|---|---|---|
| user_account | user_id | None |
| customer | customer_id | user_id |
| premises | premises_id | customer_id, region_id, tariff_band_id |
| meter | meter_id | premises_id |
| reading | reading_id | meter_id |
| wallet | wallet_id | customer_id |
| token_purchase | purchase_id | wallet_id, meter_id |
| region | region_id | None |
| tariff_band | tariff_band_id | None |
| staff_profile | staff_id | user_id, region_id |
| payment | payment_id | wallet_id |
| fault_alert | alert_id | meter_id |
| work_order | work_order_id | alert_id, assigned_staff_id |

## Entity details

### user_account

**Purpose:** One login for every person who uses the system

- **Attributes:** user_id, username, password_hash, role, created_at
- **Primary key:** user_id
- **Foreign keys:** None
- **Relationships:** customer (one to one, customers only); staff_profile (one to one, staff only)
- **Constraints:** username NOT NULL UNIQUE; password_hash NOT NULL (hash only, never the password); role NOT NULL CHECK (customer, technician, billing_officer, regional_manager, sys_admin); created_at NOT NULL

### customer

**Purpose:** A person who buys electricity

- **Attributes:** customer_id, user_id, first_name, last_name, email, phone_number
- **Primary key:** customer_id
- **Foreign keys:** user_id
- **Relationships:** user_account (one to one); premises (one customer to many premises); wallet (one to one)
- **Constraints:** user_id NOT NULL UNIQUE; email NOT NULL UNIQUE; first_name, last_name, phone_number NOT NULL

### premises

**Purpose:** A property where electricity is supplied

- **Attributes:** premises_id, customer_id, address, region_id, tariff_band_id
- **Primary key:** premises_id
- **Foreign keys:** customer_id, region_id, tariff_band_id
- **Relationships:** customer (many to one); region (many to one); tariff_band (many to one); meter (one premises to many meters over time)
- **Constraints:** address, customer_id, region_id, tariff_band_id all NOT NULL

### meter

**Purpose:** Smart meter installed at a premises

- **Attributes:** meter_id, meter_number, premises_id, installation_date, removal_date, status, unit_balance_kwh
- **Primary key:** meter_id
- **Foreign keys:** premises_id
- **Relationships:** premises (many to one); reading (one meter to many readings); token_purchase (one meter to many token purchases); fault_alert (one meter to many alerts)
- **Constraints:** meter_number NOT NULL UNIQUE; status NOT NULL CHECK (active, replaced, faulty); unit_balance_kwh NOT NULL DEFAULT 0 CHECK (>= 0); removal_date NULL until replaced, CHECK (removal_date IS NULL OR removal_date >= installation_date)

### reading

**Purpose:** One 15-minute measurement from a meter

- **Attributes:** reading_id, meter_id, kwh_consumed, voltage, current_amps, recorded_at
- **Primary key:** reading_id
- **Foreign keys:** meter_id
- **Relationships:** meter (many to one)
- **Constraints:** meter_id NOT NULL; UNIQUE (meter_id, recorded_at); kwh_consumed CHECK (>= 0); voltage CHECK (>= 0); current_amps CHECK (>= 0); recorded_at NOT NULL

### wallet

**Purpose:** Prepaid money held for a customer

- **Attributes:** wallet_id, customer_id, balance, last_updated
- **Primary key:** wallet_id
- **Foreign keys:** customer_id
- **Relationships:** customer (one to one); payment (one wallet to many payments); token_purchase (one wallet to many token purchases)
- **Constraints:** customer_id NOT NULL UNIQUE; balance NOT NULL DEFAULT 0 CHECK (>= 0)

### token_purchase

**Purpose:** Wallet money converted into kWh units for one meter

- **Attributes:** purchase_id, wallet_id, meter_id, kwh_units, rate_per_kwh, amount_debited, token_code, purchased_at
- **Primary key:** purchase_id
- **Foreign keys:** wallet_id, meter_id
- **Relationships:** wallet (many to one); meter (many to one)
- **Constraints:** token_code NOT NULL UNIQUE; kwh_units CHECK (> 0); rate_per_kwh CHECK (> 0); amount_debited CHECK (> 0); CHECK (amount_debited = ROUND(kwh_units * rate_per_kwh, 2))

### region

**Purpose:** Lagos, Kano and Ogun offices. Replaces the state text on premises.

- **Attributes:** region_id, region_name
- **Primary key:** region_id
- **Foreign keys:** None
- **Relationships:** premises (one region to many premises); staff_profile (one region to many staff)
- **Constraints:** region_name NOT NULL UNIQUE CHECK (Lagos, Kano, Ogun)

### tariff_band

**Purpose:** Price per kWh. A rate change is a new row with a new effective date.

- **Attributes:** tariff_band_id, band_name, rate_per_kwh, effective_from
- **Primary key:** tariff_band_id
- **Foreign keys:** None
- **Relationships:** premises (one tariff band to many premises)
- **Constraints:** band_name NOT NULL UNIQUE; rate_per_kwh NOT NULL CHECK (> 0); effective_from NOT NULL

### staff_profile

**Purpose:** Technicians, billing officers, regional managers, administrators.

- **Attributes:** staff_id, user_id, region_id, first_name, last_name, job_title
- **Primary key:** staff_id
- **Foreign keys:** user_id, region_id
- **Relationships:** user_account (one to one); region (many staff to one region); work_order (one technician to many work orders)
- **Constraints:** user_id NOT NULL UNIQUE; region_id NOT NULL; first_name, last_name, job_title NOT NULL

### payment

**Purpose:** Money received into a wallet.

- **Attributes:** payment_id, wallet_id, reference_code, amount, payment_method, status, paid_at
- **Primary key:** payment_id
- **Foreign keys:** wallet_id
- **Relationships:** wallet (many payments to one wallet)
- **Constraints:** reference_code NOT NULL UNIQUE; amount CHECK (> 0); payment_method NOT NULL CHECK (card, bank_transfer, ussd); status NOT NULL CHECK (pending, successful, failed)

### fault_alert

**Purpose:** Outage, abnormal consumption or tampering. Belongs to a meter.

- **Attributes:** alert_id, meter_id, alert_type, detected_at, status
- **Primary key:** alert_id
- **Foreign keys:** meter_id
- **Relationships:** meter (many alerts to one meter); work_order (one alert to many work orders, for reassignment)
- **Constraints:** meter_id NOT NULL; detected_at NOT NULL; alert_type NOT NULL CHECK (outage, abnormal_consumption, tampering); status NOT NULL CHECK (open, investigating, resolved)

### work_order

**Purpose:** A technician sent to deal with an alert.

- **Attributes:** work_order_id, alert_id, assigned_staff_id, status, created_at, completed_at
- **Primary key:** work_order_id
- **Foreign keys:** alert_id, assigned_staff_id
- **Relationships:** fault_alert (many work orders to one alert); staff_profile (many work orders to one technician)
- **Constraints:** alert_id, assigned_staff_id NOT NULL; status NOT NULL CHECK (pending, in_progress, completed, cancelled); completed_at NULL until done, CHECK (completed_at IS NULL OR completed_at >= created_at); assigned staff must have role technician (enforce in app or trigger)
