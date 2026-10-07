# DynamoDB and RDS — Database Services

| Dimension | DynamoDB | RDS |
|---|---|---|
| Model | Managed NoSQL key-value/document | Managed relational database |
| Data | Tables contain items with attributes | Tables contain typed rows and relationships |
| Access | Design partition/sort keys and indexes around queries | SQL, joins, constraints and indexes |
| Examples | Session state, shopping carts, predictable key lookups | Orders, financial records, relational business applications |

## DynamoDB

A **table** contains **items**; each item has **attributes**. The primary key is either a partition key alone or a partition key plus sort key. The **partition key** determines data distribution; the **sort key** orders related items sharing a partition key and enables range queries. In a composite key, the pair is unique, not the partition key alone. Pick keys that distribute traffic to avoid hot partitions. Secondary indexes support additional access patterns; a scan reads broadly and is not a substitute for query-oriented design. Capacity modes include on-demand and provisioned capacity. IAM controls access, with encryption and backups available.

## RDS

RDS manages relational **DB instances** and operational tasks around engines including PostgreSQL, MySQL, MariaDB, Oracle, SQL Server and Db2; Amazon Aurora supplies MySQL/PostgreSQL-compatible managed cluster options. Choose engine/version availability for the region. Deploy in private subnets, restrict security groups to application clients, use TLS/encryption and store credentials securely.

**Automated backups** and transaction logs support point-in-time recovery within retention; manual snapshots support deliberate retention. **Multi-AZ** is a high-availability deployment choice, not a generic promise of read scaling: a traditional Multi-AZ DB instance standby does not serve reads. **Read replicas** typically replicate asynchronously and offload reads; replication lag and failover behavior differ from a standby. Multi-AZ DB clusters have different readable-instance capabilities, so specify the deployment type.

References: [DynamoDB core components](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.CoreComponents.html), [RDS overview](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Welcome.html).
