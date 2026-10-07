# VPC — Networking

A Virtual Private Cloud is an isolated logical network. **CIDR** notation describes address space, e.g. `10.20.0.0/16`; a **subnet** subdivides that space within one Availability Zone. **Route tables** map destination prefixes to targets, using the most specific matching route. An **Internet Gateway** attaches a VPC to the internet; a **NAT Gateway** lets private resources initiate outbound connections without accepting unsolicited inbound internet connections (and incurs charges).

A **public subnet** has a direct default route to an Internet Gateway; an IPv4 instance also needs a public IPv4 address and permissive security rules to be internet reachable. A **private subnet** lacks that direct internet route and may send outbound traffic via NAT. Route classification alone does not guarantee access.

**Security Groups** operate on network interfaces, are stateful and contain allow rules. **Network ACLs** operate at subnet boundaries, are stateless, evaluate ordered allow/deny rules and need return-path rules (including ephemeral ports). Both can affect connectivity. DNS resolution, source/destination checks and route associations also matter when debugging.

The cloud assignment uses one public subnet, a default route to an Internet Gateway, and an HTTP rule restricted to the learner's CIDR. Production multi-tier systems often place databases in private subnets across zones.

Reference: [Amazon VPC user guide](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html).
