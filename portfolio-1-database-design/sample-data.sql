-- =====================================================================
-- AOWLYF Dynamics Energy Services : sample data for Portfolio 1
-- Student ID: 301922731
-- All people, hashes, meter numbers and token codes are invented.
-- Run this once, straight after schema.sql on a freshly created schema,
-- because the foreign keys below rely on IDs 1, 2, 3 ... in order.
-- =====================================================================

INSERT INTO region (region_name) VALUES ('Lagos'), ('Kano'), ('Ogun');

INSERT INTO tariff_band (band_name, rate_per_kwh, effective_from) VALUES
    ('Residential', 68.7400,  '2026-01-01'),
    ('Commercial',  120.0000, '2026-01-01'),
    ('Lifeline',    50.0000,  '2026-01-01');

-- Users 1-5 are customers, users 6-10 are staff. Hashes are placeholders.
INSERT INTO user_account (username, password_hash, role) VALUES
    ('adewale.ogunleye', 'sample_hash_not_a_real_password_01', 'customer'),
    ('aisha.bello',      'sample_hash_not_a_real_password_02', 'customer'),
    ('chinedu.okafor',   'sample_hash_not_a_real_password_03', 'customer'),
    ('funke.adeyemi',    'sample_hash_not_a_real_password_04', 'customer'),
    ('musa.ibrahim',     'sample_hash_not_a_real_password_05', 'customer'),
    ('tech.sani',        'sample_hash_not_a_real_password_06', 'technician'),
    ('tech.bashir',      'sample_hash_not_a_real_password_07', 'technician'),
    ('billing.ngozi',    'sample_hash_not_a_real_password_08', 'billing_officer'),
    ('manager.tunde',    'sample_hash_not_a_real_password_09', 'regional_manager'),
    ('admin.system',     'sample_hash_not_a_real_password_10', 'sys_admin');

INSERT INTO customer (user_id, first_name, last_name, email, phone_number) VALUES
    (1, 'Adewale', 'Ogunleye', 'adewale.ogunleye@example.com', '08010000001'),
    (2, 'Aisha',   'Bello',    'aisha.bello@example.com',      '08010000002'),
    (3, 'Chinedu', 'Okafor',   'chinedu.okafor@example.com',   '08010000003'),
    (4, 'Funke',   'Adeyemi',  'funke.adeyemi@example.com',    '08010000004'),
    (5, 'Musa',    'Ibrahim',  'musa.ibrahim@example.com',     '08010000005');

INSERT INTO staff_profile (user_id, region_id, first_name, last_name, job_title) VALUES
    (6,  2, 'Sani',   'Abdullahi', 'Field Technician'),
    (7,  2, 'Bashir', 'Garba',     'Field Technician'),
    (8,  1, 'Ngozi',  'Eze',       'Billing Officer'),
    (9,  1, 'Tunde',  'Bakare',    'Regional Manager'),
    (10, 1, 'System', 'Admin',     'System Administrator');

INSERT INTO premises (customer_id, address, region_id, tariff_band_id) VALUES
    (1, '12 Admiralty Way, Lekki, Lagos',        1, 1),
    (2, '5 Zaria Road, Nassarawa, Kano',          2, 1),
    (3, '8 Oke-Mosan Street, Abeokuta, Ogun',     3, 1),
    (4, '22 Allen Avenue, Ikeja, Lagos (shop)',   1, 2),
    (5, '3 Bompai Road, Kano',                    2, 1),
    (1, '40 Ajah Estate Road, Ajah, Lagos',       1, 1);

INSERT INTO meter (meter_number, premises_id, installation_date, status, unit_balance_kwh) VALUES
    ('AOW-LG-0001', 1, '2026-02-10', 'active', 120.5000),
    ('AOW-KN-0002', 2, '2026-02-15', 'active',  80.0000),
    ('AOW-OG-0003', 3, '2026-03-01', 'active',  45.2500),
    ('AOW-LG-0004', 4, '2026-03-05', 'active', 300.0000),
    ('AOW-KN-0005', 5, '2026-03-20', 'faulty',   0.0000),
    ('AOW-LG-0006', 6, '2026-04-02', 'active',  10.0000);

-- 15-minute readings. Meter 5 shows zero voltage (an outage).
INSERT INTO reading (meter_id, kwh_consumed, voltage, current_amps, recorded_at) VALUES
    (1, 0.2500, 229.80, 1.10, '2026-11-10 08:00:00+01'),
    (1, 0.2700, 230.10, 1.17, '2026-11-10 08:15:00+01'),
    (1, 0.3100, 228.90, 1.35, '2026-11-10 08:30:00+01'),
    (1, 0.2900, 229.50, 1.26, '2026-11-10 08:45:00+01'),
    (2, 0.1800, 231.20, 0.78, '2026-11-10 08:00:00+01'),
    (2, 0.2000, 230.70, 0.87, '2026-11-10 08:15:00+01'),
    (2, 0.1900, 230.90, 0.83, '2026-11-10 08:30:00+01'),
    (4, 1.2000, 228.00, 5.26, '2026-11-10 08:00:00+01'),
    (4, 3.9000, 226.50, 17.20, '2026-11-10 08:15:00+01'),
    (5, 0.0000, 0.00,   0.00, '2026-11-10 08:00:00+01'),
    (5, 0.0000, 0.00,   0.00, '2026-11-10 08:15:00+01');

INSERT INTO wallet (customer_id, balance) VALUES
    (1, 19689.00),
    (2,  1563.00),
    (3,  8000.00),
    (4, 26000.00),
    (5,     0.00);

INSERT INTO payment (wallet_id, reference_code, amount, payment_method, status) VALUES
    (1, 'PAY-20261101-0001', 20000.00, 'card',          'successful'),
    (1, 'PAY-20261105-0002', 10000.00, 'ussd',          'successful'),
    (2, 'PAY-20261102-0003',  5000.00, 'bank_transfer', 'successful'),
    (3, 'PAY-20261103-0004',  8000.00, 'card',          'failed'),
    (3, 'PAY-20261103-0005',  8000.00, 'card',          'successful'),
    (4, 'PAY-20261104-0006', 50000.00, 'bank_transfer', 'successful'),
    (5, 'PAY-20261109-0007',  3000.00, 'ussd',          'pending');

-- amount_debited must equal ROUND(kwh_units * rate_per_kwh, 2)
INSERT INTO token_purchase (wallet_id, meter_id, kwh_units, rate_per_kwh, amount_debited, token_code) VALUES
    (1, 1, 100.0000,  68.7400,  6874.00, '1111-2222-3333-4444-5551'),
    (1, 6,  50.0000,  68.7400,  3437.00, '1111-2222-3333-4444-5552'),
    (2, 2,  50.0000,  68.7400,  3437.00, '1111-2222-3333-4444-5553'),
    (4, 4, 200.0000, 120.0000, 24000.00, '1111-2222-3333-4444-5554');

INSERT INTO fault_alert (meter_id, alert_type, status) VALUES
    (5, 'outage',               'investigating'),
    (4, 'abnormal_consumption', 'open'),
    (2, 'tampering',            'resolved');

-- Alert 1 was first given to technician 2, then cancelled and reassigned.
INSERT INTO work_order (alert_id, assigned_staff_id, status, created_at, completed_at) VALUES
    (1, 2, 'cancelled',   '2026-11-10 08:30:00+01', NULL),
    (1, 1, 'in_progress', '2026-11-10 09:00:00+01', NULL),
    (3, 1, 'completed',   '2026-11-08 10:00:00+01', '2026-11-08 14:30:00+01');