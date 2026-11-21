# Part 4 – Deploying Inside an AWS Landing Zone

## 1. Research - Landing Zone

1.A -Landing Zone is a multi-account AWS environment designed for scalable baseline for deploying workloads. Rather than running everything in a single AWS account or manually configuring security networking, and billing for each new project a landing zone establishes standardized guardrails and account structures upfront.

1.B - Account types would you expect to find  are *Management * , *Security* , *Shared Services* , * Experimentation* , *Sandbox (to fix bugs)* 

Management account - he root account that creates the AWS Organization, manages consolidated billing, applies Service Control Policies (SCPs), and provisions new member accounts

Security account - divide to Log Archive & Security Tool . *Log Archive* is where all the logs and the config file are stored for every a account . *Security Tool* Acts as the delegated administrator for organization  giving  the security team services—such as Amazon GuardDuty, AWS Security Hub, and IAM Access Analyzer—giving security teams centralized visibility.

Shared Services account- Managed by central platform or networking teams to provide shared Services across the organization such as Gateway , Firewall , egress , ingress ,VPCs . VPN , golden image , CI/CD, monitoring services and containers registries 

Experimentation account/Sandbox accoun- Working account for testing different environment such as QA , DEV ,PROD or testing bugs in the system


1.C - For the research of the landing zone i use AI such as gemini & grokbot and to conform it i look in the AWS website "https://docs.aws.amazon.com/prescriptive-guidance/latest/strategy-migration/aws-landing-zone.html"






Typical accounts:
- **Management** – Organizations, billing, Control Tower
- **Log Archive** – centralized CloudTrail / Config logs
- **Security / Audit** – security tooling and findings
- **Network** – Transit Gateway, shared ingress/egress, CloudFront, WAF
- **Shared Services** – CI/CD runners, artifact repositories
- **Workload** – one (or more) per application or team

Sources: AWS Control Tower docs, Landing Zone Accelerator, AWS multi-account whitepaper.

## 2. Placement Diagram (Scenario)


*diagram app a pick*

Request Flow
The user navigates to [https://demoapp.com](https://demoapp.com).

Route 53 routes the request to the Load Balancer in the Network Account.

The LB terminates TLS and forwards the request through the Transit Gateway.

The request reaches the EKS Cluster in the Workload Account.

It arrives at a Pod running on one of the Nodes.


**Assumptions:**
- DNS for `demoapp.com` lives in the Network account (or is delegated).
- TLS certificate is on the shared ALB / CloudFront (ACM in Network account).
- The workload VPC has only private subnets; internet egress goes through the Transit Gateway to a centralized NAT in the Network account.
- CI/CD runs in the Shared Services account and assumes a role into the Workload account.

## 3. Network Changes vs Part 1

| # | What I would change | Why |
|---|---------------------|-----|
| 1 | Remove Internet Gateway and NAT from the workload VPC | Egress is centralized via Transit Gateway |
| 2 | No public IPs on nodes | Nodes are in private subnets only |
| 3 | Add VPC Endpoints for ECR, S3, STS | Image pulls and AWS API calls stay private |
| 4 | Use a non-overlapping CIDR (e.g. 10.x allocated by the network team) | Avoid conflicts with other accounts |
| 5 | Point the Ingress/ALB to the shared load balancer instead of creating a new one | Ingress is centralized |

## 4. Guardrails

The three required tags (`environment`, `owner`, `cost_center`) are already applied via `default_tags` in the AWS provider.

If a resource is missing a tag, the organization SCP rejects the API call and the pipeline fails with an explicit error.  
I would add **Checkov** (or tfsec) in the pipeline before `terraform apply` to catch missing tags and other misconfigurations early.

## 5. FinOps

| Resource | Estimated monthly cost (us-east-1) |
|----------|------------------------------------|
| EKS control plane | ~$73 |
| 2× t3.medium nodes | ~$60 |
| NAT Gateway | ~$32 + data |
| ALB | ~$22 |
| **Total** | **~$190–220** |

**Cost cuts for dev:**
1. Spot instances for nodes
2. Scale to 0 outside working hours
3. Delete the environment when idle

I would **not** use Spot or scale-to-zero in production (availability and cold-start risk).  
Tags let finance filter costs by team/owner in Cost Explorer.

## 6. Pipeline Credentials

The pipeline should use **OIDC federation** (GitHub → AWS) to assume a role in the Shared Services account, then assume a second role in the Workload account (cross-account).  
No long-lived access keys are stored in GitHub.

Minimum permissions: EKS, EC2, IAM (limited), Route53, ACM, and Helm-related actions.

## How I worked

- Read AWS Control Tower and Landing Zone Accelerator documentation.
- Compared the scenario with the VPC I built in Part 1.
- Used AI for structure and cost estimates, then verified pricing on the AWS Pricing Calculator and official docs.
- Double-checked that private subnets + Transit Gateway is the standard pattern for centralized egress.
