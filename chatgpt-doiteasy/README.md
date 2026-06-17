# Project Overview

This project is a beginner-friendly Terraform implementation of the **"Do it easy"** assignment. The goal is to provision the required AWS infrastructure directly with simple Terraform resources, without using modules, variables, remote state, conditional logic, multiple environments, Docker installation, or Docker containers.

The project creates a basic public web architecture that contains:

- A custom VPC instead of the AWS default VPC.
- Two public subnets in separate Availability Zones.
- An Internet Gateway attached to the VPC.
- A public route table that sends internet-bound traffic to the Internet Gateway.
- Security groups for the Application Load Balancer and EC2 instances.
- Two Amazon Linux EC2 instances, one in each public subnet.
- A public-facing Application Load Balancer.
- A Target Group containing both EC2 instances.
- An HTTP listener on port 80 that forwards requests to the Target Group.
- Useful outputs for the VPC, subnets, EC2 public IP addresses, and ALB DNS name.

## How the Architecture Works

The architecture is intentionally simple and suitable for a first Terraform assignment:

1. Terraform creates a new VPC with a private IP range of `10.0.0.0/16`.
2. Terraform creates two public subnets inside that VPC:
   - `10.0.1.0/24` in `us-east-1a`
   - `10.0.2.0/24` in `us-east-1b`
3. Terraform creates and attaches an Internet Gateway to allow public internet connectivity.
4. Terraform creates a route table with a default route, `0.0.0.0/0`, pointing to the Internet Gateway.
5. Both public subnets are associated with that public route table.
6. Terraform launches one EC2 instance in each public subnet.
7. Terraform creates a public Application Load Balancer across both public subnets.
8. Terraform creates a Target Group and registers both EC2 instances as targets.
9. Terraform creates an ALB listener on port 80 that forwards HTTP requests to the Target Group.

## Traffic Flow

Traffic flows through the environment as follows:

```text
Internet User
    |
    | HTTP request on port 80
    v
Public Application Load Balancer
    |
    | Forwards request to Target Group
    v
Target Group
    |
    | Routes request to a healthy registered target
    v
EC2 Instance A or EC2 Instance B
```

> **Note:** This project provisions infrastructure only. It does not install a web server or run Docker containers on the EC2 instances. If the EC2 instances do not serve HTTP traffic on port 80, the ALB targets may appear unhealthy until application software is installed manually or in a later assignment step.

# Architecture

```text
+--------------------------------------------------------------------------------+
| Custom VPC: doiteasy-vpc                                                       |
| CIDR: 10.0.0.0/16                                                              |
|                                                                                |
|   +-----------------------------+        +-----------------------------+       |
|   | Public Subnet A             |        | Public Subnet B             |       |
|   | doiteasy-public-subnet-1    |        | doiteasy-public-subnet-2    |       |
|   | CIDR: 10.0.1.0/24           |        | CIDR: 10.0.2.0/24           |       |
|   | AZ: us-east-1a              |        | AZ: us-east-1b              |       |
|   |                             |        |                             |       |
|   | EC2 Instance A              |        | EC2 Instance B              |       |
|   | doiteasy-web-1              |        | doiteasy-web-2              |       |
|   +-----------------------------+        +-----------------------------+       |
|                                                                                |
|   +------------------------------------------------------------------------+   |
|   | Public Application Load Balancer: doiteasy-alb                         |   |
|   | Listener: HTTP :80                                                     |   |
|   +------------------------------------------------------------------------+   |
|                                      |                                         |
|                                      v                                         |
|   +------------------------------------------------------------------------+   |
|   | Target Group: doiteasy-web-tg                                          |   |
|   | Targets: doiteasy-web-1, doiteasy-web-2                                |   |
|   +------------------------------------------------------------------------+   |
|                                                                                |
|   +------------------------------------------------------------------------+   |
|   | Public Route Table                                                     |   |
|   | Route: 0.0.0.0/0 -> Internet Gateway                                   |   |
|   +------------------------------------------------------------------------+   |
|                                      |                                         |
+--------------------------------------|-----------------------------------------+
                                       |
                                       v
                          Internet Gateway: doiteasy-igw
                                       |
                                       v
                                    Internet
```

# Created Resources

