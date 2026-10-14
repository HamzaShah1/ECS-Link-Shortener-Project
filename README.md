
# URL Shortener - ECS Project

# Watch the demo
[![ECS v2 Demo](images/ECSv2-Demo/ECSv2-Demo-Cover.jpg)](https://github.com/user-attachments/assets/e14a65fc-614e-4a58-93e7-da24bfc674ae)


A URL link shortener with click analytics on AWS. One ECS cluster was used to run 3 application services.

Throughout this project I used the following AWS Services, and gained skills in the following technologies:

Amazon VPC, public and private subnets, Internet Gateway (IGW), VPC endpoints, security groups, AWS WAF, Application Load Balancer (ALB), Amazon ECS with AWS Fargate, Amazon ECR, Amazon RDS for PostgreSQL, Amazon ElastiCache for Redis, Amazon SQS, AWS Secrets Manager, IAM, GitHub Actions with OIDC, Terraform for Infrastructure as Code, Amazon S3 for remote Terraform state, and Amazon CloudWatch for logging.

## 1. Architecture Diagram
![AWS Architecture diagram](images/ECSv2.png)

## 2. Infrastructure
In this project we made three application services and ran them on ECS using ECS fargate, all infrastructure was automated using IaC using Terraform.

Incoming Traffic from the internet is filtered through a WAF (web application firewall) so that we can block malicious HTTP/HTTPS requests before they reach the application, next they are routed using an ALB (application load balancer) which sits accross 2 public subnets; into 2 private subnets hosting our application services. The Database has a cache atatched infront of it using Amazon Redis; this is to store frequently used URLs so that they can be accessed quickly in the future.

We have 3 main App serives: our API (app), our Worker, and our dashboard. each of them is Docekrised and container images stored on Amazon ECR, and then deployed and managed using Amazon ECS on AWS fargate.

The API service: is the main entry point for the application. It accepts requests to shorten a URL, then generates the shortened URL and stores it in our database (Amazon RDS, which uses PostgreSQL). When a user clicks the shortened URL, the app retrieves the original URL and redirects the user. It also publishes click events for Amazon SQS to store the analytics.

The Worker service: this polls the Amazon SQS queue we made for click events, it then writes the analytics to the database using postgreSQL. The reason why we used a queue is so that the API doesnt have to wait for the click events to be written into the database; we can simply pass this on as a background task; this maintains the user's experience (No long wait time whilst the analytics are written).  

The Dashboard service: exposes API endpoints that allow us to query postgreSQL to retrieve and calulate analytics information. It then returns this data to the frontend allowing users to see the analytics.

| Service | Language | Port | Description |
|---------|----------|------|-------------|
| **api** | Python | 8080 | Shortens URLs, handles redirects, tracks clicks, publishes events to SQS |
| **worker** | Go | - | Polls SQS for click events, writes analytics to PostgreSQL |
| **dashboard** | Go | 8081 | Analytics API - top URLs, click stats, hourly breakdowns, recent events |

### 2a. Networking
For this project, I created a VPC across 2 availibilty zones: with 2 public and 2 private subnets. This is so that we can have high availibility, and the private subnets were created seperated from the public subnets so that our AWS services dont have internet access by default; keeping them secure and protected against unauthorised access and direct exposure to the public internet.

All of the ECS services run in private subnets, with no public IP. This is cheaper, but it also creates a networking challenge: how will the containers pull their docker images from Amazon ECR without access to the internet?

![VPC endpoint in terraform](images/VPC-endpoints.png)

Private VPC endpoints were used to provide private access to the required AWS services without allowing public internet access (Interface endpoints were used). Using VPC endpoints reduces our NAT gateway cost (another Engineering decision to reduce cost).

security groups: security groups were used throughout to make sure that each service had __least privilege__. Components were allowed to do only their job and nothing more.

### 2b. Compute using ECS and ECS Fargate
We created an ECS cluster to host our 3 app services (api, worker, dashboard). I used ECS task definitions to define the desired number of applications that should run, for example the API service has a desired task count of 1: if it stops; ECS starts a replacement.

AWS Fargate was used to manage the underlying compute infrastructure -> this means we dont have to create the EC2 instances ourselves and manage their operating systems, patch servers, etc. with ECS Fargate; you only need to specify the resources that the container needs such as CPU and memory; and AWS ECS fargate runs the rest.

#### Setting up rolling deployments (ZERO DOWNTIME)
I configured ECS for rolling deployments; this means in a new deployment, old containers will be replaced one by one with newer versions without taking the application offline.

The configuration uses:
- Minimum healthy capacity: 100% — ECS aims to keep the existing healthy tasks running at 100% while deploying the new version.
- Maximum deployment capacity: 200% — ECS can temporarily run additional tasks during a deployment, allowing new tasks to start before old ones are stopped.
- Deployment circuit breaker with automatic rollback — if a deployment fails to reach a healthy state, ECS can roll back to the previous deployment.

### 2c. Traffic Routing
Incoming traffic is filtered through a Web Application Firewall (WAF); to block malicious HTTP/HTTPS requests before they reach the application, next they are routed using an ALB(application load balancer) to the appropriate targets. Host based routing is used to route the root domain (https://ecs-link-shortener-project) to the API, whilst (dashboard.ecs-link-shortener-project.com) routes to the dashboard.

Health checks determine whether the backend targets are healthy enough to recieve traffic.

![simple diagram denoting traffic flow](images/Traffic-routing.png)

### 2d. Messaging - SQS
Amazon SQS (Simple Queue Service) is a managed message queue. It allows for tasks to be done in the background without affecting the main application experience. 

When people click a link: we want analytics to be recorded, BUT it would be distruptive to make the user wait till the analytics are written to PostgreSQL. Instead we made an SQS queue to seperate the immediate redirect (to the shortened links URL), from the background task (writing analytics to the database).

After the click even has been published to SQS, the worker task waits for it and processes it accordingly (Go worker application service).

SQS gives us three benefits: Faster responses (to redirected URL), decoupling the API and worker, and Buffering; if clicks arrive faster than the worker processes them, the SQS queue holds the messages, waiting for the worker.

### 2e. Database using RDS PostgreSQL
Our database is  hosted using Amazon RDS, which is a fully managed relational databse service. [The engineering decision for why RDS was chosen was explained in this section](#3-engineering-decision-why-was-rds-postgresql-chosen).

### 2f. Caching using ElastiCache Redis
In order to store frequenctly accessed data, Amazon Elasticache Redis was used. This allows for the application to retrieve it faster than repeatedly fetching it from the main database. 

Redis is the caching layer between the API and the PostgreSQL Database. 

This improves performance; the cached data can be served quickly rather than fetching from the database each time, It reduces load on the database; if something is frequently accessed, it doesnt need to be retrieved every time from the database, and lastly; AWS manages the infrastructure (it is a fully managed service).

### 2g. Amazon ECR and logging
All 3 aplicaiton services are containerised using Docker, these docker images are stored in Amazon ECR (Elastic Container Registry). The ECS task definitions reference images stored in ECR.

![The 3 container registires in ECR](images/ECR-repos.png)

3 cloudwatch log groups were made in terraform; these send their logging outputs to the corresponding log group (using awslogs logging driver).

![3 Logging groups](images/Cloudwatch-log-groups.png)

### 2h. IaC using Terraform
Instead of using the AWS console to create these above resources, I used Terraform to implement them in an IAC (Infrastructure as Code) fashion.

The resources were defined in configuration files, and terraform uses those files to create the infra when needed.

The flow to set up this infrastructure using Terraform is the following:

__terraform plan__ [shows planned changes before applying] -> __terraform apply__ [will ask for confirmation then create or update the infra according to the configuration]

#### Terraform Remote State
I configured an S3 bucket for Terraform to use as its remote state. The S3 bucket was configured with:
- Versioning
- Encryption
- S3 Lockfile
This allows terraform to safely store its tfstate outside of my local machine. S3 is also encrypted at rest, and the lockfile mechanism prevents concurrent state operations.

### 2i. Security and IAM
#### IAM (Identity and Access Management)
Controls which users and services can access AWS resources and what actions they can perform. 

I used IAM roles for ECS tasks and Github Actions:
- to allow ECS to perform actions from ECR, send logs, etc.
- Application task roles, to give the 3 app services the permissions they need to access AWS resources.
- Github Actions role; to allow the CI/CD pipeline to deploy to AWS without storing long lived AWS access keys in github.

#### GitHub Actions OIDC
OpenID connect (OIDC) allows Github Actions to be authenticated with AWS; instead of storing long lived credentials in GitHub Secrets, GitHub Actions gains a temporary credentials using an IAM role. This reduces the risk associated with long lived credentials being leaked.

#### Least Privilege
Throughout the project, each role was only given the permissions it needed to complete its job.

For example the worker needs access to the SQS queue; but not more.

#### Secrets
Task definitions recieve their database connection string from AWS secrets manager, rather than hardcoding it.

#### Network Security
Another security aspect is that private subnets, security groups, and VPC endpoints were used to limit exposure to the public internet.

## 3. ENGINEERING DECISION: Why was RDS PostgreSQL chosen?
I chose Amazon RDS because it is a FULLY MANAGED; relational; postgreSQL based database service. Rather than Amazon DynamoDB (which is non relational). Because it is fully managed, it reduces our burden of backups, infrastructure provisioning, etc.

My data is in a relational format: the main data ill be storing is shortened URLs and click events, these would BENEFIT from being stored in a table (relational data structure) rather than a non relational database structure. Our data will be in a relational structure: one URL can have multiple clicks: these would make sense to be stored in a table format, which can then be queried using their keys.

In addition to this, our dashboard calculates top URLs (number of clicks), PostgreSQL allows us to query the data using joins, aggregations and grouping: rather than having to structure the query in terms of a specific key structure in advance.

Trade Offs: DynamoDB can be very fast; but complex queries may require additional data modelling.

Overall RDS would be the best fit for this project.

## 4. Docker
I used Docker to containerise each applicaiton: API, Worker, and Dashboard. Each service has its own dockerfile to define its image, dependencies, application code, and startup commands.

This allows each sertivce to run consistently accross different environments.

You can build the docker images locally using __docker compose up --build__

Once Built, the docker images are pushed to Amazon ECR to store them using Github actions.

Next ECS fargate pulls the images from ECR and runs the containers.

## 5. CI/CD
GitHub Actions were used to automate the testing, integration and deployment of our app. I configured this by writing 2 workflows: 1 for CI and one for CD: I wrote both workflows from scratch in yaml.

### How it works:
When changes are pushed to the main branch, the CI pipeline builds and tests the application services, then builds docker images and pushed them to ECR using commit specific SHA tags, and a latest tag.

![The CI workflow: Build then push to ECR](images/CI.png)

![Build steps](images/Build.png)
![Publishing the build to ECR steps](images/publish-to-ECR.png)

After this, the CD pipeline deploys the updated task definitions to ECS Fargate and waits for serives to become stable.

![CD deployment steps](images/CD-deploy.png)

Once the new versions of the app have been pushed to ECS Fargate; ECS uses Rolling Deployments to replace existing tasks with new ones.

### Full Deployment workflow
Here is the full deployment workflow from the moment the code is pushed and merged:
### CI
1. Code Merged, the new application code is pushed merged and into main.
2. When code merged into main; the CI.yml workflow is triggered. When ci.yml starts to run, it checks out the code, sets up python and go, and downloads all dependencies.
3. Next; Python, The Dashboard, and Worker applications are tested: using pytest and go test; respectively.
4. If these pass, then the app docker images are made. Which leads onto the next job in ci.yml : publishing to ecr
5. Once the app has passed all tests, it is pushed to Amazon ECR (Elastic Container Registry). Where the Images are stored till infrastructure needs to be created. The process for pushing the docker images to ECR is:
 - AWS credentials are verified and authenticated using OIDC. OIDC allows github actions to assume the configured IAM Role and obtain temporary credentials instead of long lived secrets stored in github.
 - Then the images are built and pushed using docker commands (Docker buildx and docker --push).

### CD
6. CD awaits CI to successfully pass, AND: the push to be to __main.__
7. It then checks out the code and configures AWS credentials using OIDC again (to ensure long lived credentials are not saved to github).
8. Then we use the __base commit__ to check which files have changed.
9. I used filters / logic to check which file has changed:

![Detecting changes in app using filters in CD.yml](images/detect-changes-cd.png)

10. we need to keep track of which files were changed so that we know whether to recreate the infrastructure or not; if something which doesnt have an effect on the app was changed (like the README.md, then we dont want to recreate all infrastructure again as it would incur costs and is unnecesary).
11. Next the appropriate changed services are redeployed: using a rolling deployment (old services are gradually replaced by new services whilst they become healthy). Only changed services are remade; if nothing has changed then there is no need to redploy.
![Changed services](images/show-changed-services.png)


