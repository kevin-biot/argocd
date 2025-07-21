# Day 3 GitOps Workshop - Student Repository

## 🚨 CRITICAL: Work on YOUR Student Branch
**IMPORTANT**: You must work on YOUR specific student branch for GitOps to function correctly!

## 🚀 Quick Start Guide

### Step 1: Navigate and Clone YOUR Branch
```bash
cd /home/coder/workspace/labs/day3-gitops
git clone -b student01 https://github.com/kevin-biot/argocd
cd argocd

# Validate you're on YOUR branch
git branch --show-current  # Should show: student01
```

### Step 2: Clean Setup (3 Simple Commands)
```bash
# 1. Clean up any Day 2 artifacts
./cleanup-day2.sh

# 2. Setup git credentials (automatic - no token needed!)
./setup-git-credentials.sh

# 3. Setup your pipeline environment
./setup-student-pipeline.sh
```

### Step 3: Follow Script Output
**📝 IMPORTANT**: After running setup script:
- Read ALL script output completely
- Follow the specific "Next steps" it provides
- Copy/paste commands from the script output

## 📋 What's In This Repository

| File/Directory | Purpose |
|----------------|---------|
| `cleanup-day2.sh` | Removes Day 2 workshop conflicts |
| `setup-git-credentials.sh` | Auto-configures git (embedded token) |
| `setup-student-pipeline.sh` | Main workshop setup script |
| `docs/ARGOCD-README.md` | Complete detailed instructions |
| `k8s/` | Kubernetes manifests for your app |
| `tekton/` | CI/CD pipeline definitions |
| `shipwright/` | Container build configurations |
| `src/` | Java application source code |

## 🎯 Workshop Flow: Pipeline → Git → ArgoCD → Deploy

1. **Pipeline builds** your container image
2. **Pipeline commits** new image tag to YOUR branch
3. **ArgoCD detects** the git change automatically
4. **ArgoCD deploys** your updated application

## 📚 Need Help?
- Check `docs/ARGOCD-README.md` for detailed instructions
- Ask your instructor
- Use troubleshooting commands in the detailed guide

---
**🚀 Goal: Experience modern GitOps workflows used in enterprise environments!**
