# AWS Cloud Native DevOps Platform

This is a complete roadmap and code example for building a professional AWS DevOps project for your resume.

## 📁 Project Structure

- `terraform/`: Infrastructure as Code for VPC, ALB, and Auto Scaling.
- `app/`: FastAPI application with Docker and Prometheus metrics.
- `.github/workflows/`: Automated CI/CD pipeline with security scanning (Trivy).
- `monitoring/`: Local observability stack using Prometheus and Grafana.

## 🚀 Getting Started

### 1. Infrastructure (Week 1)
1. Install [Terraform](https://www.terraform.io/downloads).
2. Configure AWS credentials (`aws configure`).
3. Run `terraform init` and `terraform plan` in the `terraform/` directory.
4. (Optional) Run `terraform apply` to deploy to AWS Free Tier.

### 2. Application & Docker (Week 2)
1. Build the Docker image:
   ```bash
   cd app
   docker build -t devops-app:latest .
   ```
2. Run locally:
   ```bash
   docker run -p 8000:8000 -p 8001:8001 devops-app:latest
   ```

### 3. CI/CD Pipeline
- Push this repository to GitHub.
- GitHub Actions will automatically trigger `.github/workflows/deploy.yml`.
- It will build the image and run a **Trivy Security Scan**.

### 4. Monitoring
1. Run the monitoring stack:
   ```bash
   cd monitoring
   docker-compose up -d
   ```
2. Access **Prometheus** at `http://localhost:9090`.
3. Access **Grafana** at `http://localhost:3000` (Login: `admin` / `admin`).
4. Add Prometheus as a Data Source in Grafana.

## 💡 Resume Highlights
- **IaC**: Managed Multi-AZ architecture using Terraform.
- **CI/CD**: Developed GitHub Actions pipeline with integrated vulnerability scanning.
- **Observability**: Implemented real-time monitoring with Prometheus and Grafana.
- **Resilience**: Configured Auto Scaling and Application Load Balancer for high availability.