| Resource Type | Resource Name | Purpose |
| ------------- | ------------- | ------- |
| `aws_vpc` | `doiteasy_vpc` | Creates a custom VPC for all assignment resources. |
| `aws_subnet` | `public_subnet_1` | Creates the first public subnet for one EC2 instance and the ALB. |
| `aws_subnet` | `public_subnet_2` | Creates the second public subnet for one EC2 instance and the ALB. |
| `aws_internet_gateway` | `doiteasy_igw` | Provides internet connectivity for the VPC. |
| `aws_route_table` | `public_route_table` | Defines the public route to the Internet Gateway. |
| `aws_route_table_association` | `public_subnet_1_association` | Associates public subnet A with the public route table. |
| `aws_route_table_association` | `public_subnet_2_association` | Associates public subnet B with the public route table. |
| `aws_security_group` | `alb_security_group` | Allows inbound HTTP traffic from the internet to the ALB. |
| `aws_security_group` | `ec2_security_group` | Allows SSH from one public IP and HTTP from the ALB security group. |
| `data.aws_ami` | `amazon_linux` | Looks up a recent Amazon Linux 2023 AMI. |
| `aws_instance` | `web_1` | Creates the first EC2 instance in public subnet A. |
| `aws_instance` | `web_2` | Creates the second EC2 instance in public subnet B. |
| `aws_lb` | `doiteasy_alb` | Creates a public Application Load Balancer across both subnets. |
| `aws_lb_target_group` | `web_target_group` | Creates an HTTP Target Group for the EC2 instances. |
| `aws_lb_target_group_attachment` | `web_1_attachment` | Registers EC2 instance A with the Target Group. |
| `aws_lb_target_group_attachment` | `web_2_attachment` | Registers EC2 instance B with the Target Group. |
| `aws_lb_listener` | `http_listener` | Listens on port 80 and forwards traffic to the Target Group. |
| `output` | `vpc_id` | Prints the VPC ID after deployment. |
| `output` | `public_subnet_ids` | Prints both public subnet IDs after deployment. |
| `output` | `ec2_public_ips` | Prints both EC2 public IP addresses after deployment. |
| `output` | `load_balancer_dns_name` | Prints the public DNS name of the ALB after deployment. |

## Resource Details

### VPC

The VPC is the isolated network boundary for this assignment. It uses the CIDR block `10.0.0.0/16`, which provides enough private IP space for the two public subnets.

### Public Subnets

Two public subnets are created in different Availability Zones. This is required because an Application Load Balancer must be deployed across at least two subnets in different Availability Zones.

### Internet Gateway and Route Table

The Internet Gateway allows resources in the VPC to communicate with the public internet when routing permits it. The public route table sends all non-local traffic, represented by `0.0.0.0/0`, to the Internet Gateway.

### Security Groups

The ALB security group allows public HTTP traffic on port 80. The EC2 security group allows SSH on port 22 only from a single placeholder CIDR and allows HTTP on port 80 only from the ALB security group.

### EC2 Instances

Two Amazon Linux EC2 instances are created, one in each public subnet. They are associated with public IP addresses so they can be reached over SSH from the allowed public IP CIDR.

### Application Load Balancer and Target Group

The Application Load Balancer accepts public HTTP traffic. The listener forwards traffic to the Target Group, and the Target Group distributes traffic to the two registered EC2 instances.

# Prerequisites

Before deploying this project, confirm that you have the required AWS account access and local tools.

## AWS Requirements

| Requirement | Description |
| ----------- | ----------- |
| AWS Account | You need an active AWS account where you are allowed to create networking, compute, and load balancing resources. |
| IAM permissions | Your IAM user or role must be allowed to manage VPCs, subnets, route tables, Internet Gateways, security groups, EC2 instances, Elastic Load Balancing resources, and AMI lookups. |
| EC2 Key Pair | You need an existing EC2 key pair in the selected AWS region so Terraform can attach it to the EC2 instances. |
| AWS Region support | The selected region must support the Availability Zones and instance type used by this project. |

Recommended IAM permissions for this learning project include access to these AWS services:

- Amazon VPC
- Amazon EC2
- Elastic Load Balancing v2
- IAM read access if your organization requires role validation
- STS for identity verification

> **Best practice:** Use least-privilege IAM permissions in real environments. For a beginner lab, an instructor may provide a sandbox account or temporary administrative access.

## Local Requirements

