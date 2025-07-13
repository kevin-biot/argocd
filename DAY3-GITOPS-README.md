# Day 3 GitOps Setup & Cleanup Process

This document explains the corrected GitOps approach for Day 3 exercises, addressing both RBAC permissions and proper GitOps workflow.

## Problem Fixed
1. **RBAC Issues**: Students don't have cluster-level permissions
2. **GitOps Conflicts**: Setup script was creating deployments directly, conflicting with ArgoCD

## Solution
**Proper GitOps separation**: Infrastructure setup vs Application deployment management

## Scripts Overview

### For Students

#### 1. `cleanup.sh` - Student Cleanup (Run First)
```bash
./cleanup.sh
```
- Cleans Day 2 resources from student's namespace only
- Auto-detects namespace using `oc whoami`
- Permission-safe (no cluster operations)

#### 2. `fix-gitops-conflicts.sh` - Fix Existing Conflicts
```bash
./fix-gitops-conflicts.sh
```
- Removes script-created deployments that conflict with ArgoCD
- Lets ArgoCD become the single source of truth
- Run this if you have existing conflicting resources

#### 3. `setup-student-pipeline.sh` - GitOps Setup (Run After Cleanup)
```bash
./setup-student-pipeline.sh
```
- Creates infrastructure: RBAC, ImageStream, Pipeline, Build
- Creates ArgoCD Application (GitOps controller)
- **Does NOT create deployments** - ArgoCD handles those
- Renders all YAML files for reference

### For Instructors

#### 1. `instructor-setup.sh` - Cluster Admin Setup
```bash
./instructor-setup.sh
```
- Manages cluster-scoped resources (ClusterTasks, ClusterBuildStrategies)
- Run this BEFORE students start their exercises

## Proper GitOps Workflow

### What the Setup Script Creates:
✅ **Infrastructure Resources**:
- RBAC (Roles, RoleBindings)  
- ImageStream
- Tekton Pipeline
- Shipwright Build
- Tekton Tasks

✅ **GitOps Controller**:
- ArgoCD Application pointing to Git repo

### What ArgoCD Creates:
🎯 **Application Resources** (from Git):
- Deployment
- Service  
- Route

### What Students Trigger:
🚀 **Pipeline Execution**:
- BuildRun (builds container image)
- PipelineRun (runs full CI/CD pipeline)

## Step-by-Step Usage

### 1. Instructor Preparation
```bash
# Run as cluster-admin
./instructor-setup.sh
```

### 2. Student Setup Process
```bash
# Step 1: Clean any existing Day 2 resources
./cleanup.sh

# Step 2: Fix any GitOps conflicts (if you have existing deployments)
./fix-gitops-conflicts.sh

# Step 3: Set up GitOps infrastructure
./setup-student-pipeline.sh
# Enter: student01 (or your assigned number)
# Enter: https://github.com/kevin-biot/argocd.git

# Step 4: Verify ArgoCD Application created your deployment
oc get application java-webapp-student01 -n openshift-gitops
oc get deployment java-webapp -n student01

# Step 5: Run pipeline to build and deploy
cd rendered_student01
oc create -f buildrun.yaml -n student01
oc apply -f pipeline-run.yaml -n student01
```

## GitOps Benefits

✅ **Single Source of Truth**: Git repository controls all deployments  
✅ **Drift Detection**: ArgoCD monitors and corrects configuration drift  
✅ **Declarative**: Desired state defined in Git, not imperative commands  
✅ **Audit Trail**: All changes tracked in Git history  
✅ **Rollback**: Easy to revert to previous versions  
✅ **No Conflicts**: Only ArgoCD manages application resources  

## Troubleshooting

### Issue: "Application resources already exist"
**Solution**: Run `./fix-gitops-conflicts.sh` to clean conflicting resources

### Issue: "ArgoCD Application not syncing"
**Check**: 
```bash
oc get application java-webapp-student01 -n openshift-gitops -o yaml
```

### Issue: "Pipeline fails to update deployment"
**Check**: Ensure ArgoCD Application is healthy and synced first

## File Structure
```
argocd/
├── cleanup.sh                    # Student cleanup (namespace-scoped)
├── fix-gitops-conflicts.sh       # Fix existing deployment conflicts  
├── setup-student-pipeline.sh     # GitOps-compatible setup
├── instructor-setup.sh           # Cluster admin setup
├── k8s/                          # Kubernetes manifests
│   ├── deployment.yaml          # Managed by ArgoCD (not script)
│   ├── service.yaml             # Managed by ArgoCD (not script)
│   └── route.yaml               # Managed by ArgoCD (not script)
├── tekton/                       # Pipeline definitions
├── shipwright/                   # Build configurations
└── argocd/                       # ArgoCD Application definitions
```

## Key Differences from Previous Approach

❌ **Old Way**: Script creates everything directly  
✅ **New Way**: Script creates infrastructure, ArgoCD creates apps  

❌ **Old Way**: Multiple sources of truth  
✅ **New Way**: Git is single source of truth  

❌ **Old Way**: Permission errors for students  
✅ **New Way**: Respects RBAC boundaries  

❌ **Old Way**: Resource conflicts  
✅ **New Way**: Clear separation of responsibilities