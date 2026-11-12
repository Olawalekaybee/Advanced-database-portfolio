---
noteId: "979f3393dea111f1af14e3682d930608"
tags: []

---

# Portfolio 1: Database Design and Modelling

Student: Balogun Kabiru | Student ID: 301922731 | Case study: AOWLYF Dynamics Energy Services

In this portfolio I model the AOWLYF Dynamics Energy Services database in PostgreSQL 18. It has 13 tables covering users, customers, premises, meters, readings, prepaid wallets, payments, token purchases, fault alerts and technician work orders.

## Users

Customers buy electricity and manage their prepaid wallet. Field technicians handle faults through work orders. Billing officers, regional managers and system administrators use the same login system with different roles.

## Main operations

Register a customer and a premises; install a meter; record a reading every 15 minutes; top up a wallet; buy a token that loads kWh onto a meter; raise a fault alert; assign a technician through a work order; produce regional consumption reports.

## Business rules

1. Every person who uses the system has one login with a unique username and one role.
2. A customer has exactly one wallet. A wallet balance and a meter's unit balance can never be negative.
3. A meter number is unique, and a meter has at most one reading for any given time.
4. Each premises belongs to one customer, one region (Lagos, Kano or Ogun) and one tariff band.
5. A token purchase keeps its own rate, and the amount debited must equal the units multiplied by that rate, rounded to two decimal places.
6. A removal date cannot be earlier than the installation date, and a work order cannot be completed before it was created.
7. A work order should only go to a technician. The schema does not enforce this rule yet (see limits below).

## Scope

One electricity distribution company with three regions and fictional records. Billing disputes, meter hardware protocols, tariff history reports and real payment gateways are outside this exercise.

## Files

| File | What it contains |
|---|---|
| [Balogun_Kabiru_301922731_P1_CaseStudy.md](Balogun_Kabiru_301922731_P1_CaseStudy.md) | The case study statement |
| [Balogun_Kabiru_301922731_P1_Design.md](Balogun_Kabiru_301922731_P1_Design.md) | Every entity with its attributes, keys, relationships and constraints |
| [Balogun_Kabiru_301922731_P1_ERDiagram.md](Balogun_Kabiru_301922731_P1_ERDiagram.md) | The ER diagram (Mermaid) |
| [Balogun_Kabiru_301922731_P1_Schema.sql](Balogun_Kabiru_301922731_P1_Schema.sql) | Creates all 13 tables with primary keys, foreign keys, UNIQUE, NOT NULL and CHECK rules |
| [Balogun_Kabiru_301922731_P1_SampleData.sql](Balogun_Kabiru_301922731_P1_SampleData.sql) | Invented sample rows for every table |
| [Balogun_Kabiru_301922731_P1_Normalisation.md](Balogun_Kabiru_301922731_P1_Normalisation.md) | Normalisation from a flat record to 3NF and BCNF |
| [screenshots/](screenshots/) | ER diagram on GitHub, tables in psql, and constraint errors |

## Key design decisions

- A wallet holds money. Buying a token debits the wallet and adds kWh to the meter's balance.
- Customers and staff share one `user_account` table. Each has a separate profile table.
- Payments (money in) and token purchases (units issued) are separate tables.
- `token_purchase` keeps its own rate, so a later tariff change does not alter old purchases.

## How to run

1. Create a database: `CREATE DATABASE aowlyf_energy;` and connect to it.
2. Run `Balogun_Kabiru_301922731_P1_Schema.sql`, then `Balogun_Kabiru_301922731_P1_SampleData.sql`.
3. Check with `\dt`. It should list 13 tables.

## Limits of this portfolio

- The rule that a work order goes only to a technician is not enforced in the schema.
- Updating wallet and meter balances in a single transaction is covered in Portfolio 3.

## Evidence

- [Balogun_Kabiru_301922731_P1_ERDiagram.png](screenshots/Balogun_Kabiru_301922731_P1_ERDiagram.png): the ER diagram rendering on GitHub
- [Balogun_Kabiru_301922731_P1_TableList.png](screenshots/Balogun_Kabiru_301922731_P1_TableList.png): all 13 tables created
- [Balogun_Kabiru_301922731_P1_ConstraintErrors.png](screenshots/Balogun_Kabiru_301922731_P1_ConstraintErrors.png): an invalid region and a negative balance both rejected
