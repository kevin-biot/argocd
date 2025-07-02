# DevOps Workshop - Instructor Setup Guide

## Overview

This guide covers the complete instructor setup for the DevOps workshop including cluster preparation, student environment deployment, and pipeline infrastructure setup.

## Prerequisites

**Cluster Requirements:**
- OpenShift 4.10+ cluster with cluster-admin access  
- OpenShift Pipelines (Tekton) operator installed
- OpenShift GitOps (ArgoCD) operator installed  
- Shipwright Build operator installed
- Sufficient cluster resources for multiple students (see capacity planning below)

**Local Tools Required:**
```bash
# Verify these commands are available
oc version
tkn version  
git --version
openssl version
```

## Quick Start Checklist

### 1. Initial Cluster Setup ⚙️

**a) Install Required Operators (via OpenShift Console or CLI):**
```bash
# Install OpenShift Pipelines
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-pipelines-operator
  namespace: openshift-operators
spec:
  channel: latest
  name: openshift-pipelines-operator-rh
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

# Install Shipwright Build
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: shipwright-operator
  namespace: openshift-operators
spec:
  channel: latest
  name: shipwright-operator
  source: community-operators
  sourceNamespace: openshift-marketplace
EOF
```

**b) Create Infrastructure Namespace:**
```bash
oc new-project devops --display-name="DevOps Workshop Infrastructure"
```

### 2. Build Student Environment Image 🏗️

```bash
cd /Users/kevinbrown/code-server-student-image

# Run the comprehensive course setup (requires cluster-admin)
./course-setup.sh /Users/kevinbrown/devops-test/java-webapp

# This script will:
# - Install shared ClusterTasks for all students
# - Install Shipwright ClusterBuildStrategies  
# - Configure RBAC for student access
# - Build the code-server image with all dev tools
```

### 3. Install Shared Pipeline Resources 📋

These ClusterTasks are shared across all student namespaces:

```bash
cd /Users/kevinbrown/devops-test/java-webapp

# Install cluster-wide Tekton tasks
oc apply -f tekton/clustertasks/

# Install cluster-wide Shipwright build strategies
oc apply -f shipwright/build/buildstrategy_buildah_shipwright_managed_push_cr.yaml

# Verify installation
tkn clustertask list | grep -E "(git-clone|maven-build|war-sanity-check)"
oc get clusterbuildstrategy
```

### 4. Deploy Student Environments 👥

**Option A: Basic Deployment (Code-Server Only)**
```bash
cd /Users/kevinbrown/code-server-student-image

# Deploy 20 students with auto-detected cluster domain
./deploy-students.sh -n 20 -d apps.your-cluster.com

# Check deployment status
./monitor-students.sh
```

**Option B: Full Workshop Deployment (Code-Server + OpenShift Console Access)**
```bash
# Deploy with OpenShift console access
./deploy-students.sh -n 20 -d apps.your-cluster.com --console-access --console-password workshop123

# This creates:
# - Code-server environments for each student
# - OpenShift console user accounts  
# - RBAC permissions for their namespace
# - Access to Tekton dashboard
```

### 5. Verify Student Setup ✅

**Test a single student environment:**
```bash
# Test specific student setup
./test-deployment.sh student01

# Check all students
for i in {01..20}; do
  student="student$i"
  echo "Testing $student..."
  oc get pods -n $student
  oc get route -n $student
done
```

## Student Access Information

After deployment, students will have:

### Code-Server Environment
- **URL:** `https://studentXX-code-server.apps.your-cluster.com`
- **Password:** Generated automatically (see `student-credentials.txt`)
- **Workspace:** Pre-configured with all development tools
- **Storage:** 1Gi persistent volume for their work

### OpenShift Console Access (if enabled)
- **Console URL:** `https://console-openshift-console.apps.your-cluster.com`
- **Username:** studentXX (e.g., student01, student02)
- **Password:** workshop123 (or custom password specified)
- **CLI Login:** `oc login https://api.cluster.com:6443 -u studentXX -p workshop123`

### Tekton Dashboard Access
- **URL:** `https://tekton-dashboard.apps.your-cluster.com`
- **Authentication:** Uses OpenShift console credentials

## Workshop Pipeline Setup

### For Each Student Namespace

Students will use the setup script in their environment:

```bash
# Students run this in their code-server terminal
cd workspace
git clone -b dev https://github.com/kevin-biot/devops-workshop.git
cd devops-workshop
./setup-student-pipeline.sh
```

This script:
1. **Prompts for their namespace** (e.g., student01)
2. **Renders all YAML templates** with their namespace
3. **Applies infrastructure resources** (RBAC, ImageStream, Deployment, etc.)
4. **Provides manual steps** for BuildRun and PipelineRun

### Resources Created Per Student

The setup script creates these resources in each student namespace:

**Infrastructure:**
- `pipeline-app-role.yaml` - RBAC permissions
- `pipeline-app-binding.yaml` - Role binding  
- `java-webapp-imagestream.yaml` - Container image registry
- `deployment.yaml` - Application deployment
- `service.yaml` - Internal service
- `route.yaml` - External access

**Tekton Pipeline:**
- `pvc.yaml` - Shared workspace for pipeline steps
- `pipeline.yaml` - Main CI/CD pipeline definition
- `tasks/deploy.yaml` - Deployment task
- `tasks/shipwright-trigger.yaml` - Build trigger task

**Shipwright Build:**
- `build.yaml` - Build configuration
- `buildrun.yaml` - One-time build execution (student applies manually)
- `pipeline-run.yaml` - Pipeline execution (student applies manually)

## Cluster Capacity Planning

### Resource Requirements Per Student

