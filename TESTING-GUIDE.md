# ArgoCD Day 3 Workshop - Testing Guide

## Overview
This guide walks through testing the complete ArgoCD integration with your student04 environment.

## Prerequisites ✅
- [ ] Student04 namespace exists and is working
- [ ] Code server running in student04 namespace  
- [ ] GitHub repo created as mirror of original java-webapp
- [ ] Student branches created (student01-student25)
- [ ] OpenShift GitOps (ArgoCD) installed and running

## Testing Steps

### 1. Setup Student Environment
```bash
# In student04 code server:
cd /workspace
mkdir day3-workshop
cd day3-workshop

# Clone your argocd repo
git clone https://github.com/kevin-biot/argocd.git
cd argocd

# Check current branch and switch to student04
git branch -a
git checkout student04
```

### 2. Setup Student Pipeline & ArgoCD
```bash
# Run the enhanced setup script
./setup-student-pipeline.sh
# Enter: student04
# Enter: https://github.com/kevin-biot/argocd.git
# Confirm: y

# Verify ArgoCD application was created
oc get application java-webapp-student04 -n openshift-gitops
```

### 3. Setup Git Credentials
```bash
# Run git credentials setup
./setup-git-credentials.sh
# Enter your GitHub Personal Access Token

# Verify secret was created
oc get secret git-credentials -n student04
```

### 4. Test the Full Pipeline
```bash
cd rendered_student04

# Trigger Shipwright build (creates :latest image)
oc delete buildrun --all -n student04 --ignore-not-found
oc create -f buildrun.yaml -n student04

# Monitor build - IMPORTANT: Wait for build to complete!
oc get buildrun -n student04 -w
# Wait until STATUS shows Succeeded

# Verify the :latest image was created
oc get istag -n student04
# Should show java-webapp:latest

# Once build completes, run pipeline (will retag :latest to commit SHA)
oc delete pipelinerun --all -n student04 --ignore-not-found
oc apply -f pipeline-run.yaml -n student04

# Monitor pipeline
tkn pipelinerun logs -f -n student04
```

### 5. Verify ArgoCD Integration
```bash
# Check ArgoCD application status
oc get application java-webapp-student04 -n openshift-gitops
oc describe application java-webapp-student04 -n openshift-gitops

# Access ArgoCD UI
echo "ArgoCD UI: https://openshift-gitops-server-openshift-gitops.apps-crc.testing"

# Check deployment in student namespace
oc get pods -n student04 -l app=java-webapp
oc get route java-webapp -n student04
```

### 6. Test GitOps Workflow
```bash
# Make a change to trigger ArgoCD sync
echo "<!-- Updated by student04 -->" >> src/main/webapp/index.jsp
git add .
git commit -m "Test change to trigger ArgoCD sync"
git push

# Run pipeline again to update manifests
oc delete pipelinerun --all -n student04 --ignore-not-found
oc apply -f pipeline-run.yaml -n student04

# Watch ArgoCD sync the changes
oc get application java-webapp-student04 -n openshift-gitops -w
```

### 7. Validation Checklist
- [ ] Shipwright build creates java-webapp:latest image
- [ ] Pipeline retags :latest to commit SHA successfully
- [ ] Pipeline updates deployment.yaml with new image tag
- [ ] Pipeline commits and pushes changes to student04 branch
- [ ] ArgoCD detects Git changes automatically
- [ ] ArgoCD syncs deployment to student04 namespace
- [ ] Application is accessible via OpenShift route
- [ ] ArgoCD UI shows healthy application status
- [ ] Multiple image tags exist (latest + commit SHA)

### 8. Common Issues & Troubleshooting

**Issue: Pipeline fails to push to Git**
```bash
# Check git credentials
oc get secret git-credentials -n student04 -o yaml
# Verify GitHub token has repo write permissions
```

**Issue: Pipeline fails with "Source image not found"**
```bash
# Check if Shipwright build completed successfully
oc get buildrun -n student04
oc get istag -n student04
# Should show java-webapp:latest - if not, check BuildRun logs
oc logs buildrun/<buildrun-name> -n student04
```

**Issue: ArgoCD app not syncing**
```bash
# Check ArgoCD application events
oc describe application java-webapp-student04 -n openshift-gitops
# Verify branch exists and has latest changes
git log --oneline -5
```

**Issue: Build fails**
```bash
# Check buildrun logs
oc get buildrun -n student04
oc logs -f buildrun/<buildrun-name> -n student04
```

**Issue: Deployment not updating**
```bash
# Check if image tag was updated in deployment.yaml
git log -p k8s/deployment.yaml
# Verify ArgoCD is pointing to correct branch
oc get application java-webapp-student04 -n openshift-gitops -o yaml | grep targetRevision
```

## Success Criteria ✅
When everything works correctly, you should see:
1. 🔨 Pipeline builds image with commit SHA tag
2. 📝 Pipeline updates deployment.yaml with new tag  
3. 🚀 Pipeline pushes changes to student04 branch
4. 🔄 ArgoCD automatically detects and syncs changes
5. 🌐 Application deployed and accessible
6. 👀 ArgoCD UI shows healthy green status

This validates the complete GitOps workflow for Day 3!
