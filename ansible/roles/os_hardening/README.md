This README provides a comprehensive overview of the Multi-Tier Secure Infrastructure Deployment project. It covers the architecture, security hardening, monitoring stack, and the CI/CD pipeline used to deploy the application.

 Project Architecture
 The project follows a classic three-tier architecture deployed within a Virtual Private Cloud (VPC) on AWS, ensuring a clear separation of concerns and high security.Core ComponentsBastion Host (Public Subnet): Acts as the secure gateway (Jump Server) for the entire infrastructure. It hosts the Nginx Reverse Proxy, Prometheus, and Grafana.Backend Application (Private Subnet): A FastAPI application running on a private instance. It is shielded from direct internet access.Database Tier (RDS): A managed PostgreSQL instance (Amazon RDS) that stores application data.Security Layers: Multi-level security using AWS Security Groups and host-based firewalls (Firewalld).
 
  Security Hardening
  Security is baked into every layer of the deployment using an os_hardening Ansible role.
  SSH Hardening: Password authentication is disabled in favor of SSH key-based access.
  Firewall Management: firewalld is enabled on all instances, allowing only necessary traffic (Port 22, 80, 3000, 8000, 9090, 9100).
  SELinux: Configured to allow Nginx to connect to the network for reverse proxying.
  Vulnerability Scanning: * Bandit: Scans the Python codebase for security flaws.
    Safety/pip-audit: Scans requirements.txt for known vulnerabilities in dependencies.
  Monitoring & Observability
  A full observability stack is deployed on the Bastion host to monitor the health of the Backend.
  Prometheus: Scrapes hardware metrics from the Backend and health status from the App.
  Node Exporter: Installed on the Backend to provide real-time CPU, RAM, and Disk metrics.
  Grafana: Provides a visual dashboard. A pre-configured "Node Exporter Full" dashboard is provisioned automatically.Alertmanager: (Optional Extension) Configured to send email alerts via SMTP if the Backend instance goes down.
   Deployment Workflow
   The deployment is automated via a GitHub Actions CI/CD pipeline using Ansible.
   1. Infrastructure Provisioning
   -Inventory is dynamically generated or manually defined (e.g., inventory.ini).
   -Ansible connects to the Bastion and Backend to apply configuration.
   2. Application Deployment
   -The FastAPI application is transferred to the Backend.
   -Dependencies are installed "offline" from a wheels directory to ensure consistency.
   -The app is started in the background using Uvicorn.
   3. Reverse Proxy Setup
   -Nginx is installed on the Bastion.
   -A custom proxy configuration routes traffic from http://<Bastion_IP>/ to http://<Backend_IP>:8000.
   Accessing the Project
   Once the pipeline finishes, the services are available at the Bastion's Public IP:
   Service                                       URL
   Main Application                       http://18.119.164.127/
   App Health Check                       http://18.119.164.127/healthz
   Grafana Dashboard                      http://18.119.164.127:3000 
   Prometheus UI                          http://18.119.164.127:9090
   Tech Stack
   -Cloud: AWS (EC2, RDS, VPC)
   -Configuration: Ansible
   -Web Server: Nginx
   -App Framework: FastAPI (Python 3.9)
   -Database: PostgreSQL
   -Monitoring: Prometheus, Grafana, Node Exporter
   -CI/CD: GitHub Actions









                +-----------------------------+
                |       GitHub Actions        |
                |  (CI runner in the cloud)   |
                +-----------------------------+
                         |
                         | 1) Checkout code, run Bandit (local)
                         | 2) Terraform: create Bastion + Backend, RDS, etc.
                         | 3) Download:
                         |      - Python wheels → ./dependencies
                         |      - Node Exporter → ./downloads
                         |
                         | 4) Run Ansible master.yml
                         v
     ===================================================================
                         Ansible Playbook: master.yml
     ===================================================================
                         |
                         |  (uses SSH + key.pem to reach Bastion,
                         |   Bastion then reaches Backend)
                         v
+-------------------------------------------------------------+
|                         BASTION (web)                      |
|            Public subnet, has internet access              |
+-------------------------------------------------------------+
| Roles from master.yml that run here:                       |
|                                                             |
| 1) os_hardening                                             |
|    - Secure OS, firewall, SSH                              |
|                                                             |
| 2) monitoring_server                                        |
|    - Install Prometheus, Grafana, Alertmanager             |
|    - Prometheus scrapes backend:                           |
|        - {{ backend_ip }}:9100 (Node Exporter)             |
|        - {{ backend_ip }}:8000 (FastAPI health)            |
|                                                             |
| 3) nginx_proxy                                              |
|    - Install Nginx                                         |
|    - Proxy public HTTP → http://{{ backend_ip }}:8000      |
|                                                             |
| 4) vulnerability_scanning (delegated tasks)                |
|    - Copy key.pem here                                     |
|    - Install Bandit, Safety                                |
|    - SSH/rsync to backend to pull app code + requirements  |
|    - Run scans and send results back to backend report     |
+-------------------------------------------------------------+
                         ^
                         |  SSH (jump host)
                         |
