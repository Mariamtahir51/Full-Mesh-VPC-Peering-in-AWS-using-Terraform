# Implementing Multi-Region VPC Peering in AWS Using Terraform

Modern cloud applications often require secure communication between isolated networks. In Amazon Web Services (AWS), Virtual Private Cloud (VPC) Peering allows private connectivity between multiple VPCs without routing traffic through the public internet. This makes VPC peering a reliable and low-latency solution for multi-environment architectures such as development, staging, and production.

In this implementation, a full-mesh VPC peering architecture was created using Terraform to connect three different VPCs: Primary, Secondary, and Tertiary. Each VPC contains its own subnet, EC2 instance, route table, internet gateway, and security group. The entire infrastructure was provisioned as Infrastructure as Code (IaC), making the setup reproducible, scalable, and easier to manage.

---

# Architecture Overview

The implementation consists of three VPCs deployed in AWS:

- Primary VPC
- Secondary VPC
- Tertiary VPC

Each VPC contains:

- A public subnet
- An EC2 instance
- An Internet Gateway
- A route table
- A security group

To allow communication among all VPCs, a full-mesh peering topology was implemented. This means every VPC has a direct peering connection with the other VPCs.

The peering connections are:

- Primary ↔ Secondary
- Secondary ↔ Tertiary
- Primary ↔ Tertiary

This design is important because AWS VPC peering is **non-transitive**. If only Primary ↔ Secondary and Secondary ↔ Tertiary were configured, the Primary VPC would still not be able to communicate with the Tertiary VPC through Secondary. AWS does not allow transit routing over VPC peering connections, so direct peering between every pair of VPCs is required.

---

# Creating the VPCs

The first step involved creating three separate VPCs using Terraform resources. Each VPC was assigned a unique CIDR block to avoid overlapping IP ranges. DNS hostnames and DNS support were enabled to ensure proper internal name resolution and instance communication.

Terraform provider aliases were used to manage multiple VPC deployments cleanly. Each provider represented a separate VPC environment, allowing resources to be associated with the correct configuration.

## Example

```hcl
resource "aws_vpc" "primary_vpc" {
  cidr_block           = var.primary_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Primary-VPC"
  }
}
```

---

# Configuring Subnets and Internet Access

A public subnet was created inside each VPC. The subnets were placed in different availability zones to improve fault tolerance and simulate a more realistic production setup.

The following configuration was important:

```hcl
map_public_ip_on_launch = true
```

This ensured that EC2 instances launched inside the subnet automatically received public IP addresses, allowing SSH access from the internet.

Each VPC also received its own Internet Gateway. Route tables were then configured with a default route (`0.0.0.0/0`) pointing to the respective Internet Gateway, enabling outbound internet connectivity.

Finally, each subnet was associated with its corresponding route table.

---

# Launching EC2 Instances

One EC2 instance was deployed into each VPC subnet. The instances used the same Amazon Machine Image (AMI) and instance type for consistency. Separate SSH key pairs were configured for secure access.

User data scripts were also attached to automate initial server configuration during launch. This helped reduce manual setup steps after deployment.

## Example

```hcl
resource "aws_instance" "primary_vpc_instance" {
  ami                    = "ami-0233214e13e500f77"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.primary_vpc_subnet.id
  vpc_security_group_ids = [aws_security_group.primary_security_group.id]
}
```

---

# Implementing Security Groups

Security groups were created to control inbound and outbound traffic between the VPCs.

Each security group allowed:

- SSH access from anywhere
- ICMP traffic from the other VPC CIDRs
- TCP communication between peer VPCs
- All outbound traffic

Initially, the security groups only allowed communication between some VPCs, which caused connectivity limitations. This issue was resolved by adding ingress rules for all VPC CIDRs, ensuring complete communication across the full-mesh topology.

For example:

- The Primary VPC security group allows traffic from both Secondary and Tertiary CIDRs.
- The Secondary VPC security group allows traffic from Primary and Tertiary CIDRs.
- The Tertiary VPC security group allows traffic from Primary and Secondary CIDRs.

This configuration enables successful ping, SSH, and TCP communication between all EC2 instances.

## Example Ingress Rule

```hcl
ingress {
  description = "Allow ICMP from secondary VPC"
  from_port   = -1
  to_port     = -1
  protocol    = "icmp"
  cidr_blocks = [aws_vpc.secondary_vpc.cidr_block]
}
```

---

# Creating VPC Peering Connections

The core part of the implementation involved configuring VPC peering connections.

Three separate peering connections were created:

- Primary to Secondary
- Secondary to Tertiary
- Primary to Tertiary

Because provider aliases were used, Terraform resources could clearly identify which VPC initiated the peering request and which VPC accepted it.

Each peering connection required:

- A requester resource
- An accepter resource

The accepter resources were configured using `aws_vpc_peering_connection_accepter` to automatically approve incoming peering requests.

## Example

```hcl
resource "aws_vpc_peering_connection" "primary_to_secondary" {
  vpc_id      = aws_vpc.primary_vpc.id
  peer_vpc_id = aws_vpc.secondary_vpc.id
  auto_accept = false
}
```

---

# Configuring Peering Routes

After establishing peering connections, routing tables needed to be updated.

For every VPC pair:

- A route was added in the source VPC route table
- The destination CIDR block pointed to the correct peering connection

Bidirectional routing was configured for all VPC pairs.

For example:

- Primary route table contains routes to Secondary and Tertiary CIDRs.
- Secondary route table contains routes to Primary and Tertiary CIDRs.
- Tertiary route table contains routes to Primary and Secondary CIDRs.

## Example Route

```hcl
resource "aws_route" "primary_to_secondary_route" {
  route_table_id            = aws_route_table.primary_vpc_route_table.id
  destination_cidr_block    = aws_vpc.secondary_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
}
```

---

# Multi-Region VPC Peering Support

This implementation can also work across different AWS regions. Terraform supports inter-region VPC peering by using multiple provider configurations and specifying the target region during peering creation.

For cross-region peering:

- Each provider must point to a different AWS region
- The `peer_region` attribute must be configured
- Separate provider aliases should be used for each region

## Example

```hcl
provider "aws" {
  region = var.primary_region
  alias = "primary"
}

provider "aws" {
  region = var.secondary_region
  alias = "secondary"
}

provider "aws" {
  region = var.tertiary_region
  alias = "tertiary"
}
```

Inter-region VPC peering allows private communication between globally distributed environments while still avoiding public internet routing.

---

# Testing Connectivity

After deployment, connectivity was tested between all EC2 instances using private IP addresses.

Commands such as:

```bash
ping
ssh
```

were used to verify successful communication across all VPCs.

The tests confirmed:

- Primary ↔ Secondary communication
- Secondary ↔ Tertiary communication
- Primary ↔ Tertiary communication

This validated that the full-mesh VPC peering implementation was functioning correctly.

---

# Conclusion

This implementation demonstrates how Terraform can be used to automate a scalable and reliable AWS networking architecture using VPC peering. By creating a full-mesh topology, all three VPCs were able to communicate securely using private IP connectivity without relying on the public internet. The project also highlights an important AWS networking concept: VPC peering is non-transitive. Understanding this limitation is essential when designing multi-VPC environments.
