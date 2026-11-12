// =====================================================================
// AOWLYF Dynamics Energy Services : Portfolio 4, Neo4j queries
// Run each query on its own in the Neo4j Aura Query tool.
// Student ID: 301922731
// =====================================================================

// 1. The whole graph, for a picture of the model.
MATCH (n) RETURN n;

// 2. The design question: for a faulty meter, which other meters are in
//    the same region, and which technicians have worked on faults on
//    them? (Cancelled work orders are ignored.)
//    Expected: Kano, AOW-KN-0005, AOW-KN-0002, Sani Abdullahi.
MATCH (:FaultAlert)-[:RAISED_ON]->(m:Meter {status: 'faulty'})
      -[:INSTALLED_AT]->(:Premises)-[:IN_REGION]->(r:Region)
      <-[:IN_REGION]-(:Premises)<-[:INSTALLED_AT]-(other:Meter)
WHERE other <> m
OPTIONAL MATCH (other)<-[:RAISED_ON]-(:FaultAlert)<-[:FOR_ALERT]-(w:WorkOrder)
               -[:ASSIGNED_TO]->(s:Staff)
WHERE w.status <> 'cancelled'
RETURN r.name AS region,
       m.meter_number AS faulty_meter,
       other.meter_number AS other_meter,
       collect(DISTINCT s.name) AS technicians;

// 3. Customers affected by an unresolved fault.
MATCH (c:Customer)-[:OWNS]->(:Premises)<-[:INSTALLED_AT]-(m:Meter)
      <-[:RAISED_ON]-(f:FaultAlert)
WHERE f.status <> 'resolved'
RETURN c.name AS customer, m.meter_number AS meter,
       f.alert_type AS fault, f.status AS status;

// 4. Work order count per technician.
MATCH (s:Staff)<-[:ASSIGNED_TO]-(w:WorkOrder)
RETURN s.name AS technician, count(w) AS work_orders
ORDER BY work_orders DESC;

// 5. Shortest connection between a customer and a technician.
MATCH p = shortestPath(
  (c:Customer {name: 'Musa Ibrahim'})-[*..6]-(s:Staff {name: 'Sani Abdullahi'}))
RETURN p;