**Code-Server Pod:**
- CPU: 200m request, 1000m limit
- Memory: 1Gi request, 2Gi limit  
- Storage: 1Gi PVC

**Namespace Quota:**
- CPU: 2 cores request, 4 cores limit
- Memory: 4Gi request, 8Gi limit
- Storage: 20Gi total
- Pods: 15 maximum

### Total Cluster Requirements

**For 20 Students:**
- **CPU:** 40 cores request, 80 cores limit
- **Memory:** 80Gi request, 160Gi limit  
- **Storage:** 400Gi (20Gi × 20 students)
- **Pods:** 300 maximum (15 × 20 students)

**Recommended Cluster Size:**
- **Nodes:** 3-5 worker nodes
- **Instance Type:** 8 vCPU, 32Gi RAM per node (AWS m5.2xlarge equivalent)
- **Storage:** Fast SSD with dynamic provisioning

## Troubleshooting Guide

### Common Issues

**1. Student Deployment Failures**
```bash
# Check deployment status
oc get pods -n studentXX
oc describe pod <pod-name> -n studentXX
oc logs deployment/code-server -n studentXX

# Common fixes:
# - Resource quota exceeded: Check cluster capacity
# - Image pull errors: Verify code-server image build
# - PVC issues: Check storage class configuration
```

**2. Pipeline Execution Issues**
```bash
# Check pipeline status
tkn pipelinerun list -n studentXX
tkn pipelinerun logs <pipeline-run-name> -n studentXX

# Check build status  
oc get buildrun -n studentXX
oc logs buildrun/<buildrun-name> -n studentXX

# Common fixes:
# - Missing ClusterTasks: Re-run course-setup.sh
# - RBAC issues: Check service account permissions
# - Git clone failures: Verify repository URL and branch
```

**3. Resource Quota Issues**
```bash
# Check quota status
oc describe resourcequota student-quota -n studentXX
oc get limitrange -n studentXX

# Increase quota if needed:
oc patch resourcequota student-quota -n studentXX --patch='{"spec":{"hard":{"limits.cpu":"6","limits.memory":"12Gi"}}}'
```

**4. Network Access Issues**
```bash
# Check routes and services
oc get routes -n studentXX  
oc get svc -n studentXX
oc get endpoints -n studentXX

# Test connectivity
oc rsh deployment/code-server -n studentXX curl localhost:8080/healthz
```

### Cleanup Commands

**Remove All Student Environments:**
```bash
cd /Users/kevinbrown/code-server-student-image
./deploy-students.sh -n 20 --cleanup
```

**Clean Shared Resources:**
```bash
# Remove ClusterTasks
oc delete clustertask git-clone maven-build war-sanity-check

# Remove infrastructure namespace
oc delete project devops
```

## File Reference

### Critical Files for Students

**Workshop Repository Structure:**
```
/Users/kevinbrown/devops-test/java-webapp/
├── setup-student-pipeline.sh          # Main setup script for students
├── k8s/                               # Kubernetes manifests
│   ├── rbac/                         # RBAC configuration
│   ├── deployment.yaml               # App deployment template
│   ├── service.yaml                  # Service template  
│   └── route.yaml                    # Route template
├── tekton/                           # Pipeline definitions
│   ├── clustertasks/                 # Shared cluster tasks
│   ├── pipeline.yaml                 # Main pipeline template
│   ├── pvc.yaml                      # Workspace PVC template
│   ├── tasks/                        # Custom tasks
│   └── pipeline-run.yaml             # Manual execution template
└── shipwright/                       # Build configuration
    └── build/
        ├── build.yaml                # Build definition template
        └── buildrun.yaml             # Manual build execution template
```

### Student Credentials File

After deployment, check `/Users/kevinbrown/code-server-student-image/student-credentials.txt`:

```
# Student Credentials - [timestamp]
# Format: Student | Code-Server URL | Code-Server Password | Console URL | Console Password | CLI Login

student01 | https://student01-code-server.apps.cluster.com | abc123def456 | https://console-openshift-console.apps.cluster.com | workshop123 | oc login https://api.cluster.com:6443 -u student01 -p workshop123
student02 | https://student02-code-server.apps.cluster.com | xyz789uvw012 | https://console-openshift-console.apps.cluster.com | workshop123 | oc login https://api.cluster.com:6443 -u student02 -p workshop123
...
```

## Workshop Day Checklist

### Pre-Workshop (Day Before)

- [ ] Run complete setup and verify all 20 students can access code-server
- [ ] Test pipeline execution with 2-3 sample students  
- [ ] Verify Tekton dashboard access
- [ ] Prepare backup cluster or scaling plan
- [ ] Print/email student credentials

### Workshop Day

- [ ] Monitor cluster resource usage
- [ ] Have troubleshooting commands ready
- [ ] Monitor student progress through pipeline exercises
- [ ] Be ready to scale resources if needed

### Post-Workshop

- [ ] Export student work if needed
- [ ] Clean up environments: `./deploy-students.sh -n 20 --cleanup`
- [ ] Archive cluster configurations and student feedback

## Support Contacts

- **Cluster Issues:** [Your Cloud Provider Support]
- **Workshop Content:** [Instructor Email]  
- **Code-Server Issues:** Check GitHub issues at code-server repository
- **Pipeline Issues:** Check OpenShift Pipelines documentation

---

**Quick Commands Reference:**

```bash
# Monitor all students
watch 'oc get pods -A -l app=code-server'

# Check cluster resource usage  
oc adm top nodes
oc adm top pods -A

# Emergency scale down
oc scale deployment code-server --replicas=0 -n studentXX

# View pipeline dashboard
open https://tekton-dashboard.apps.your-cluster.com
```