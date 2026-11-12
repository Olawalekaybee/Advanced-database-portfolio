# Portfolio 4: NoSQL and advanced data models

This portfolio extends the AOWLYF Dynamics Energy Services case study with two NoSQL stores: MongoDB Atlas (document model) and Neo4j Aura (graph model). PostgreSQL stays the system of record for money and customer data. The NoSQL stores take the work that suits them.

## 1. What stays in PostgreSQL

Customer accounts, wallet balances, payments, token purchases and the structured meter readings stay in PostgreSQL. These records need a fixed structure and reliable transactions. A token purchase changes a wallet, a purchase record and a meter balance together, and Portfolio 3 showed what goes wrong without that guarantee (the lost update). Portfolio 5 classed the wallet and token purchase tables as consistency-first (CP). A NoSQL store that relaxes consistency is the wrong place for them.

## 2. Document model: MongoDB Atlas

### Design

One document holds one meter's readings for one day. The collection is `meter_telemetry` in the database `aowlyf_nosql`.

| Field | Content | Embedded or referenced |
|---|---|---|
| `_id` | meter number and date, for example `AOW-LG-0001_2026-11-10` | |
| `meter_number`, `meter_id` | which meter | |
| `region` | region name, for example Lagos | Embedded (short, and used in regional reports) |
| `customer_id`, `tariff_band_id` | the owner and the tariff | Referenced by ID only |
| `date` | the day | |
| `readings` | array of readings, each with time, kWh, voltage and current | Embedded |
| `reading_count`, `total_kwh` | summary values for the day | Embedded |

I left customer details and tariff information out of the document and kept only their IDs. That avoids repeating the same information in every document, and a change to a customer's details does not mean editing thousands of telemetry documents.

A second collection, `device_events`, stores events from the meters: firmware updates, outages, abnormal consumption and tamper alerts. Each event type carries different fields, and they sit in the same collection with no schema change. A firmware event has `from_version` and `to_version`, while an outage has `voltage` and `consecutive_zero_readings`. A relational table would need many empty columns or a table for each event type.

### Why a document suits this data

A meter sends a reading every 15 minutes, so a full day is up to 96 readings. Stored as 96 rows, a day's data for one meter has to be assembled from many records. As one document, a meter's whole day is stored and retrieved in a single read, with no join. The sample documents hold only the 2 to 4 readings that exist in my Portfolio 1 sample data, but the structure is the same for a full day.

### What I ran

| Query | Result | Evidence |
|---|---|---|
| One meter's day (`meter_number` and `date`) | One document with its embedded readings | `mongo-find-meter-day.png` |
| Total kWh per region (`$match`, `$group`, `$sort`) | Lagos 6.22, Kano 0.57 | `mongo-aggregation-region.png` |
| Readings with voltage below 100 | Only AOW-KN-0005 | `mongo-low-voltage.png` |
| All device events | Four events with different fields | `mongo-device-events.png` |
| Same query before and after a compound index on `meter_number` and `date` | COLLSCAN (4 documents examined) became IXSCAN (1 document examined) | `mongo-explain-before.png`, `mongo-index-created.png`, `mongo-explain.png` |

The regional totals are the same as Query 1 in Portfolio 2 on PostgreSQL (Lagos 6.2200, Kano 0.5700), so the two stores agree. The index result is the same idea as Portfolio 2: an index lets the database go straight to the right document. With four documents the time is zero either way, so what matters is the change in the plan.

## 3. Graph model: Neo4j Aura

### Design

| Node | Properties | Built from |
|---|---|---|
| `Region` | name | `region` |
| `Customer` | customer_id, name | `customer` |
| `Premises` | premises_id, address | `premises` |
| `Meter` | meter_id, meter_number, status | `meter` |
| `Staff` | staff_id, name, job_title | `staff_profile` |
| `FaultAlert` | alert_id, alert_type, status | `fault_alert` |
| `WorkOrder` | work_order_id, status | `work_order` |

| Relationship | Meaning |
|---|---|
| `(Customer)-[:OWNS]->(Premises)` | who owns the property |
| `(Premises)-[:IN_REGION]->(Region)` | where the property is |
| `(Meter)-[:INSTALLED_AT]->(Premises)` | where the meter is installed |
| `(FaultAlert)-[:RAISED_ON]->(Meter)` | which meter had the fault |
| `(WorkOrder)-[:FOR_ALERT]->(FaultAlert)` | which fault the job addresses |
| `(WorkOrder)-[:ASSIGNED_TO]->(Staff)` | who does the job |
| `(Staff)-[:WORKS_IN]->(Region)` | the technician's region |

The graph holds 31 nodes and 32 relationships, built from the same sample data as Portfolio 1.

I first planned to make each reading a node as well. I removed it, because a meter sends 96 readings a day and millions of tiny nodes would swamp the graph for no benefit. Readings stay in MongoDB and PostgreSQL, and the graph keeps only the connections between the entities that matter.

### The question that suits a graph

**For a faulty meter, which other meters are in the same region, and which technicians have worked on faults on them?**

The meter that is faulty is AOW-KN-0005 in Kano. The graph query returns one row: Kano, faulty meter AOW-KN-0005, other meter AOW-KN-0002, technician Sani Abdullahi. Cancelled work orders are ignored, so Bashir Garba does not appear. The result is in `neo4j-design-question.png`.

I first thought of "other meters on the same premises", but in my sample data every premises has exactly one meter, so that query would return nothing. Asking about the same region gives a real answer and one more hop through the graph.

### Graph compared with SQL

The same question in SQL (`06_sql_equivalent.sql`) joins eight table references: meter twice, premises twice, region, fault_alert, work_order and staff_profile. I ran it on PostgreSQL and it returns the same row. The Cypher version is one connected pattern that reads like the question: a fault on a meter, in a region, with other meters in that region, and the staff on their faults.

At this size both work, and I am not claiming the graph is faster here. The graph's advantage grows with questions that follow connections to unknown depth. The shortest path query shows this: from the customer Musa Ibrahim to the technician Sani Abdullahi, Neo4j finds the route (Musa, his premises at 3 Bompai Road, Kano, Sani) in three steps, with no joins written (`neo4j-shortest-path.png`). In SQL, a path of unknown length needs a recursive query.

### Other queries

- Customers affected by an unresolved fault: Funke Adeyemi (AOW-LG-0004, abnormal consumption, open) and Musa Ibrahim (AOW-KN-0005, outage, investigating) (`neo4j-affected-customers.png`).
- Work orders per technician: Sani Abdullahi 2, Bashir Garba 1 (`neo4j-workload.png`).

## 4. Choosing the right store

| Data | Store | Reason |
|---|---|---|
| Customers, wallets, payments, token purchases | PostgreSQL | Fixed structure and reliable transactions |
| Structured meter readings | PostgreSQL | Defined columns, used in reports |
| Daily meter telemetry and device events | MongoDB | Flexible fields, one read for a meter's day |
| Customers, meters, faults, technicians and how they connect | Neo4j | Relationship questions and path finding |

## 5. Limits

- The data is a small sample copied from Portfolio 1. Nothing here was tested at real scale.
- The three stores are not kept in sync automatically. I loaded the MongoDB and Neo4j data from the PostgreSQL sample by hand. A real system would need a process that copies changes between them, and I have not built one.
- Both cloud databases are on free tiers. An Aura Free instance is deleted after 30 days of inactivity, so the scripts in this folder rebuild the graph in a minute.
- Connection details and the Aura credentials file are not in the repository.