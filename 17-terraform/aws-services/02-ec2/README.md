# EC2 — Compute

Amazon EC2 provides virtual servers. An **AMI** supplies the OS/root-image template; an **instance type** selects CPU, memory, architecture and networking capacity. Match ARM/x86 AMIs to the type. A **key pair** provides SSH public-key authentication where configured; it does not open network access by itself. **Security Groups** are stateful allow-rule firewalls on network interfaces. **EBS** provides persistent block volumes within an Availability Zone; root-volume deletion behavior depends on its delete-on-termination setting.

A **private IP** is used inside private network routing. A **public IP** provides an internet-routable address when routing and firewalls permit; an automatically assigned public IPv4 commonly changes after stop/start. An Elastic IP can provide a stable public address. A public subnet needs an Internet Gateway route in addition to a public address.

Lifecycle: pending → running → stopping → stopped → pending/running, or shutting-down → terminated. Reboot preserves the running instance allocation; stop releases compute while EBS persists; terminate removes the instance and applicable volumes. Stopped instances can still incur storage and other resource charges. Use EC2 for web applications, build workers and services requiring OS-level control; use Auto Scaling and multiple zones for resilience.

Reference: [Amazon EC2 concepts](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html).
