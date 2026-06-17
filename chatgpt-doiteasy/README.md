# ChatGPT Do It Easy Terraform Assignment

This folder contains a simple Terraform project for the **Do it easy** assignment. It creates the infrastructure only. It does not use modules, variables, remote state, Docker, conditional logic, or separate environments.

## Infrastructure created

Terraform creates the following AWS resources:

- One custom VPC, not the default VPC.
- Two public subnets in different Availability Zones.
- One Internet Gateway attached to the VPC.
- One public route table with internet access for both subnets.
- One security group for the Application Load Balancer.
- One security group for the EC2 instances.
- Two Amazon Linux EC2 instances, one in each public subnet.
- One public-facing Application Load Balancer.
- One Target Group.
- Two Target Group attachments, one for each EC2 instance.
- One HTTP listener on port 80 that forwards traffic to the Target Group.

## Placeholders to replace before running

Before running Terraform, review the files and replace these beginner-assignment placeholders if needed:

1. **AWS region**
   - File: `provider.tf`
   - Current value: `us-east-1`
   - Replace it if you want to deploy to a different AWS region.

2. **Availability Zones**
   - File: `main.tf`
   - Current values: `us-east-1a` and `us-east-1b`
   - If you change the region, update these Availability Zones to match that region.

3. **EC2 key pair name**
   - File: `main.tf`
   - Current value: `REPLACE_WITH_YOUR_KEY_PAIR_NAME`
   - Replace it with an existing EC2 key pair name from your AWS account.

4. **SSH allowed IP/CIDR**
   - File: `security.tf`
   - Current value: `203.0.113.10/32`
   - Replace it with your own public IP address followed by `/32`, for example `198.51.100.25/32`.
   - Do not use `0.0.0.0/0` for SSH in this assignment.

5. **AMI ID if required by your instructor**
   - File: `main.tf`
   - This project automatically looks up a recent Amazon Linux 2023 AMI.
   - If your instructor requires a specific AMI ID, replace the AMI lookup with that AMI ID.

## How to run

From inside this folder, run:

```bash
terraform init
```

Then review the planned changes:

```bash
terraform plan
```

Apply the infrastructure:

```bash
terraform apply
```

When Terraform asks for confirmation, type `yes`.

## How to destroy the resources

AWS resources cost money. Destroy all resources when you are finished with the assignment:

```bash
terraform destroy
```

When Terraform asks for confirmation, type `yes`.

## Useful outputs

After `terraform apply`, Terraform prints:

- VPC ID
- Public subnet IDs
- EC2 public IP addresses
- Load Balancer DNS name

Use the Load Balancer DNS name to test HTTP access after the instances are running and serving web traffic.
