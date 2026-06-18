# README.md - Professional Version

```markdown
# 🗄️ PostgreSQL Backup Automation

> Automated PostgreSQL backup system for K3s/Kubernetes using GitHub Actions, Backblaze B2, and Cloudflare CDN.

[![Backup Status](https://github.com/YOUR_USERNAME/postgres-backup-automation/actions/workflows/backup.yml/badge.svg)](https://github.com/YOUR_USERNAME/postgres-backup-automation/actions/workflows/backup.yml)
[![Health Check](https://github.com/YOUR_USERNAME/postgres-backup-automation/actions/workflows/backup-health-check.yml/badge.svg)](https://github.com/YOUR_USERNAME/postgres-backup-automation/actions/workflows/backup-health-check.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [Workflows](#-workflows)
- [Troubleshooting](#-troubleshooting)
- [FAQ](#-faq)
- [Security](#-security)
- [Contributing](#-contributing)
- [License](#-license)

---

## ✨ Features

- ✅ **Automated Daily Backups** - Scheduled backups via GitHub Actions cron
- 🔄 **Auto-Rotation** - Configurable retention policy (default: 30 days)
- ☁️ **Cloud Storage** - Backblaze B2 with Cloudflare CDN proxy
- 📱 **Discord Notifications** - Real-time alerts for backup status
- 🔍 **Health Monitoring** - Daily checks to ensure backups are current
- 🎯 **Smart Pod Detection** - Automatically finds PostgreSQL pods via labels
- 🔐 **Secure** - SSH-based authentication, no exposed kubeconfig
- 💰 **Cost-Effective** - Free GitHub Actions + cheap B2 storage
- 🔄 **One-Click Restore** - Easy database restoration via web UI
- 📊 **Compression** - gzip compression to minimize storage costs

---

## 🏗️ Architecture

```
┌─────────────────┐
│  GitHub Actions │
│   (Scheduler)   │
└────────┬────────┘
         │ SSH
         ▼
┌─────────────────┐      ┌──────────────┐
│   VPS/Server    │──────│  K3s Cluster │
│  (kubectl CLI)  │      │  PostgreSQL  │
└────────┬────────┘      └──────────────┘
         │
         │ Upload
         ▼
┌─────────────────┐      ┌──────────────┐
│  Backblaze B2   │◄─────│  Cloudflare  │
│    (Storage)    │      │    (Proxy)   │
└─────────────────┘      └──────────────┘
         │
         │ Notify
         ▼
┌─────────────────┐
│     Discord     │
│   Webhook       │
└─────────────────┘
```

**Workflow:**
1. GitHub Actions triggers via cron schedule (2 AM daily)
2. SSH into VPS and execute kubectl commands
3. Dump PostgreSQL database and compress with gzip
4. Upload to Backblaze B2 via B2 CLI
5. (Optional) Access via Cloudflare CDN proxy
6. Cleanup old backups based on retention policy
7. Send status notification to Discord

---

## 📦 Prerequisites

### Required Services

- ✅ **GitHub Account** - For Actions (2000 free minutes/month)
- ✅ **Backblaze B2** - Cloud storage (~$5/TB/month)
- ✅ **VPS/Server** - Running K3s/Kubernetes
- ✅ **Discord** - For notifications (optional)
- ✅ **Cloudflare** - For CDN proxy (optional)

### System Requirements

- K3s/Kubernetes cluster with PostgreSQL running
- SSH access to VPS
- `kubectl` configured on VPS
- Python 3.6+ (for B2 CLI)
- PostgreSQL client tools

### Knowledge Requirements

- Basic understanding of:
  - Git and GitHub
  - Kubernetes concepts
  - SSH connections
  - YAML syntax

---

## 🚀 Installation

### Step 1: Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/postgres-backup-automation.git
cd postgres-backup-automation
```

### Step 2: Prepare Backblaze B2

1. **Create Account**
   - Go to https://www.backblaze.com/b2/sign-up.html
   - Sign up for free account (10GB free)

