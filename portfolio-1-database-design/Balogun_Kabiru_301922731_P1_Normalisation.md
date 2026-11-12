---
noteId: "979f3390dea111f1af14e3682d930608"
tags: []

---

# Normalisation

AOWLYF Dynamics Energy Services. Student ID: 301922731.

This document shows how a flat table can be broken down, one step at a time, into the design in `Balogun_Kabiru_301922731_P1_Schema.sql`. The example throughout is meter AOW-LG-0001 and its customer, Adewale Ogunleye.

## Starting point: one flat record

Suppose everything about a meter is kept in a single table:

| meter_number | customer_name | customer_phone | address | region | tariff_band | rate_per_kwh | readings (kwh, voltage, time) | payments |
|---|---|---|---|---|---|---|---|---|
| AOW-LG-0001 | Adewale Ogunleye | 08010000001 | 12 Admiralty Way | Lagos | Residential | 68.74 | (0.25, 229.8, 08:00), (0.27, 230.1, 08:15) | 20000, 10000 |

This table causes trouble. Adewale's phone number is repeated for every meter he owns, so one change means editing many rows. A new region or tariff band cannot be saved until a meter uses it. Deleting his last meter also deletes his details.

## First normal form (1NF)

1NF says each cell holds a single value. The readings and payments columns break this, because they pack several values into one cell.

With several readings in one cell, I cannot correct one without rewriting all of them, and I cannot ask the database for an average voltage or for readings above 240 V. In 1NF every reading and every payment gets its own row, so each can be updated and queried on its own. A reading is then identified by its meter and the time it was taken: (meter_number, recorded_at).

## Second normal form (2NF)

2NF says every column must depend on the whole key, not just part of it. The key of the reading table is (meter_number, recorded_at). The customer's name, phone, address, region and tariff band depend only on the meter and do not change with the time of the reading. This is called a partial dependency.

If the phone number sits in every reading row, it is repeated thousands of times, since the meter reports every 15 minutes. When Adewale changes his number, every one of those rows has to be found and updated, and missing one leaves the data inconsistent. This is an update anomaly. So those columns moved out, and the phone number is now stored once, in `customer`. A reading points to its `meter`, the meter to its `premises`, and the premises to the `customer`.

## Third normal form (3NF)

3NF says a column must describe the key and nothing else. In `premises`, the rate per kWh depends on the tariff band, not on the premises. The region name is the same kind of case.

The rate belongs to the tariff band. Most premises share one band, so keeping the rate once in `tariff_band` means a rate change is a single update, and two premises on the same band can never end up with different rates. Region names move to `region` in the same way. `premises` keeps only `tariff_band_id` and `region_id`.

## BCNF check

Every table has a primary key. Where a table has a second candidate key, I declared it UNIQUE: meter_id with recorded_at in `reading`, user_id in `customer`, and customer_id in `wallet`. Every determinant is therefore a candidate key, so no hidden dependencies remain.

## Deliberate choices

**rate_per_kwh in token_purchase.** The rate is already in `tariff_band`, but each purchase keeps its own copy as a receipt. Adewale buys 100 kWh at 68.74 and pays 6,874.00. If the rate later becomes 75 and the purchase looked it up live, it would show 7,500.00, which is not what he paid.

**amount_debited in token_purchase.** It could be calculated from the units and the rate, but I store it so each billing record is complete. A CHECK constraint rejects any row where it does not equal ROUND(kwh_units * rate_per_kwh, 2).

**unit_balance_kwh and wallet.balance.** These are running totals kept for quick reads, and CHECK (>= 0) stops them going negative. I tested that a negative wallet balance is rejected (see [Balogun_Kabiru_301922731_P1_ConstraintErrors.png](screenshots/Balogun_Kabiru_301922731_P1_ConstraintErrors.png)). Updating them together with a payment or token purchase in one transaction belongs to Portfolio 3 and is not done here.

**Technician-only work orders.** The rule that a work order can only go to a staff member whose role is technician is not enforced by `Balogun_Kabiru_301922731_P1_Schema.sql`. It would need application code or a trigger, and neither is built yet.

## Result

The flat table became the 13 tables in `Balogun_Kabiru_301922731_P1_Schema.sql`. The ER diagram is in `Balogun_Kabiru_301922731_P1_ERDiagram.md`.