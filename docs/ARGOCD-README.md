# Day 3 GitOps Lab - OpenShift Pipelines & ArgoCD

## 🚨 CRITICAL: Work on YOUR Student Branch

**IMPORTANT**: You must work on YOUR specific student branch for GitOps to function correctly!

## 🚀 Complete Setup Process

### Step 1: Navigate to Day 3 Directory
```bash
cd /home/coder/workspace/labs/day3-gitops
```

### Step 2: Clone YOUR Student Branch
```bash
# ❌ WRONG: git clone https://github.com/kevin-biot/argocd
# ✅ CORRECT: Clone YOUR specific branch
git clone -b student01 https://github.com/kevin-biot/argocd
cd argocd

# 🔍 VALIDATE: Confirm you're on your student branch
git branch --show-current
# Should output: student01
```

### Step 3: Clean Up Previous Day 2 Workshop (If Applicable)
```bash
# Clean any Day 2 artifacts that might conflict
./cleanup-day2.sh
```

### Step 4: Configure Git Credentials (Automatic)
```bash
# This now happens automatically - no manual token entry needed!
./setup-git-credentials.sh
```

### Step 5: Setup Student Pipeline Environment
```bash
# Run the main setup script
./setup-student-pipeline.sh
```

**📝 IMPORTANT**: After running setup script:
- **Read ALL script output completely**
- **Look for any error messages**  
- **Follow the specific "Next steps" it provides**
- **Copy/paste commands from the script output**

### Step 6: Execute Pipeline (Follow Script Output)
The setup script will tell you exactly what to run. Typically:

```bash
cd rendered_student01

# Trigger build
oc create -f buildrun-beta.yaml -n student01

# Trigger pipeline  
oc apply -f pipeline-run.yaml -n student01
```

## 🔍 Monitor Your GitOps Workflow

### Watch Pipeline Progress
```bash
# Monitor pipeline execution
tkn pipelinerun logs -f -n student01

# Check TaskRuns (should be TaskRuns, not CustomRuns!)
oc get taskruns -n student01

# Check BuildRun status
oc get buildruns -n student01
```

### Access ArgoCD UI
1. **URL**: https://openshift-gitops-server-openshift-gitops.apps.bootcamp-ocs-cluster.bootcamp.tkmind.net/

2. **Login Options**:
   - **Student Login**: student01 / DevOps2025!
   - **Admin Login**: admin / [ask instructor for password]

3. **Find Your Application**: Look for `java-webapp-student01`

### Verify Final Deployment
```bash
# Check your deployed application
oc get pods -n student01 -l app=java-webapp

# Get your application URL
oc get route java-webapp -n student01
```

## 🎯 Success Criteria
✅ **Pipeline creates TaskRuns** (not CustomRuns)  
✅ **ArgoCD shows your application** as Synced & Healthy  
✅ **Java webapp** accessible via route  
✅ **GitOps magic**: Pipeline → Git → ArgoCD → Deploy  

## 🔧 Troubleshooting

### Common Issues:
1. **Wrong branch**: Ensure `git branch --show-current` shows `student01`
2. **Pipeline fails**: Check `tkn pipelinerun logs -f -n student01`
3. **Can't see ArgoCD app**: Try admin login or check RBAC
4. **Deployment stuck**: Check ArgoCD sync status

### Get Help:
```bash
# Check everything is working
oc get all -n student01
oc get application java-webapp-student01 -n openshift-gitops
```

## 🎉 What You've Accomplished
- **Built a production CI/CD pipeline** with Tekton
- **Implemented GitOps deployment** with ArgoCD  
- **Experienced modern DevOps workflows** used in enterprise environments
- **Automated the entire code → container → deployment lifecycle**

---
**🚀 Congratulations! You've completed the Day 3 GitOps workshop!**