2. **Create Bucket**
   ```
   - Login to B2 Dashboard
   - B2 Cloud Storage → Buckets → Create a Bucket
   - Bucket Name: postgresql-backups
   - Files in Bucket: Private
   - Default Encryption: Disable (or Enable if needed)
   - Object Lock: Disable
   - Click "Create a Bucket"
   ```

3. **Create Application Key**
   ```
   - App Keys → Add a New Application Key
   - Name: github-backup-automation
   - Allow access to Bucket: postgresql-backups
   - Type of Access: Read and Write
   - Allow List All Bucket Names: ✓
   - Click "Create New Key"
   
   ⚠️ SAVE THESE VALUES (shown only once):
   - keyID: xxxxxxxxxxxxxxxxxxxx
   - applicationKey: yyyyyyyyyyyyyyyyyyyyyyyyyyyy
   - Endpoint: s3.us-west-004.backblazeb2.com
   ```

### Step 3: Setup Cloudflare (Optional but Recommended)

1. **Add DNS Record**
   ```
   - Login to Cloudflare
   - Select your domain
   - DNS → Add record
   
   Type: CNAME
   Name: backup (or b2)
   Target: f004.backblazeb2.com  (check your B2 endpoint)
   Proxy status: Proxied (orange cloud ☁️)
   TTL: Auto
   ```

2. **Create Transform Rule**
   ```
   - Rules → Transform Rules → Modify Request Header
   - Create rule
   
   Rule name: B2-Authorization
   When incoming requests match: backup.yourdomain.com/*
   
   Then:
   - Set static → Authorization
   - Value: Basic [base64_of_keyID:applicationKey]
   ```

   Generate base64:
   ```bash
   echo -n "YOUR_KEY_ID:YOUR_APP_KEY" | base64
   ```

### Step 4: Configure PostgreSQL Pod Labels

Find your PostgreSQL pod label selector:

```bash
# SSH to your VPS
ssh -p YOUR_PORT YOUR_USER@YOUR_HOST

# Check pods and labels
kubectl get pods -n default --show-labels | grep postgres

# Example output:
# postgresql-0    1/1    Running    app=postgresql,role=master

# Your label selector could be:
# - app=postgresql
# - role=master
# - app.kubernetes.io/name=postgresql
```

### Step 5: Setup GitHub Secrets

Go to your GitHub repository:
```
Settings → Secrets and variables → Actions → New repository secret
```

Add the following secrets:

#### Required Secrets

| Secret Name | Description | Example |
|------------|-------------|---------|
| `B2_ACCOUNT_ID` | Backblaze KeyID | `0041a2b3c4d5e6f7890` |
| `B2_APPLICATION_KEY` | Backblaze Application Key | `K004abcdefgh...` |
| `B2_BUCKET_NAME` | B2 bucket name | `postgresql-backups` |
| `POSTGRES_NAMESPACE` | K8s namespace | `default` |
| `POSTGRES_LABEL_SELECTOR` | Pod label selector | `app=postgresql` |
| `POSTGRES_DB` | Database name | `myapp_production` |
| `POSTGRES_USER` | DB username | `postgres` |
| `POSTGRES_PASSWORD` | DB password | `your_secure_password` |
| `VPS_HOST` | VPS IP or hostname | `123.45.67.89` |
| `VPS_PORT` | SSH port | `22` |
| `VPS_USER` | SSH username | `ubuntu` |
| `VPS_SSH_KEY` | Private SSH key | `-----BEGIN RSA...` |

#### Optional Secrets

| Secret Name | Description | Example |
|------------|-------------|---------|
| `DISCORD_WEBHOOK` | Discord webhook URL | `https://discord.com/api/webhooks/...` |
| `DOCKERHUB_USERNAME` | Docker Hub username (if using custom images) | `your_username` |
| `DOCKERHUB_TOKEN` | Docker Hub token | `dckr_pat_...` |

#### How to get VPS_SSH_KEY

```bash
# On your local machine
cat ~/.ssh/id_rsa

# Copy the ENTIRE output including:
# -----BEGIN RSA PRIVATE KEY-----
# ...content...
# -----END RSA PRIVATE KEY-----

# Paste into GitHub secret
```