| Tool | Recommended Version | Verification Command |
| ---- | ------------------- | -------------------- |
| Terraform | `>= 1.5.0` | `terraform version` |
| AWS CLI | AWS CLI v2 recommended | `aws --version` |
| Git | Any current stable version | `git --version` |

Run these commands locally to verify your tools:

```bash
terraform version
```

Expected result: Terraform prints an installed version such as `Terraform v1.5.7` or newer.

```bash
aws --version
```

Expected result: AWS CLI prints a version string such as `aws-cli/2.x.x`.

```bash
git --version
```

Expected result: Git prints a version string such as `git version 2.x.x`.

# Project Structure

```text
chatgpt-doiteasy/
├── README.md
├── alb.tf
├── main.tf
├── outputs.tf
├── provider.tf
└── security.tf
```

| File | Responsibility |
| ---- | -------------- |
| `provider.tf` | Defines the required Terraform version, AWS provider source/version, and AWS region. |
| `main.tf` | Defines the Amazon Linux AMI lookup, VPC, public subnets, Internet Gateway, route table, route table associations, and EC2 instances. |
| `security.tf` | Defines the ALB and EC2 security groups and their inbound/outbound rules. |
| `alb.tf` | Defines the Application Load Balancer, Target Group, Target Group attachments, and HTTP listener. |
| `outputs.tf` | Defines useful Terraform outputs displayed after deployment. |
| `README.md` | Provides this technical guide for deployment, verification, troubleshooting, and cleanup. |

> **Note:** Some Terraform projects split networking and compute into files such as `networking.tf` and `compute.tf`. This beginner project keeps those resources in `main.tf` to stay simple and easy to follow.

# Configuration Before Deployment

Review and update the following values before running `terraform apply`.

## AWS Region

| Item | Value |
| ---- | ----- |
| File | `provider.tf` |
| Current value | `us-east-1` |
| Why it matters | Terraform creates all AWS resources in this region. EC2 key pairs and Availability Zones are region-specific. |

Example:

```hcl
provider "aws" {
  region = "us-east-1"
}
```

How to choose the correct value:

1. Open the AWS Console.
2. Use the region selector in the top-right corner.
3. Choose a region where you are allowed to create EC2, VPC, and ALB resources.
4. Use the region code, such as `us-east-1`, `us-west-2`, or `eu-west-1`.

> **Important:** If you change the region, also update the Availability Zones in `main.tf`.

## Availability Zones

| Item | Value |
| ---- | ----- |
| File | `main.tf` |
| Current values | `us-east-1a`, `us-east-1b` |
| Why it matters | The two public subnets should be in different Availability Zones for ALB high availability. |

Example:

```hcl
availability_zone = "us-east-1a"
```

To find Availability Zones in your selected region:

```bash
aws ec2 describe-availability-zones --region us-east-1 --query "AvailabilityZones[*].ZoneName" --output table
```

If you deploy in `us-west-2`, for example, you might use `us-west-2a` and `us-west-2b`.

## EC2 Key Pair Name

| Item | Value |
| ---- | ----- |
| File | `main.tf` |
| Current value | `REPLACE_WITH_YOUR_KEY_PAIR_NAME` |
| Why it matters | AWS uses the key pair to allow SSH access to EC2 instances. Terraform will fail if the key pair does not exist in the selected region. |

Example:

```hcl
key_name = "my-lab-key"
```

To list key pairs in the selected region:

```bash
aws ec2 describe-key-pairs --region us-east-1 --query "KeyPairs[*].KeyName" --output table
```

If you do not have a key pair, create one in the AWS Console:

1. Go to **EC2**.
2. Open **Network & Security**.
3. Choose **Key Pairs**.
4. Choose **Create key pair**.
5. Save the private key file securely.

## SSH Allowed IP/CIDR

| Item | Value |
| ---- | ----- |
| File | `security.tf` |
| Current value | `203.0.113.10/32` |
| Why it matters | This restricts SSH access to only your public IP address. |

Example:

```hcl
cidr_blocks = ["198.51.100.25/32"]
```

To find your public IP address:

```bash
curl https://checkip.amazonaws.com
```

If the command returns:

```text
198.51.100.25
```

then use:

```hcl
cidr_blocks = ["198.51.100.25/32"]
```

