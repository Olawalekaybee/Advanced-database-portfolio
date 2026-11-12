---
noteId: "6ecfb0a0de9e11f1af14e3682d930608"
tags: []

---

# Distributed Design for AOWLYF Dynamics Energy Services

Student ID: 301922731

This document describes how the AOWLYF database would be spread across servers for its three regions: Lagos, Kano and Ogun. It covers sharding, replication, the consistency choice for each important table, and what happens when a server fails. A small demonstration of sharding is included.

## 1. Sharding by region

The shard key is `region_id`. Customers, premises and meter readings can be stored on the server assigned to their region, so regional data is quicker to reach. A Kano customer's wallet balance, for example, is read from the Kano server and does not have to travel to another region.

The trade-off is that a query across all regions, such as a national consumption report, has to collect data from three servers and so takes longer. In the same way, a query that does not include the shard key has to look in every shard.

### Demonstration

`01_partition_by_region.sql` splits a copy of the readings into three partitions, one per region, using PostgreSQL list partitioning on `region_id`. It shows three things:
- Each reading is stored in the partition for its region ([partition-rows.png](screenshots/partition-rows.png)).
- A query for Kano readings scans only the Kano partition ([explain-kano.png](screenshots/explain-kano.png)).
- A query that filters on `meter_id` alone has to scan all three partitions ([explain-all.png](screenshots/explain-all.png)).

This demonstration runs on one PostgreSQL server. It shows the idea of fragmentation, but the partitions are not on separate machines, so it does not test network failure or replication.

## 2. Replication

Each regional server would have a backup copy on a second server.

- **Wallet and token purchases: synchronous replication.** A change is confirmed only after the backup has it too. Customers' money must be accounted for even if a server fails, so the extra delay is acceptable. The cost is that writes slow down, and if the backup cannot be reached, writes may have to wait.
- **Meter readings: asynchronous replication.** Readings are copied to the backup a little later. This keeps normal operation fast. The cost is that if the main server fails, the last few readings that had not yet been copied could be lost.

## 3. Consistency choice per table (CAP)

When the network between servers breaks, a system must choose between consistency and availability.

| Table | Choice | Reason |
|---|---|---|
| `wallet` | CP | Customers must see the correct balance, and the same money must not be spent twice. |
| `token_purchase` | CP | It avoids duplicate purchases and tokens issued without confirmed payment. |
| `reading` | AP | Meters should keep recording even when the network is down, and readings can be synchronised later. |
| `fault_alert` | AP | Faults must still be recorded and viewed during network problems, and differences can be fixed afterwards. |

This matches the concurrency demonstration in Portfolio 3, where wallet updates needed row locking so that two purchases could not both spend the same balance. A reading is also never changed after it is recorded, which is why late synchronisation is safe for it.

## 4. If the Kano server fails

Without a backup, Kano customers could not reach wallet balances, token purchases or meter records until the server returned. Customers in Lagos and Ogun would carry on normally, because their data sits on their own regional servers. This is the benefit of sharding: a failure stays inside one region.

With the backup from section 2, the Kano backup can take over. For wallets and token purchases nothing is lost, because the backup was updated at the same time. For readings, the last few unsynchronised readings may be missing and would need to be requested again from the meters.

## 5. Limits

- Only the sharding idea was demonstrated, on a single server.
- Replication, failover and the consistency choices are described in design terms and were not built or tested on several servers or in the cloud.