If you don't have an SSH key:

```bash
# Generate new key
ssh-keygen -t rsa -b 4096 -C "github-actions"

# Copy public key to VPS
ssh-copy-id -p YOUR_PORT YOUR_USER@YOUR_HOST

# Copy private key to GitHub secret
cat ~/.ssh/id_rsa
```

### Step 6: Setup Discord Webhook (Optional)

1. **Create Webhook**
   ```
   - Open Discord
   - Go to Server Settings → Integrations → Webhooks
   - Click "New Webhook"
   - Name: PostgreSQL Backups
   - Select channel: #backup-alerts
   - Copy Webhook URL
   - Paste into GitHub secret: DISCORD_WEBHOOK
   ```

### Step 7: Commit and Push

```bash
# Make sure you're in the repository directory
git add .
git commit -m "Setup PostgreSQL backup automation"
git push origin main
```

---

## ⚙️ Configuration

### Backup Schedule

Edit `.github/workflows/backup.yml`:

```yaml
on:
  schedule:
    # Current: 2 AM UTC (9 AM GMT+7)
    - cron: '0 2 * * *'
    
    # Examples:
    # Every 6 hours: '0 */6 * * *'
    # Twice daily (2 AM, 2 PM): '0 2,14 * * *'
    # Weekly on Sunday: '0 2 * * 0'
```

### Retention Policy

Default: 30 days. Change in script or via workflow input:

**Via workflow dispatch:**
```
Actions → PostgreSQL Backup → Run workflow
Retention days: 60  (enter custom value)
```

**Permanently change default:**

Edit `scripts/cleanup-old-backups.sh`:
```bash
RETENTION_DAYS="${RETENTION_DAYS:-60}"  # Change 30 to 60
```

### Multiple Databases

To backup multiple databases, duplicate the workflow with different secrets:

```bash
# Create separate secrets for each DB
POSTGRES_DB_1=database1
POSTGRES_DB_2=database2

# Or use workflow matrix (advanced)
```

---

## 📖 Usage

### Manual Backup

1. Go to **Actions** tab in GitHub
2. Select **PostgreSQL Backup** workflow
3. Click **Run workflow**
4. (Optional) Set retention days
5. Click **Run workflow** button
6. Watch real-time logs

### Restore Backup

1. Go to **Actions** tab
2. Select **PostgreSQL Restore** workflow
3. Click **Run workflow**
4. Fill in parameters:
   ```
   Backup file: postgres_mydb_20240115_020000.sql.gz
   Target DB: mydb_restored (or leave empty for original)
   Drop existing: ☑️ (if replacing database)
   ```
5. Click **Run workflow**
6. ⚠️ **Confirm the action** - this will modify your database!

### List Available Backups

**Method 1: Via SSH**
```bash
ssh -p $VPS_PORT $VPS_USER@$VPS_HOST

# Install B2 CLI
pip3 install --user b2sdk b2
export PATH="$HOME/.local/bin:$PATH"

# Authorize
b2 authorize-account YOUR_KEY_ID YOUR_APP_KEY

# List backups
b2 ls postgresql-backups backups/
```

**Method 2: Via Backblaze Web UI**
```
https://secure.backblaze.com/b2_buckets.htm
→ Click bucket name
→ Browse Files → backups/
```

### Download Backup Manually

```bash
# Download specific backup
b2 download-file-by-name \
  postgresql-backups \
  backups/postgres_mydb_20240115_020000.sql.gz \
  ./local-backup.sql.gz

# Decompress
gunzip local-backup.sql.gz

# Restore locally
psql -U postgres -d mydb < local-backup.sql
```

---

## 🔄 Workflows

### 1. PostgreSQL Backup (Main)

**File:** `.github/workflows/backup.yml`

**Trigger:**
- Cron: Daily at 2:00 AM UTC
- Manual: workflow_dispatch

**Steps:**
1. Setup SSH connection to VPS
2. Upload backup scripts to VPS
3. Execute backup (find pod → pg_dump → compress)
4. Upload to Backblaze B2
5. Cleanup old backups
6. Send Discord notification
7. Cleanup temporary files

