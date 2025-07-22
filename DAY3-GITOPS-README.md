# Day 3: GitOps with ArgoCD Workshop

## 🎯 Workshop Overview
Learn GitOps practices using ArgoCD for automated application deployments. Your pipeline will build, test, and update Kubernetes manifests, while ArgoCD automatically deploys changes.

## 📋 Pre-requisites Verification
Ensure you're in the correct environment:
```bash
pwd  # Should show: ~/workspace/labs/day3-gitops/argocd
git branch  # Should show: * student01 (your assigned number)
oc whoami  # Should show: student01
```

## 🔧 Setup Instructions

### Step 1: Configure Git Credentials
```bash
chmod +x ./setup-git-credentials.sh
./setup-git-credentials.sh
```
**Required:** GitHub Personal Access Token with `repo` permissions  
Create at: https://github.com/settings/tokens

### Step 2: Clean Previous Workshop Data (If Needed)
```bash
chmod +x ./cleanup-day2.sh
./cleanup-day2.sh
```

### Step 3: Setup Student Pipeline
```bash
chmod +x ./setup-student-pipeline.sh
./setup-student-pipeline.sh
```
**Action:** Type `y` when prompted to proceed with auto-detected values.

## 🚀 Pipeline Execution

### Step 4: Navigate to Rendered Directory
```bash
cd rendered_student01
ls -la  # Validate: Should see buildrun-beta.yaml, pipeline-run.yaml
```

### Step 5: Verify ArgoCD Application
```bash
oc get application java-webapp-student01 -n openshift-gitops
```
**Expected:** Application should be listed and healthy.

### Step 6: Trigger Container Build
```bash
# Clean any existing builds
oc delete buildrun --all -n student01 --ignore-not-found

# Start new build
oc create -f buildrun-beta.yaml -n student01

# Monitor build progress
oc get buildrun -n student01 -w
```
**Wait:** Until status shows "Succeeded" (press Ctrl+C to stop watching)

### Step 7: Trigger Pipeline
```bash
# Clean any existing pipeline runs
oc delete pipelinerun --all -n student01 --ignore-not-found

# Start pipeline
oc apply -f pipeline-run.yaml -n student01

# Monitor pipeline
oc get pipelinerun -n student01
```

### Step 8: Monitor Pipeline Logs
```bash
tkn pipelinerun logs -f -n student01
```
**Action:** Follow logs until completion.

## 🌐 ArgoCD Console Access

### Login to ArgoCD UI
1. **Open ArgoCD Console:**
   ```
   https://openshift-gitops-server-openshift-gitops.apps.bootcamp-ocs-cluster.bootcamp.tkmind.net
   ```

2. **Login Method:** ⚠️ **IMPORTANT**
   - Click **"LOG IN VIA OPENSHIFT"** button
   - **Username:** `student01` (your assigned number)
   - **Password:** `DevOps2025!`

3. **Direct Application Link:**
   ```
   https://openshift-gitops-server-openshift-gitops.apps.bootcamp-ocs-cluster.bootcamp.tkmind.net/applications/openshift-gitops/java-webapp-student01?view=tree&resource=
   ```

### What You Should See in ArgoCD
- ✅ **Application:** `java-webapp-student01`
- ✅ **Status:** "Synced" (green)
- ✅ **Health:** "Healthy" (green)
- ✅ **Source:** Your git branch (student01)
- ✅ **Resources:** Deployment, Service, Route

## 🌐 Verify Deployed Application

### Check Application Status
```bash
# Check running pods
oc get pods -n student01

# Get application route
oc get route java-webapp -n student01

# Get application URL
echo "https://$(oc get route java-webapp -n student01 -o jsonpath='{.spec.host}')"
```

### Access Your Application
Open the URL from the command above in your browser. You should see your Java web application running.

## ✅ Success Criteria

Your workshop is successful when:
- ✅ Build completes successfully (buildrun shows "Succeeded")
- ✅ Pipeline completes successfully (pipelinerun shows "Succeeded") 
- ✅ ArgoCD shows your application as "Synced" and "Healthy"
- ✅ Your application URL responds with the Java webapp
- ✅ You can login to ArgoCD UI with OpenShift authentication
- ✅ You can see your `java-webapp-student01` application in ArgoCD

## 🔧 Troubleshooting

### ArgoCD Access Issues
If you can't see your application in ArgoCD UI:
1. **Verify you used "LOG IN VIA OPENSHIFT"** (not local users)
2. **Check credentials:** `student01` / `DevOps2025!`
3. **Verify application exists:**
   ```bash
   oc get application java-webapp-student01 -n openshift-gitops
   ```

### Build/Pipeline Issues
```bash
# Check build logs
oc logs -f buildrun/java-webapp-buildrun-beta -n student01

# Check pipeline logs  
tkn pipelinerun logs -f -n student01

# Check git configuration
git config --list
```

### Application Issues
```bash
# Check deployment status
oc get deployment java-webapp -n student01

# Check pod logs
oc logs deployment/java-webapp -n student01

# Check service and route
oc get svc,route -n student01
```

## 📚 GitOps Benefits Demonstrated

Through this exercise, you've experienced:
- **Declarative Deployments:** ArgoCD manages all application resources automatically
- **Single Source of Truth:** Git repository branch serves as the definitive state
- **Automatic Drift Detection:** ArgoCD continuously monitors and corrects configuration drift
- **GitOps Workflow:** Code changes → Pipeline → Git commit → ArgoCD sync → Deployment

## 🔄 Making Changes (Advanced)

To see GitOps in action:
1. Modify application code in your git branch
2. Push changes to trigger the pipeline
3. Watch ArgoCD automatically detect and deploy updates
4. Observe zero-downtime deployments and rollback capabilities

## 📞 Getting Help

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all success criteria
3. Ask your instructor for assistance
4. Use the provided CLI commands to debug issues

**Remember:** The key to GitOps is that ArgoCD manages deployments automatically based on your git repository state!

---

## 🎯 Quick Reference Commands

### Copy-paste these URLs for easy access:
```bash
echo "ArgoCD Console: https://openshift-gitops-server-openshift-gitops.apps.bootcamp-ocs-cluster.bootcamp.tkmind.net"
echo "Your Application: https://openshift-gitops-server-openshift-gitops.apps.bootcamp-ocs-cluster.bootcamp.tkmind.net/applications/openshift-gitops/java-webapp-student01?view=tree&resource="
echo "Your App URL: https://$(oc get route java-webapp -n student01 -o jsonpath='{.spec.host}')"
```

### Essential monitoring commands:
```bash
# Watch build progress
oc get buildrun -n student01 -w

# Watch pipeline progress  
tkn pipelinerun logs -f -n student01

# Check ArgoCD application status
oc get application java-webapp-student01 -n openshift-gitops

# Check deployed resources
oc get pods,svc,route -n student01
```