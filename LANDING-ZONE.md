# Part 4 – Deploying Inside an AWS Landing Zone

## 1. Research – What is a Landing Zone?

A Landing Zone is a multi-account AWS environment with centralized governance, security, and networking. Organizations use it because a single account becomes hard to secure, bill, and operate at scale.

Typical accounts:
- **Management** – Organizations, billing, Control Tower
- **Log Archive** – centralized CloudTrail / Config logs
- **Security / Audit** – security tooling and findings
- **Network** – Transit Gateway, shared ingress/egress, CloudFront, WAF
- **Shared Services** – CI/CD runners, artifact repositories
- **Workload** – one (or more) per application or team

Sources: AWS Control Tower docs, Landing Zone Accelerator, AWS multi-account whitepaper.

## 2. Placement Diagram (Scenario)

```
Browser
   │
   ▼
[Network Account]
   CloudFront + WAF + Shared ALB
   │
   ▼ (Transit Gateway)
[Workload Account]
   VPC (private subnets only, no IGW/NAT)
   └── EKS Cluster
       └── Pods
```

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
