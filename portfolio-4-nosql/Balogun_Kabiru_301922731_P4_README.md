# Portfolio 4: NoSQL and Advanced Data Models

Student: Balogun Kabiru | Student ID: 301922731 | Case study: AOWLYF Dynamics Energy Services

This portfolio adds two NoSQL stores to the same AOWLYF case study. MongoDB Atlas (document model) holds daily meter telemetry and device events. Neo4j Aura (graph model) holds how customers, premises, meters, faults and technicians connect. PostgreSQL stays the system of record for money and customer data. I explain the design and my reasons in `Balogun_Kabiru_301922731_P4_Design.md`.

## Files

| File | What it contains |
|---|---|
| [Balogun_Kabiru_301922731_P4_Design.md](Balogun_Kabiru_301922731_P4_Design.md) | Document and graph models, why they suit the data, graph compared with SQL, limits |
| [Balogun_Kabiru_301922731_P4_MeterTelemetry.json](Balogun_Kabiru_301922731_P4_MeterTelemetry.json) | Four sample documents, one per meter per day, with embedded readings |
| [Balogun_Kabiru_301922731_P4_DeviceEvents.json](Balogun_Kabiru_301922731_P4_DeviceEvents.json) | Four device events with different fields |
| [Balogun_Kabiru_301922731_P4_MongoDB.js](Balogun_Kabiru_301922731_P4_MongoDB.js) | MongoDB queries, aggregation and index with explain plan |
| [Balogun_Kabiru_301922731_P4_Neo4jLoad.cypher](Balogun_Kabiru_301922731_P4_Neo4jLoad.cypher) | Builds the graph (31 nodes, 32 relationships) |
| [Balogun_Kabiru_301922731_P4_Neo4jQueries.cypher](Balogun_Kabiru_301922731_P4_Neo4jQueries.cypher) | Graph queries, including the design question and a shortest path |
| [Balogun_Kabiru_301922731_P4_SqlEquivalent.sql](Balogun_Kabiru_301922731_P4_SqlEquivalent.sql) | The design question written in SQL, for comparison |
| [screenshots/](screenshots/) | Results from both databases |

## What was tested

1. **MongoDB.** I read one meter's day as a single document, totalled kWh per region (Lagos 6.22, Kano 0.57, the same as Portfolio 2), searched for low voltage (it finds AOW-KN-0005), and stored device events with different fields in one collection.
2. **MongoDB index.** I ran the same query before and after a compound index on `meter_number` and `date`. A collection scan of 4 documents became an index scan of 1.
3. **Neo4j.** For a faulty meter, I found the other meters in its region and the technicians who worked on them (Kano, AOW-KN-0005, AOW-KN-0002, Sani Abdullahi). I also listed the affected customers, counted work orders per technician, and found the shortest path from a customer to a technician.

## How to run

1. MongoDB Atlas: create a free cluster, create the database `aowlyf_nosql` with the collections `meter_telemetry` and `device_events`, and insert the two JSON files. Run the queries in `Balogun_Kabiru_301922731_P4_MongoDB.js` in the Data Explorer.
2. Neo4j Aura: create a free instance, open Query, run `Balogun_Kabiru_301922731_P4_Neo4jLoad.cypher` once as a single statement, then run the queries in `Balogun_Kabiru_301922731_P4_Neo4jQueries.cypher` one at a time.
3. Optional: run `Balogun_Kabiru_301922731_P4_SqlEquivalent.sql` in `aowlyf_energy` to compare with the graph result.

Connection strings, passwords and the Aura credentials file are not stored in this repository.

## Limits

- The data is a small sample from Portfolio 1, and the three databases are not kept in sync automatically.
- Both cloud databases are on free tiers. An Aura Free instance is deleted after 30 days of inactivity, so the Cypher scripts are how the graph is rebuilt.
- At this size SQL and the graph give the same answer. The graph's advantage appears with deeper questions, and I did not test at real scale.

## Evidence

- MongoDB: [Balogun_Kabiru_301922731_P4_MongoFindMeterDay.png](screenshots/Balogun_Kabiru_301922731_P4_MongoFindMeterDay.png), [Balogun_Kabiru_301922731_P4_MongoAggregationRegion.png](screenshots/Balogun_Kabiru_301922731_P4_MongoAggregationRegion.png), [Balogun_Kabiru_301922731_P4_MongoLowVoltage.png](screenshots/Balogun_Kabiru_301922731_P4_MongoLowVoltage.png), [Balogun_Kabiru_301922731_P4_MongoDeviceEvents.png](screenshots/Balogun_Kabiru_301922731_P4_MongoDeviceEvents.png), [Balogun_Kabiru_301922731_P4_MongoExplainBefore.png](screenshots/Balogun_Kabiru_301922731_P4_MongoExplainBefore.png), [Balogun_Kabiru_301922731_P4_MongoIndexCreated.png](screenshots/Balogun_Kabiru_301922731_P4_MongoIndexCreated.png), [Balogun_Kabiru_301922731_P4_MongoExplain.png](screenshots/Balogun_Kabiru_301922731_P4_MongoExplain.png)
- Neo4j: [Balogun_Kabiru_301922731_P4_Neo4jLoadResult.png](screenshots/Balogun_Kabiru_301922731_P4_Neo4jLoadResult.png), [Balogun_Kabiru_301922731_P4_Neo4jGraphOverview.png](screenshots/Balogun_Kabiru_301922731_P4_Neo4jGraphOverview.png), [Balogun_Kabiru_301922731_P4_Neo4jDesignQuestion.png](screenshots/Balogun_Kabiru_301922731_P4_Neo4jDesignQuestion.png), [Balogun_Kabiru_301922731_P4_Neo4jAffectedCustomers.png](screenshots/Balogun_Kabiru_301922731_P4_Neo4jAffectedCustomers.png), [Balogun_Kabiru_301922731_P4_Neo4jWorkload.png](screenshots/Balogun_Kabiru_301922731_P4_Neo4jWorkload.png), [Balogun_Kabiru_301922731_P4_Neo4jShortestPath.png](screenshots/Balogun_Kabiru_301922731_P4_Neo4jShortestPath.png)
