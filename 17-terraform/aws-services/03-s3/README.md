# S3 — Object Storage

Amazon S3 stores **objects** (bytes plus metadata) under keys in **buckets**. Bucket names are globally unique within an AWS partition; keys provide prefixes resembling folders, not a POSIX filesystem. S3 is useful for static assets, backups, data lakes and application artifacts.

**Storage classes** trade retrieval behavior and cost: Standard for active data, Intelligent-Tiering for variable access, Standard-IA/One Zone-IA for less-frequent access, and Glacier classes for archives with varying retrieval times. Choose according to access frequency, availability and retention needs rather than assuming all classes retrieve instantly or have the same minimum duration.

**Versioning** keeps multiple object versions and uses delete markers for ordinary deletes. It helps recover overwrites but means deleting a key does not remove all stored versions. **Lifecycle policies** transition or expire current/noncurrent versions according to rules; configure them carefully for retention requirements. **Encryption** can use S3-managed keys (SSE-S3) or KMS keys (SSE-KMS), plus TLS in transit. Encryption does not grant authorization.

**Bucket policies** are resource-based JSON policies controlling access and conditions. Combine identity policies, bucket policy and public-access controls; keep Block Public Access on for private data. The assignment demo explicitly enables versioning, encryption and all public-access blocks. Empty all versions before cleanup.

Reference: [Amazon S3 overview](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html).