+-------------------------------------------------------------+
|                         BACKEND (backend)                  |
|           Private subnet, NO direct internet               |
+-------------------------------------------------------------+
| Roles from master.yml that run here:                       |
|                                                             |
| 1) os_hardening                                             |
|    - Secure OS, firewall, SSH                              |
|    - Open app port 8000                                    |
|                                                             |
| 2) db_servers                                               |
|    - Configure DB tier (RDS connection, users, etc.)       |
|                                                             |
| 3) app_servers                                              |
|    - Copy from GitHub runner → backend:                    |
|        - app/                                              |
|        - requirements.txt                                  |
|        - dependencies/  (Python wheels)                    |
|    - Offline pip install using local dependencies/         |
|    - Start FastAPI (uvicorn) on port 8000                  |
|    - Health check /healthz                                 |
|                                                             |
| 4) node_exporter                                            |
|    - Copy Node Exporter tarball from runner → backend      |
|    - Install and run node_exporter on port 9100            |
|                                                             |
| 5) vulnerability_scanning                                   |
|    - Receive unified report /tmp/scan_report.txt           |
|      (written using results gathered from Bastion)         |
+-------------------------------------------------------------+

                ↑                                          ↑
                |                                          |
          External user                             Prometheus on Bastion
          (browser)                                  scrapes Backend
   http://BASTION_PUBLIC_IP/                    (9100 & 8000 via private IP)
        │
        └─> Nginx on Bastion → http://BACKEND_IP:8000




STEP 0 – GITHUB ACTIONS: PREPARE OFFLINE FILES
------------------------------------------------
On the GitHub Actions runner:

1) Download Python dependencies as wheels
   - Step: "Download Pip Wheels"
   - Command:
       pip download --dest ./dependencies ... -r requirements.txt ...

   Result on runner workspace:
   - ./app/                (your app code)
   - ./requirements.txt
   - ./dependencies/       (all Python wheels)


2) Download Node Exporter tarball
   - Step: "Download Node Exporter for Offline Install"
   - Command:
       wget -P downloads/ node_exporter-1.7.0.linux-amd64.tar.gz

   Result on runner workspace:
   - ./downloads/node_exporter-1.7.0.linux-amd64.tar.gz


STEP 1 – RUN ANSIBLE master.yml (from GitHub Actions)
------------------------------------------------------
- GitHub Actions SSHs into Bastion/Backend using key.pem.
- It runs: ansible-playbook -i inventory.ini master.yml ...


STEP 2 – APP DEPLOY (ROLE: app_servers ON BACKEND)
---------------------------------------------------
Role: app_servers
Target: BACKEND (private subnet, no internet)

Tasks:

1) Copy app, requirements, and wheels from *runner* to *backend*:
   - From:    playbook_dir/../app/
              playbook_dir/../requirements.txt
              playbook_dir/../dependencies/
   - To:      /home/ec2-user/app/
              /home/ec2-user/app/requirements.txt
              /home/ec2-user/app/dependencies/

   Effect:
   - Backend now has:
       /home/ec2-user/app/            (code)
       /home/ec2-user/app/requirements.txt
       /home/ec2-user/app/dependencies/   (all wheels)


2) Offline install of Python deps:
   - Command (on backend):
       python3 -m pip install --user --no-index \
         --find-links=/home/ec2-user/app/dependencies/ \
         -r /home/ec2-user/app/requirements.txt

   Key flags:
   - --no-index       → do NOT use internet
   - --find-links     → only use local wheels in dependencies/


STEP 3 – NODE EXPORTER DEPLOY (ROLE: node_exporter ON BACKEND)
--------------------------------------------------------------
Role: node_exporter
Target: BACKEND

Tasks:

1) Copy Node Exporter tarball from *runner* to *backend*:
   - From:
       playbook_dir/../downloads/node_exporter-1.7.0.linux-amd64.tar.gz
   - To:
       /tmp/node_exporter.tar.gz  (on backend)


2) Extract and install:
   - Extract /tmp/node_exporter.tar.gz under /tmp
   - Copy binary to /usr/local/bin/node_exporter
   - Create systemd service and start it
   - Open port 9100 in firewalld

   Result:
   - Backend exposes metrics at: http://BACKEND_IP:9100/metrics
   - No internet needed on backend


SUMMARY FLOW (OFFLINE PATH ONLY)
--------------------------------
GitHub Actions runner
  ├─ downloads all Python wheels → ./dependencies/
  ├─ downloads Node Exporter tarball → ./downloads/
  └─ runs Ansible master.yml
        │
        └─ Role: app_servers (BACKEND)
              ├─ copy app + requirements.txt + dependencies/ → backend
              └─ pip install using ONLY local dependencies/

        └─ Role: node_exporter (BACKEND)
              ├─ copy node_exporter*.tar.gz → backend
              └─ extract + install + run node_exporter