> **Warning:** Do not use `0.0.0.0/0` for SSH in this assignment. That would allow SSH attempts from the entire internet.

## AMI ID

| Item | Value |
| ---- | ----- |
| File | `main.tf` |
| Current behavior | Terraform automatically looks up a recent Amazon Linux 2023 AMI. |
| Why it matters | EC2 instances need an AMI to know which operating system to boot. |

This project uses a data source instead of a hardcoded AMI ID:

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
}
```

You usually do not need to change this. If your instructor requires a specific AMI ID, replace the data source usage with the required AMI ID.

# Deployment Guide

Follow these steps from a terminal on your local machine.

## Step 1 – Clone Repository

Clone the repository that contains this project:

```bash
git clone <repository-url>
```

Change into the repository directory:

```bash
cd terraform-aws-infra
```

Change into this assignment folder:

```bash
cd chatgpt-doiteasy
```

Confirm that the expected Terraform files are present:

```bash
ls
```

Expected files include:

```text
README.md
alb.tf
main.tf
outputs.tf
provider.tf
security.tf
```

## Step 2 – Configure AWS Credentials

Terraform uses the AWS provider, and the AWS provider needs credentials. You can configure credentials in several ways.

### Option A – AWS CLI

Run:

```bash
aws configure
```

The AWS CLI prompts for four values:

| Prompt | What to enter |
| ------ | ------------- |
| `AWS Access Key ID` | Your IAM user's access key ID. |
| `AWS Secret Access Key` | Your IAM user's secret access key. |
| `Default region name` | The same region used in `provider.tf`, for example `us-east-1`. |
| `Default output format` | Use `json` unless your team requires another format. |

Example prompt flow:

```text
AWS Access Key ID [None]: AKIA...
AWS Secret Access Key [None]: ********
Default region name [None]: us-east-1
Default output format [None]: json
```

### Option B – Environment Variables

You can also export credentials directly in your shell.

Linux or macOS:

```bash
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
export AWS_DEFAULT_REGION="us-east-1"
```

If you use temporary credentials, also export the session token:

```bash
export AWS_SESSION_TOKEN="your-session-token"
```

Windows PowerShell:

```powershell
$env:AWS_ACCESS_KEY_ID="your-access-key-id"
$env:AWS_SECRET_ACCESS_KEY="your-secret-access-key"
$env:AWS_DEFAULT_REGION="us-east-1"
```

With temporary credentials in PowerShell:

```powershell
$env:AWS_SESSION_TOKEN="your-session-token"
```

### Verify Credentials

Run:

```bash
aws sts get-caller-identity
```

Expected output is JSON similar to this:

```json
{
  "UserId": "AIDAEXAMPLEUSERID",
  "Account": "123456789012",
  "Arn": "arn:aws:iam::123456789012:user/example-user"
}
```

If this command succeeds, AWS credentials are configured correctly for the current shell.

## Step 3 – Initialize Terraform

Run:

```bash
terraform init
```

What this command does:

- Reads the Terraform configuration files in the current directory.
- Downloads the AWS provider plugin from the Terraform Registry.
- Creates the local `.terraform` directory.
- Creates or updates the provider dependency lock file, `.terraform.lock.hcl`.
- Prepares the directory so Terraform can run `plan`, `apply`, and `destroy`.

Expected result:

```text
Terraform has been successfully initialized!
```

## Step 4 – Review Execution Plan

Run:

```bash
terraform plan
```

What this command does:

- Reads the Terraform configuration.
- Compares the desired infrastructure with the current Terraform state.
- Contacts AWS to check existing remote objects when needed.
- Shows which resources Terraform will create, change, or destroy.

Before continuing, review the plan carefully. For this assignment, you should expect Terraform to create resources such as:

- `aws_vpc.doiteasy_vpc`
- `aws_subnet.public_subnet_1`
- `aws_subnet.public_subnet_2`
- `aws_internet_gateway.doiteasy_igw`
- `aws_route_table.public_route_table`
- `aws_security_group.alb_security_group`
- `aws_security_group.ec2_security_group`
- `aws_instance.web_1`
- `aws_instance.web_2`
- `aws_lb.doiteasy_alb`
- `aws_lb_target_group.web_target_group`
- `aws_lb_listener.http_listener`

> **Best practice:** Do not run `terraform apply` until you understand what Terraform plans to create.

## Step 5 – Deploy Infrastructure

Run:

```bash
terraform apply
```

Terraform displays the execution plan again and asks for confirmation:

```text
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