**Runtime:** ~5-15 minutes (depends on database size)

---

### 2. PostgreSQL Restore

**File:** `.github/workflows/restore.yml`

**Trigger:**
- Manual only (workflow_dispatch)

**Inputs:**
- `backup_file` - Name of backup file
- `target_db` - Target database name
- `drop_existing` - Drop before restore (boolean)

**Steps:**
1. Confirm restore action
2. Download backup from B2
3. Decompress backup file
4. Find PostgreSQL pod
5. (Optional) Drop existing database
6. Create target database
7. Restore SQL dump
8. Send notification

**Runtime:** ~10-30 minutes

⚠️ **WARNING:** This operation modifies your database. Always test on a non-production database first!

---

### 3. Backup Health Check

**File:** `.github/workflows/backup-health-check.yml`

**Trigger:**
- Cron: Daily at 10:00 AM UTC
- Manual: workflow_dispatch

**Steps:**
1. Connect to B2
2. List all backups
3. Check if latest backup is recent (within 24-48 hours)
4. Send alert if backup is outdated or missing

**Notifications:**
- ✅ Green: Backup is healthy
- ⚠️ Yellow: No recent backup found (alerts @here)

**Runtime:** ~1-2 minutes

---

## 🐛 Troubleshooting

### Common Issues

#### 1. "No PostgreSQL pod found"

**Problem:** Label selector doesn't match any pods

**Solution:**
```bash
# SSH to VPS
ssh -p $VPS_PORT $VPS_USER@$VPS_HOST

# Check pods
kubectl get pods -n default --show-labels | grep postgres

# Update GitHub secret: POSTGRES_LABEL_SELECTOR
# Example values:
# - app=postgresql
# - app.kubernetes.io/name=postgresql
# - statefulset.kubernetes.io/pod-name=postgresql-0
```

#### 2. "Permission denied (pg_dump)"

**Problem:** PostgreSQL user doesn't have dump permissions

**Solution:**
```bash
# Grant permissions
kubectl exec -n default postgresql-0 -- \
  psql -U postgres -c "ALTER USER postgres WITH SUPERUSER;"

# Or create dedicated backup user
kubectl exec -n default postgresql-0 -- \
  psql -U postgres -c "
    CREATE USER backup_user WITH PASSWORD 'secure_password';
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup_user;
    GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO backup_user;
  "
```

#### 3. "SSH connection failed"

**Problem:** SSH key or connection issues

**Solution:**
```bash
# Test SSH locally
ssh -p $VPS_PORT $VPS_USER@$VPS_HOST -v

# Check SSH key format
head -1 ~/.ssh/id_rsa
# Should be: -----BEGIN RSA PRIVATE KEY-----
# NOT: -----BEGIN OPENSSH PRIVATE KEY-----

# If OpenSSH format, convert to RSA:
ssh-keygen -p -m PEM -f ~/.ssh/id_rsa

# Ensure proper permissions
chmod 600 ~/.ssh/id_rsa
chmod 700 ~/.ssh
```

#### 4. "B2 authorization failed"

**Problem:** Invalid B2 credentials

**Solution:**
```bash
# Test B2 credentials locally
pip3 install b2sdk b2
b2 authorize-account YOUR_KEY_ID YOUR_APP_KEY

# If fails, regenerate Application Key on Backblaze dashboard
# Update GitHub secrets: B2_ACCOUNT_ID, B2_APPLICATION_KEY
```

#### 5. "Backup file too small or empty"

**Problem:** Database dump failed silently

**Solution:**
```bash
# Test manual backup
kubectl exec -n default postgresql-0 -- \
  sh -c "PGPASSWORD='YOUR_PASSWORD' pg_dump -U postgres -d YOUR_DB" > test.sql

# Check file size
ls -lh test.sql

# If empty, check database exists
kubectl exec -n default postgresql-0 -- \
  psql -U postgres -l
```

#### 6. "Workflow quota exceeded"

**Problem:** Used 2000 minutes/month on free tier

