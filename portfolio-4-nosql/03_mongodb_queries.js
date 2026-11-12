// =====================================================================
// AOWLYF Dynamics Energy Services : Portfolio 4, MongoDB (document model)
// Database: aowlyf_nosql   Collections: meter_telemetry, device_events
// Student ID: 301922731
//
// Load 01_meter_telemetry.json into meter_telemetry and
// 02_device_events.json into device_events first (Atlas > Browse
// Collections > Insert Document > paste the JSON array), then run
// these queries in mongosh or paste the filters and pipelines into the
// Atlas Data Explorer. No connection string or password belongs here.
// =====================================================================

use("aowlyf_nosql");

// 1. One meter's whole day in a single read (one document, no joins).
db.meter_telemetry.find({ meter_number: "AOW-LG-0001", date: "2026-11-10" });

// 2. Total kWh per region for the day. Same question as Query 1 in
//    Portfolio 2, so the two answers can be compared
//    (Lagos 6.2200, Kano 0.5700).
db.meter_telemetry.aggregate([
  { $match: { date: "2026-11-10" } },
  { $group: { _id: "$region", total_kwh: { $sum: "$total_kwh" } } },
  { $sort: { total_kwh: -1 } }
]);

// 3. Meters that reported a very low voltage (a possible outage).
//    Matches meter AOW-KN-0005, which reported 0 V.
db.meter_telemetry.find(
  { "readings.voltage": { $lt: 100 } },
  { meter_number: 1, region: 1, date: 1 }
);

// 4. Device events have different fields depending on the event type.
//    No schema change was needed to store them side by side.
db.device_events.find({}, { _id: 0, meter_number: 1, event_type: 1 });
db.device_events.find({ event_type: "firmware_update" });

// 5. Index and plan, the same idea as Portfolio 2.
db.meter_telemetry.createIndex({ meter_number: 1, date: 1 });
db.meter_telemetry
  .find({ meter_number: "AOW-LG-0001", date: "2026-11-10" })
  .explain("executionStats");