Type:

```text
yes
```

Approximate deployment time:

- VPC, subnets, route table, and security groups: usually less than 1 minute.
- EC2 instances: usually 1–3 minutes.
- Application Load Balancer and Target Group: usually 2–5 minutes.

When the deployment completes, Terraform prints the outputs defined in `outputs.tf`.

# Verification

Use both Terraform outputs and the AWS Console to verify the deployment.

## Verify Terraform Outputs

Run:

```bash
terraform output
```

You should see values for:

- `vpc_id`
- `public_subnet_ids`
- `ec2_public_ips`
- `load_balancer_dns_name`

## Verify VPC Creation

AWS Console path:

```text
AWS Console -> VPC -> Your VPCs
```

Check that a VPC named `doiteasy-vpc` exists with CIDR block `10.0.0.0/16`.

CLI option:

```bash
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=doiteasy-vpc" --region us-east-1
```

## Verify Subnet Creation

AWS Console path:

```text
AWS Console -> VPC -> Subnets
```

Check that these subnets exist:

| Subnet Name | CIDR | Availability Zone |
| ----------- | ---- | ----------------- |
| `doiteasy-public-subnet-1` | `10.0.1.0/24` | `us-east-1a` |
| `doiteasy-public-subnet-2` | `10.0.2.0/24` | `us-east-1b` |

CLI option:

```bash
aws ec2 describe-subnets --filters "Name=tag:Name,Values=doiteasy-public-subnet-*" --region us-east-1
```

## Verify Route Table and Internet Gateway

AWS Console paths:

```text
AWS Console -> VPC -> Internet Gateways
AWS Console -> VPC -> Route Tables
```

Check that:

- `doiteasy-igw` is attached to `doiteasy-vpc`.
- `doiteasy-public-route-table` has a route for `0.0.0.0/0` pointing to the Internet Gateway.
- Both public subnets are associated with the public route table.

## Verify Security Groups

AWS Console path:

```text
AWS Console -> EC2 -> Network & Security -> Security Groups
```

Check these security groups:

| Security Group | Expected Rules |
| -------------- | -------------- |
| `doiteasy-alb-sg` | Inbound HTTP from `0.0.0.0/0`; outbound all traffic. |
| `doiteasy-ec2-sg` | Inbound SSH from your `/32` CIDR; inbound HTTP from the ALB security group; outbound all traffic. |

## Verify EC2 Instances

AWS Console path:

```text
AWS Console -> EC2 -> Instances
```

Check that these instances exist and are running:

- `doiteasy-web-1`
- `doiteasy-web-2`

Confirm that each instance:

- Is in a different public subnet.
- Has a public IPv4 address.
- Uses the `doiteasy-ec2-sg` security group.

CLI option:

```bash
aws ec2 describe-instances --filters "Name=tag:Name,Values=doiteasy-web-*" --region us-east-1
```

## Verify Load Balancer

AWS Console path:

```text
AWS Console -> EC2 -> Load Balancing -> Load Balancers
```

Check that `doiteasy-alb` exists and has:

- Scheme: `internet-facing`
- Type: `application`
- Listener: HTTP port 80
- Subnets: both public subnets

CLI option:

```bash
aws elbv2 describe-load-balancers --names doiteasy-alb --region us-east-1
```

## Verify Target Group and Target Health

AWS Console path:

```text
AWS Console -> EC2 -> Load Balancing -> Target Groups -> doiteasy-web-tg -> Targets
```

Check that both EC2 instances are registered as targets.

CLI option:

```bash
aws elbv2 describe-target-health --target-group-arn <target-group-arn> --region us-east-1
```

> **Important:** Because this project does not install a web server on the EC2 instances, the targets may show as `unhealthy`. That is expected for an infrastructure-only assignment unless you manually install software that listens on port 80.

# Outputs

The project defines these Terraform outputs:

| Output | Description | How to Use It |
| ------ | ----------- | ------------- |
| `vpc_id` | The ID of the custom VPC. | Use it to confirm where resources were created or to inspect the VPC in AWS. |
| `public_subnet_ids` | The IDs of both public subnets. | Use them to verify subnet placement or troubleshoot ALB subnet configuration. |
| `ec2_public_ips` | The public IPv4 addresses of both EC2 instances. | Use them for SSH access if your IP is allowed and the key pair is correct. |
| `load_balancer_dns_name` | The public DNS name of the ALB. | Use it to test HTTP access to the load balancer. |