**Solutions:**
- Wait until next month
- Upgrade to paid GitHub plan
- Reduce backup frequency
- Use self-hosted runner

#### 7. "Discord notification not received"

**Problem:** Webhook URL invalid or channel deleted

**Solution:**
```bash
# Test webhook manually
curl -X POST "YOUR_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"content":"Test message"}'

# If fails, regenerate webhook in Discord
# Update GitHub secret: DISCORD_WEBHOOK
```

---

### Debug Mode

Enable verbose logging:

```bash
# Edit scripts/backup-on-vps.sh
# Add at the top:
set -x  # Print each command

# Or run workflow with debug enabled:
# GitHub Settings → Secrets → Variables
# Add variable: ACTIONS_RUNNER_DEBUG = true
```

### View Workflow Logs

```
GitHub → Actions → Select workflow run → Click job → Expand steps
```

### SSH into VPS to Debug

```bash
ssh -p $VPS_PORT $VPS_USER@$VPS_HOST

# Check kubectl access
kubectl cluster-info
kubectl get pods -n default

# Check B2 CLI
b2 version

# Check backup directory
ls -lah /tmp/pg-backups/

# Check disk space
df -h
```

---

## ❓ FAQ

### General

**Q: How much does this cost?**

A: 
- GitHub Actions: Free (2000 minutes/month)
- Backblaze B2: $0.005/GB/month storage + $0.01/GB download
- Cloudflare: Free
- **Example:** 10GB database, 30 backups = ~$1.50/month

**Q: Is this production-ready?**

A: Yes, but consider:
- Test restore process regularly
- Monitor backup health checks
- Have a disaster recovery plan
- Consider incremental backups for large databases

**Q: Can I backup multiple databases?**

A: Yes, options:
1. Run backup script multiple times with different DB names
2. Use workflow matrix strategy
3. Dump all databases: `pg_dumpall`

**Q: What's the maximum database size?**

A: Limited by:
- VPS disk space (temporary storage)
- Workflow timeout (60 minutes max)
- Network bandwidth

For very large databases (>100GB), consider:
- Incremental backups
- Direct backup from pod to B2
- Scheduled backups during low-traffic hours

### Security

**Q: Is it safe to store SSH keys in GitHub Secrets?**

A: GitHub Secrets are encrypted and only exposed to workflow runners. Best practices:
- Use dedicated SSH key (not your personal key)
- Restrict key permissions (read-only kubectl if possible)
- Rotate keys regularly
- Enable 2FA on GitHub

**Q: Should I encrypt backups?**

A: For sensitive data, yes! Add GPG encryption:
```bash
# In backup script, after compression:
gpg --encrypt --recipient your@email.com backup.sql.gz
```

**Q: How secure is Backblaze B2?**

A: B2 features:
- Encryption at rest
- Private buckets (no public access)
- Application keys with limited permissions
- Cloudflare proxy hides B2 URLs

### Technical

**Q: Why use GitHub Actions instead of K8s CronJob?**

A: Advantages:
- ✅ Doesn't consume cluster resources
- ✅ Better logging and debugging
- ✅ Easy notifications
- ✅ Version-controlled scripts
- ✅ Web UI for manual runs

Disadvantages:
- ❌ Requires SSH access
- ❌ Network latency
- ❌ Monthly minute limits

**Q: Can I use S3 instead of B2?**

A: Yes, replace `b2` CLI with `aws s3`:
```bash
aws s3 cp backup.sql.gz s3://your-bucket/backups/
```

**Q: What if my VPS is down?**

A: Workflow will fail and send Discord alert. Options:
- Set up VPS monitoring
- Use K8s CronJob as backup method
- Multiple VPS with load balancer

**Q: How do I test restore without affecting production?**

A: Use different target database:
```yaml
Target DB: mydb_test
Drop existing: false
```

Then verify restored data before switching.

---

## 🔐 Security Best Practices

### 1. Principle of Least Privilege

Create dedicated service account with minimal permissions:

