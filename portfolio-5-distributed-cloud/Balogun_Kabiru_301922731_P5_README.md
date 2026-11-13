# Portfolio 5: Distributed and Cloud Database Exercise

Student: Balogun Kabiru | Student ID: 301922731 | Case study: AOWLYF Dynamics Energy Services

In this portfolio I describe how the AOWLYF database would be spread across servers for Lagos, Kano and Ogun, and I demonstrate sharding by region in PostgreSQL.

## Files

| File | What it contains |
|---|---|
| [Balogun_Kabiru_301922731_P5_Design.md](Balogun_Kabiru_301922731_P5_Design.md) | Sharding, replication, CAP choice per table and a failure scenario |
| [Balogun_Kabiru_301922731_P5_Partitioning.sql](Balogun_Kabiru_301922731_P5_Partitioning.sql) | A demonstration of partitioning readings by `region_id` |
| [screenshots/](screenshots/) | Output of the demonstration |

## What was tested

1. I copied the readings into a table partitioned by region and checked that each row landed in its region's partition.
2. I ran a query for Kano readings and confirmed from the plan that only the Kano partition is scanned.
3. I ran a query without the region and confirmed that all three partitions are scanned.

## How to run

Load `Balogun_Kabiru_301922731_P1_Schema.sql` and `Balogun_Kabiru_301922731_P1_SampleData.sql` from `portfolio-1-database-design` (one folder up), connect with `psql -U postgres -d aowlyf_energy`, then run `Balogun_Kabiru_301922731_P5_Partitioning.sql`.

## Limits

- The demonstration runs on one server, so the partitions are not on separate machines.
- Replication, failover and cloud deployment are design discussion only and were not built.

## Evidence

- [Balogun_Kabiru_301922731_P5_PartitionRows.png](screenshots/Balogun_Kabiru_301922731_P5_PartitionRows.png)
- [Balogun_Kabiru_301922731_P5_ExplainKano.png](screenshots/Balogun_Kabiru_301922731_P5_ExplainKano.png)
- [Balogun_Kabiru_301922731_P5_ExplainAll.png](screenshots/Balogun_Kabiru_301922731_P5_ExplainAll.png)
