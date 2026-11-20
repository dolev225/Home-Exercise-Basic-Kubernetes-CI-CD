# Part 2 – Demo Application Access (demoapp.com)

## Current Status

The application is deployed and accessible via the ALB hostname.

Because no real domain is owned, we use the **host file method** (explicitly allowed by the exercise).

## How to Access the Application as demoapp.com

### 1. Get the ALB hostname

```bash
cd Q1
terraform output alb_hostname
# Example: k8s-default-mynodeapp-xxxxxxxxxx-123456789.us-east-1.elb.amazonaws.com
```

### 2. Add to hosts file

**Windows** (`C:\Windows\System32\drivers\etc\hosts`):

```
<ALB_HOSTNAME> demoapp.com
```

**Linux / macOS** (`/etc/hosts`):

```
<ALB_HOSTNAME> demoapp.com
```

Example:
```
k8s-default-mynodeapp-xxxxxxxxxx-123456789.us-east-1.elb.amazonaws.com demoapp.com
```

### 3. Open in browser

```
http://demoapp.com
```

### 4. Take the required screenshot

- Open `http://demoapp.com`
- Make sure the URL bar shows `demoapp.com`
- Take a screenshot of the application

## Certificate (ACM)

An ACM certificate resource is included and can be enabled with:

```bash
terraform apply -var="enable_dns_tls=true" -var="deploy_apps=true"
```

**Note:** ACM DNS validation requires ownership of the domain.  
For this exercise (no domain owned), the hostfile + HTTP method satisfies the requirement.

If you later own `demoapp.com`, set `enable_dns_tls=true` and complete the DNS validation in Route53.

## Pipeline Output

The pipeline already sends the ALB hostname to Slack.  
After adding the hosts file entry, use that hostname with `demoapp.com`.