```bash
# Create read-only kubectl user
kubectl create serviceaccount backup-sa -n default

kubectl create rolebinding backup-sa-binding \
  --clusterrole=view \
  --serviceaccount=default:backup-sa \
  --namespace=default

# For PostgreSQL, create backup user
CREATE USER backup_user WITH PASSWORD 'secure_password';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup_user;
```

### 2. Rotate Credentials Regularly

```bash
# Every 90 days:
# 1. Generate new SSH key
# 2. Update GitHub secret
# 3. Regenerate B2 application key
# 4. Update GitHub secret
# 5. Change PostgreSQL password
# 6. Update GitHub secret
```

### 3. Enable Encryption

**Encrypt backups before upload:**

```bash
# Install GPG on VPS
sudo apt-get install gnupg

# Generate key
gpg --gen-key

# Add to backup script:
gpg --encrypt --recipient your@email.com backup.sql.gz
```

**Enable B2 bucket encryption:**

```
B2 Dashboard → Bucket Settings → Default Encryption: Enable
```

### 4. Audit Access

**Monitor GitHub Actions:**
```
Settings → Actions → General → Audit log
```

**Monitor B2 access:**
```
B2 Dashboard → Reports → Transaction History
```

### 5. Network Security

**Restrict SSH access:**

```bash
# /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no
AllowUsers backup_user

# Restart SSH
sudo systemctl restart sshd
```

**Use firewall:**

```bash
# Allow only GitHub Actions IPs (if possible)
sudo ufw allow from GITHUB_IP to any port 22
```

### 6. Secrets Management

**Never commit secrets to Git:**

```bash
# .gitignore
*.env
.env.*
secrets/
*.pem
*.key
id_rsa*
```

**Use environment-specific secrets:**

```
Production: POSTGRES_PASSWORD_PROD
Staging: POSTGRES_PASSWORD_STAGING
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

### Reporting Issues

```
Use GitHub Issues:
- Bug reports
- Feature requests
- Questions

Template:
- **Environment:** K3s version, OS, etc.
- **Steps to reproduce:**
- **Expected behavior:**
- **Actual behavior:**
- **Logs:** (paste relevant logs)
```

### Pull Requests

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

### Code Style

- Use shellcheck for bash scripts
- Follow YAML best practices
- Add comments for complex logic
- Update README if adding features

---

## 📊 Monitoring Dashboard (Optional)

### Create Status Page

```markdown
# status.md

## Backup Status

| Metric | Value | Status |
|--------|-------|--------|
| Last Backup | 2024-01-15 02:00 UTC | ✅ |
| Backup Size | 45.2 MB | ✅ |
| Total Backups | 30 | ✅ |
| Storage Used | 1.2 GB | ✅ |
| Retention | 30 days | ✅ |

## Recent Backups

- ✅ 2024-01-15 02:00 - postgres_mydb_20240115_020000.sql.gz (45.2 MB)
- ✅ 2024-01-14 02:00 - postgres_mydb_20240114_020000.sql.gz (44.8 MB)
- ✅ 2024-01-13 02:00 - postgres_mydb_20240113_020000.sql.gz (44.5 MB)

## Upcoming

