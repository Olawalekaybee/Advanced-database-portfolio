// =====================================================================
// AOWLYF Dynamics Energy Services : Portfolio 4, Neo4j (graph model)
// Builds the network from the same sample data as Portfolio 1.
// Student ID: 301922731
// Run this once, as a single statement, in the Neo4j Aura Query tool.
// To start again, run: MATCH (n) DETACH DELETE n;
// Readings are not stored as nodes: they stay in MongoDB and PostgreSQL.
// =====================================================================

CREATE
  (lagos:Region {name: 'Lagos'}),
  (kano:Region  {name: 'Kano'}),
  (ogun:Region  {name: 'Ogun'}),

  (c1:Customer {customer_id: 1, name: 'Adewale Ogunleye'}),
  (c2:Customer {customer_id: 2, name: 'Aisha Bello'}),
  (c3:Customer {customer_id: 3, name: 'Chinedu Okafor'}),
  (c4:Customer {customer_id: 4, name: 'Funke Adeyemi'}),
  (c5:Customer {customer_id: 5, name: 'Musa Ibrahim'}),

  (p1:Premises {premises_id: 1, address: '12 Admiralty Way, Lekki'}),
  (p2:Premises {premises_id: 2, address: '5 Zaria Road, Nassarawa'}),
  (p3:Premises {premises_id: 3, address: '8 Oke-Mosan Street, Abeokuta'}),
  (p4:Premises {premises_id: 4, address: '22 Allen Avenue, Ikeja (shop)'}),
  (p5:Premises {premises_id: 5, address: '3 Bompai Road'}),
  (p6:Premises {premises_id: 6, address: '40 Ajah Estate Road, Ajah'}),

  (m1:Meter {meter_id: 1, meter_number: 'AOW-LG-0001', status: 'active'}),
  (m2:Meter {meter_id: 2, meter_number: 'AOW-KN-0002', status: 'active'}),
  (m3:Meter {meter_id: 3, meter_number: 'AOW-OG-0003', status: 'active'}),
  (m4:Meter {meter_id: 4, meter_number: 'AOW-LG-0004', status: 'active'}),
  (m5:Meter {meter_id: 5, meter_number: 'AOW-KN-0005', status: 'faulty'}),
  (m6:Meter {meter_id: 6, meter_number: 'AOW-LG-0006', status: 'active'}),

  (s1:Staff {staff_id: 1, name: 'Sani Abdullahi', job_title: 'Field Technician'}),
  (s2:Staff {staff_id: 2, name: 'Bashir Garba',   job_title: 'Field Technician'}),
  (s3:Staff {staff_id: 3, name: 'Ngozi Eze',      job_title: 'Billing Officer'}),
  (s4:Staff {staff_id: 4, name: 'Tunde Bakare',   job_title: 'Regional Manager'}),
  (s5:Staff {staff_id: 5, name: 'System Admin',   job_title: 'System Administrator'}),

  (a1:FaultAlert {alert_id: 1, alert_type: 'outage',               status: 'investigating'}),
  (a2:FaultAlert {alert_id: 2, alert_type: 'abnormal_consumption', status: 'open'}),
  (a3:FaultAlert {alert_id: 3, alert_type: 'tampering',            status: 'resolved'}),

  (w1:WorkOrder {work_order_id: 1, status: 'cancelled'}),
  (w2:WorkOrder {work_order_id: 2, status: 'in_progress'}),
  (w3:WorkOrder {work_order_id: 3, status: 'completed'}),

  (c1)-[:OWNS]->(p1), (c2)-[:OWNS]->(p2), (c3)-[:OWNS]->(p3),
  (c4)-[:OWNS]->(p4), (c5)-[:OWNS]->(p5), (c1)-[:OWNS]->(p6),

  (p1)-[:IN_REGION]->(lagos), (p2)-[:IN_REGION]->(kano),
  (p3)-[:IN_REGION]->(ogun),  (p4)-[:IN_REGION]->(lagos),
  (p5)-[:IN_REGION]->(kano),  (p6)-[:IN_REGION]->(lagos),

  (m1)-[:INSTALLED_AT]->(p1), (m2)-[:INSTALLED_AT]->(p2),
  (m3)-[:INSTALLED_AT]->(p3), (m4)-[:INSTALLED_AT]->(p4),
  (m5)-[:INSTALLED_AT]->(p5), (m6)-[:INSTALLED_AT]->(p6),

  (s1)-[:WORKS_IN]->(kano),  (s2)-[:WORKS_IN]->(kano),
  (s3)-[:WORKS_IN]->(lagos), (s4)-[:WORKS_IN]->(lagos),
  (s5)-[:WORKS_IN]->(lagos),

  (a1)-[:RAISED_ON]->(m5), (a2)-[:RAISED_ON]->(m4), (a3)-[:RAISED_ON]->(m2),

  (w1)-[:FOR_ALERT]->(a1), (w2)-[:FOR_ALERT]->(a1), (w3)-[:FOR_ALERT]->(a3),

  (w1)-[:ASSIGNED_TO]->(s2), (w2)-[:ASSIGNED_TO]->(s1), (w3)-[:ASSIGNED_TO]->(s1);
