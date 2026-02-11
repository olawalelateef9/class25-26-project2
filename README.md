# Techbleat DevOps MasterClass – FastAPI Demo Application

![Techbleat Login Screen](./docs/1.png)

![Techbleat Landing Screen](./docs/2.png)

## Overview

This project is a **FastAPI-based web application** developed as part of the **Techbleat DevOps MasterClass – Capstone Project II**.

The application provides a simple authentication flow with a login page and a protected dashboard. It is intentionally lightweight and designed to be deployed in a **secure AWS IaaS environment** as part of a DevOps capstone, integrating Infrastructure as Code, CI/CD pipelines, OS hardening, and configuration management.

After successful login, the user is redirected to a welcome page confirming authenticated access.

---

## Application Features

- FastAPI backend
- HTML-based UI (login & dashboard pages)
- Username/password authentication
- Session-based login
- Protected routes
- Logout functionality
- Suitable for deployment behind an AWS Application Load Balancer
- Designed for CI/CD, security scanning, and Ansible-based configuration

---

## Tech Stack

- Python 3.9+
- FastAPI
- Uvicorn
- Jinja2 Templates
- HTML / CSS

---

## Project Structure (Example)

```
.
├── app
│   ├── main.py
│   ├── auth.py
│   ├── templates
│   │   ├── login.html
├── requirements.txt
├── README.md
└── docs
    └── app.png
```

---

## Running the Application Locally

### 1. Clone the repository
```bash
git clone https://github.com/your-org/techbleat-fastapi-demo.git
cd techbleat-fastapi-demo
```

### 2. Create and activate a virtual environment
```bash
python3 -m venv venv
source venv/bin/activate
```

### 3. Install dependencies
```bash
pip install -r requirements.txt
```

### 4. Start the application
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 5. Open in browser
```
http://localhost:8000
```

---


## Demo Credentials

> **For demonstration purposes only**

```
Username: admin
Password: admin
```

⚠️ In production environments:
- Passwords must be hashed
- Credentials should be stored in AWS Secrets Manager or SSM Parameter Store
- Secrets must never be committed to source control

---

## DevOps Capstone Context

This application is designed to be used as part of a **secure DevOps capstone project**, where students will:

- Provision AWS infrastructure using Terraform
- Deploy the app on hardened EC2 instances in private subnets
- Place the app behind an HTTPS Application Load Balancer
- Use Ansible for OS hardening and application deployment
- Implement CI/CD pipelines with:
  - SAST
  - Dependency scanning
  - Secrets scanning
- Connect the app to a PostgreSQL database (Amazon RDS)

---

## License

This project is intended for **educational use** as part of the Techbleat DevOps MasterClass.