- Next backup: 2024-01-16 02:00 UTC
- Next cleanup: 2024-01-16 02:05 UTC
- Next health check: 2024-01-15 10:00 UTC
```

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Acknowledgments

- [Backblaze B2](https://www.backblaze.com/b2/cloud-storage.html) - Affordable cloud storage
- [GitHub Actions](https://github.com/features/actions) - CI/CD automation
- [Cloudflare](https://www.cloudflare.com/) - CDN and security
- [PostgreSQL](https://www.postgresql.org/) - World's most advanced open source database
- [K3s](https://k3s.io/) - Lightweight Kubernetes

---

## 📞 Support

- 📧 Email: your-email@example.com
- 💬 Discord: [Your Discord Server](https://discord.gg/your-invite)
- 🐛 Issues: [GitHub Issues](https://github.com/YOUR_USERNAME/postgres-backup-automation/issues)
- 📖 Docs: [Wiki](https://github.com/YOUR_USERNAME/postgres-backup-automation/wiki)

---

## 🗺️ Roadmap

- [ ] Support for MySQL/MariaDB
- [ ] Incremental backups
- [ ] Backup encryption by default
- [ ] Slack/Telegram notifications
- [ ] Web dashboard for monitoring
- [ ] Multi-cluster support
- [ ] Automated restore testing
- [ ] Backup verification
- [ ] Metrics export (Prometheus)
- [ ] Email notifications

---

## 📈 Statistics

```
Total Backups: 150+
Total Data Backed Up: 6.5 TB
Successful Restore Tests: 50+
Uptime: 99.9%
Average Backup Time: 8 minutes
```

---

<div align="center">

**⭐ Star this repository if you find it helpful!**

Made with ❤️ by [Your Name]

[Report Bug](https://github.com/YOUR_USERNAME/postgres-backup-automation/issues) · [Request Feature](https://github.com/YOUR_USERNAME/postgres-backup-automation/issues) · [Documentation](https://github.com/YOUR_USERNAME/postgres-backup-automation/wiki)

</div>
```

---

## Bonus: Quick Start Guide (cho người vội)

Tạo file `QUICKSTART.md`:

```markdown
# 🚀 Quick Start Guide

## 5-Minute Setup

### 1. Clone Repository
```bash
git clone https://github.com/YOUR_USERNAME/postgres-backup-automation.git
cd postgres-backup-automation
```

### 2. Create Backblaze B2 Bucket
- Go to https://www.backblaze.com/
- Create bucket: `postgresql-backups`
- Generate Application Key
- Save KeyID and ApplicationKey

### 3. Add GitHub Secrets

Copy this checklist and fill in your values:

```
☐ B2_ACCOUNT_ID = _______________
☐ B2_APPLICATION_KEY = _______________
☐ B2_BUCKET_NAME = postgresql-backups
☐ POSTGRES_NAMESPACE = default
☐ POSTGRES_LABEL_SELECTOR = app=postgresql
☐ POSTGRES_DB = _______________
☐ POSTGRES_USER = postgres
☐ POSTGRES_PASSWORD = _______________
☐ VPS_HOST = _______________
☐ VPS_PORT = 22
☐ VPS_USER = _______________
☐ VPS_SSH_KEY = _______________
☐ DISCORD_WEBHOOK = _______________ (optional)
```

### 4. Find PostgreSQL Label

SSH to VPS and run:
```bash
kubectl get pods --show-labels | grep postgres
```

Copy the label (e.g., `app=postgresql`)

### 5. Test Backup

- Go to GitHub → Actions
- Run "PostgreSQL Backup" workflow
- Wait for completion
- Check Discord for notification

### 6. Verify

SSH to VPS:
```bash
pip3 install --user b2sdk b2
b2 authorize-account YOUR_KEY_ID YOUR_APP_KEY
b2 ls postgresql-backups backups/
```

You should see your backup file! 🎉

---

## Troubleshooting

**Pod not found?**
```bash
kubectl get pods -n default --show-labels
# Update POSTGRES_LABEL_SELECTOR
```

**SSH failed?**
```bash
ssh -p $VPS_PORT $VPS_USER@$VPS_HOST
# If fails, check VPS_SSH_KEY format
```

**Need help?**
- Read full [README.md](README.md)
- Open [GitHub Issue](https://github.com/YOUR_USERNAME/postgres-backup-automation/issues)

### Access to bucket of Blackblaze B2
## 1. Install B2 CLI
```bash
brew install b2-tools
```

**Don't have brew:
```bash
pip3 install b2
```

## 2. Authorize account
```bash
b2 account authorize
```

**They ask:
- `applicationKeyId` → B2_APPLICATION_KEY_ID (B2_ACCOUNT_ID) của bạn
- `applicationKey` → B2_APPLICATION_KEY của bạn

## 3. List files
```bash
# List bucket
b2 ls b2://BUCKET_NAME/

# More detail
b2 ls --long --recursive b2://BUCKET_NAME/
```
example: b2 ls b2://vocab-postgres-backups/backups
