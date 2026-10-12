
# URL Shortener - ECS Project

A URL shortener with click analytics on AWS. Three services, one cluster.

## Architecture
# insert AWS diagram here

## Infrastructure
In this project we made three application services and ran them on ECS using ECS fargate, all infrastructure was automated using IaC using Terraform.

Incoming Traffic from ther internet is filtered through a WAF (web application firewall) so that we can block malicious HTTP/HTTPS requests before they reach the application, next they are routed using an ALB (application load balancer) which sits accross 2 public subnets; into 2 private subnets hosting our application services. The Database has a cache atatched infront of it using Amazon Redis; this is to store frequently used URLs so that they can be accessed quickly in the future.

We have 3 main App serives: our API (app), our Worker, and our dashboard. each of them is Docekrised and container images stored on Amazon ECR, and then deployed and managed using Amazon ECS on AWS fargate.

The API service: is the main entry point for the application. It accepts requests to shorten a URL, then generates the shortened URL and stores it in our database (Amazon RDS, which uses PostgreSQL). When a user clicks the shortened URL, the app retrieves the original URL and redirects the user. It also publishes click events for Amazon SQS to store the analytics.

The Worker service: this polls the Amazon SQS queue we made for click events, it then writes the analytics to the database using postgreSQL. The reason why we used a queue is so that the API doesnt have to wait for the click events to be written into the database; we can simply pass this on as a background task; this maintains the user's experience (No long wait time whilst the analytics are written).  

The Dashboard service: queries the database in order to get the data it needs.

| Service | Language | Port | Description |
|---------|----------|------|-------------|
| **api** | Python | 8080 | Shortens URLs, handles redirects, tracks clicks, publishes events to SQS |
| **worker** | Go | - | Polls SQS for click events, writes analytics to PostgreSQL |
| **dashboard** | Go | 8081 | Analytics API - top URLs, click stats, hourly breakdowns, recent events |

### Networking

### Compute using ECS and ECS Fargate

### Traffic Routing

### Messaging - SQS

### Database using RDS PostgreSQL

### Caching using ElastiCache Redis

### Amazon ECR and logging

### IaC using Terraform

### Security and IAM

## ENGINEERING DECISION: Why was RDS PostgreSQL chosen?
I chose Amazon RDS because it is a FULLY MANAGED; relational; postgreSQL based database service. Rather than Amazon DynamoDB (which is non relational). Because it is fully managed, it reduces our burden of backups, infrastructure provisioning, etc.

My data is in a relational format: the main data ill be storing is shortened URLs and click events, these would BENEFIT from being stored in a table (relational data structure) rather than a non relational database structure. Our data will be in a relational structure: one URL can have multiple clicks: these would make sense to be stored in a table format, which can then be queried using their keys.

In addition to this, our dashboard calculates top URLs (number of clicks), PostgreSQL allows us to query the data using joins, aggregations and grouping: rather than having to structure the query in terms of a specific key structure in advance.

Trade Offs: DynamoDB can be very fast; but complex queries may require additional data modelling.

Overall RDS would be the best fit for this project.

## Docker

## CI/CD

# Deployment Worlflow

## Security

## Troubleshooting Problems

## Local Development

### Requirements

- ECS Fargate - three separate services, one cluster
- Application Load Balancer with WAF routing to the correct service
- Database: DynamoDB or RDS PostgreSQL - you choose, you justify
- ElastiCache Redis (caching layer for the API)
- SQS queue (click events from API to worker)
- VPC with private subnets. No NAT gateways.
- GitHub Actions with OIDC. No long-lived AWS credentials.
- Zero-downtime deployments with rollback on failure
- Least-privilege IAM throughout
- Terraform with remote state
- Multi-stage Docker builds

### Deployment
You've deployed the service. Now a developer merges a PR and expects their change live within minutes - safely, with zero downtime.

<mark>Design and document the full deployment workflow in your README. Code merge to live traffic </mark>

### Deliverables

- [ ] Dockerfiles (one per service)
- [ ] Terraform for all infrastructure
- [ ] GitHub Actions CI/CD pipeline
- [ ] Deployment workflow documentation
- [ ] Working deployment - all services healthy, end-to-end flow functional
- [ ] README with your decisions, trade-offs and database justification


## Grading

- All three services running and healthy
- End-to-end flow works (shorten -> redirect -> analytics)
- Zero-downtime deployments with auto-rollback on health check failure
- No NAT gateways, no long-lived credentials, no hardcoded secrets
- Deployment workflow section present and coherent
- You can explain every resource you created

**Tear down when done.** ALB + WAF cost money even idle.

[LocalStack](https://docs.localstack.cloud/getting-started/) works for local testing of SQS.