To display outputs at any time after deployment:

```bash
terraform output
```

To display one output:

```bash
terraform output load_balancer_dns_name
```

# Troubleshooting

## Missing AWS Credentials

| Item | Details |
| ---- | ------- |
| Symptoms | `terraform plan` or `terraform apply` fails with credential errors such as `NoCredentialProviders`, `Unable to locate credentials`, or `InvalidClientTokenId`. |
| Root cause | Terraform cannot find valid AWS credentials for the AWS provider. |
| Resolution | Configure credentials with `aws configure` or environment variables, then verify with `aws sts get-caller-identity`. |

Commands:

```bash
aws configure
aws sts get-caller-identity
```

## Invalid or Missing Key Pair

| Item | Details |
| ---- | ------- |
| Symptoms | `terraform apply` fails while creating EC2 instances with an error related to `InvalidKeyPair.NotFound`. |
| Root cause | The value of `key_name` in `main.tf` does not match an existing EC2 key pair in the selected region. |
| Resolution | Create or locate a key pair in the same AWS region, then update `key_name` in `main.tf`. |

List available key pairs:

```bash
aws ec2 describe-key-pairs --region us-east-1 --query "KeyPairs[*].KeyName" --output table
```

## Security Group Issues

| Item | Details |
| ---- | ------- |
| Symptoms | SSH to EC2 fails, or HTTP traffic does not reach instances. |
| Root cause | The SSH CIDR may not match your current public IP, or HTTP rules may have been changed incorrectly. |
| Resolution | Confirm your public IP and update the SSH CIDR. Confirm that EC2 HTTP ingress allows the ALB security group. |

Find your public IP:

```bash
curl https://checkip.amazonaws.com
```

## EC2 Launch Failures

| Item | Details |
| ---- | ------- |
| Symptoms | EC2 instances fail to launch, or Terraform reports capacity, AMI, subnet, or permission errors. |
| Root cause | Common causes include unsupported instance type in the selected region, invalid AMI lookup, missing IAM permissions, or service quota limits. |
| Resolution | Check the error message, verify the region and Availability Zones, confirm IAM permissions, and try another supported instance type if needed. |

Useful command:

```bash
aws ec2 describe-instance-type-offerings --location-type availability-zone --filters "Name=instance-type,Values=t2.micro" --region us-east-1
```

## ALB Target Unhealthy

| Item | Details |
| ---- | ------- |
| Symptoms | The Target Group shows EC2 instances as `unhealthy`. The ALB DNS name may return an error. |
| Root cause | This infrastructure-only project does not install a web server. The ALB health check expects an HTTP response on port 80. |
| Resolution | For this assignment, confirm that the targets are registered. In a later step, install and run a web server or application on port 80. |

Check target health:

```bash
aws elbv2 describe-target-health --target-group-arn <target-group-arn> --region us-east-1
```

## Terraform State Lock Issues

| Item | Details |
| ---- | ------- |
| Symptoms | Terraform reports that the state is locked. |
| Root cause | A previous Terraform operation may have been interrupted. |
| Resolution | Wait for any running Terraform command to finish. If you are certain no Terraform command is running, use `terraform force-unlock` with caution. |

Example:

```bash
terraform force-unlock <lock-id>
```

> **Warning:** Do not force-unlock Terraform state unless you are sure no other Terraform operation is running.

## Region or Availability Zone Mismatch

| Item | Details |
| ---- | ------- |
| Symptoms | Terraform fails with an Availability Zone error, or the key pair is not found even though it exists in another region. |
| Root cause | `provider.tf`, subnet Availability Zones, and the EC2 key pair region do not match. |
| Resolution | Make sure the provider region, Availability Zones, and EC2 key pair all belong to the same AWS region. |

# Cost Warning

This project creates real AWS resources that can generate charges.

Resources that may cost money include:

| Resource | Cost Consideration |
| -------- | ------------------ |
| EC2 instances | Charged while running, even if idle. |
| Application Load Balancer | Charged per hour and based on Load Balancer Capacity Units. |
| EBS root volumes | Charged for storage attached to EC2 instances. |
| Public IPv4 addresses | AWS may charge for public IPv4 addresses depending on current AWS pricing. |
| Data transfer | Internet or cross-AZ traffic may generate charges. |

Recommendations to minimize cost:

- Run this project only in a lab or sandbox account.
- Use small instance types such as `t2.micro` for learning.
- Destroy the infrastructure immediately after completing the assignment.
- Verify that all resources are removed after `terraform destroy`.
- Avoid leaving the ALB and EC2 instances running overnight.

> **Warning:** Always check current AWS pricing for your selected region. Pricing can change over time.

# Cleanup

When you are finished, destroy all resources created by this project.

From inside the `chatgpt-doiteasy` folder, run:

```bash
terraform destroy
```

Terraform displays a destroy plan and asks for confirmation:

```text
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value:
```

Type:

```text
yes
```

## What Happens During Destroy

Terraform deletes the resources it created, including:

- ALB listener
- Target Group attachments
- Target Group
- Application Load Balancer
- EC2 instances
- Security groups
- Route table associations
- Route table
- Internet Gateway
- Public subnets
- VPC

## Verify Cleanup

After `terraform destroy` completes, run:

```bash
terraform state list
```

Expected result:

```text
No resources found in state.
```

Also verify in the AWS Console:

```text
AWS Console -> EC2 -> Instances
AWS Console -> EC2 -> Load Balancing -> Load Balancers
AWS Console -> VPC -> Your VPCs
```

Confirm that the assignment resources are gone.

> **Best practice:** If destroy fails, read the error carefully. Some resources may have dependencies that need to be removed first. Re-run `terraform destroy` after resolving the issue.

# Assignment Compliance

This project implements only the **"Do it easy"** requirements.

| Assignment Requirement | Terraform Resource | Implemented |
| ---------------------- | ------------------ | ----------- |
| Create a custom VPC; do not use the default VPC. | `aws_vpc.doiteasy_vpc` | Yes |
| Create 2 public subnets inside the VPC. | `aws_subnet.public_subnet_1`, `aws_subnet.public_subnet_2` | Yes |
| Create and attach an Internet Gateway. | `aws_internet_gateway.doiteasy_igw` | Yes |
| Configure route tables so both subnets have internet access. | `aws_route_table.public_route_table`, `aws_route_table_association.public_subnet_1_association`, `aws_route_table_association.public_subnet_2_association` | Yes |
| Create a Security Group that allows SSH from the user's public IP only. | `aws_security_group.ec2_security_group` | Yes, using a `/32` placeholder CIDR to be replaced by the user. |
| Create security group rules for HTTP access as needed for the Load Balancer and instances. | `aws_security_group.alb_security_group`, `aws_security_group.ec2_security_group` | Yes |
| Create 2 EC2 instances. | `aws_instance.web_1`, `aws_instance.web_2` | Yes |
| Place one EC2 instance in each subnet. | `aws_instance.web_1`, `aws_instance.web_2` subnet assignments | Yes |
| Use a common Amazon Linux AMI. | `data.aws_ami.amazon_linux` | Yes |
| Associate public IPs where needed. | `associate_public_ip_address = true` and public subnet settings | Yes |
| Create a public-facing Application Load Balancer. | `aws_lb.doiteasy_alb` | Yes |
| Spread the ALB across both subnets. | `aws_lb.doiteasy_alb.subnets` | Yes |
| Create a Target Group. | `aws_lb_target_group.web_target_group` | Yes |
| Attach both EC2 instances to the Target Group. | `aws_lb_target_group_attachment.web_1_attachment`, `aws_lb_target_group_attachment.web_2_attachment` | Yes |
| Create an ALB Listener on port 80 forwarding to the Target Group. | `aws_lb_listener.http_listener` | Yes |
| Do not use modules. | Direct Terraform resources only | Yes |
| Do not use variables. | No `variable` blocks are used | Yes |
| Do not use remote state. | No backend configuration is used | Yes |
| Do not use conditional logic. | No conditional expressions or count/for_each logic | Yes |
| Do not create Dev/Prod environments. | Single flat assignment project | Yes |
| Do not install or run Docker. | No Docker resources or provisioning | Yes |

This confirms full compliance with the requested **"Do it easy"** assignment scope.
