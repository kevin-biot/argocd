#!/bin/bash
# ------------------------------------------------------------------
# GitOps-Compatible Student Pipeline Setup Script
# Applies only infrastructure resources, lets ArgoCD manage app deployments
# ------------------------------------------------------------------
set -euo pipefail
echo "🔧 Student Pipeline Setup Script (GitOps Mode)"

# ============================================================================
# CRITICAL: Branch Validation First
# ============================================================================
echo "🔍 Validating your branch setup..."
current_branch=$(git branch --show-current 2>/dev/null || echo "no-git")
current_dir=$(basename "$(pwd)" 2>/dev/null || echo "unknown")

echo "   📁 Current directory: ${current_dir}"
echo "   🌿 Current git branch: ${current_branch}"

# Validate directory
if [ "${current_dir}" != "argocd" ]; then
    echo "❌ ERROR: You must run this script from the 'argocd' directory!"
    echo ""
    echo "🔧 Fix this by running:"
    echo "   cd /home/coder/workspace/labs/day3-gitops/argocd"
    echo "   ./setup-student-pipeline.sh"
    exit 1
fi

# Validate git repository
if [ "${current_branch}" = "no-git" ]; then
    echo "❌ ERROR: Not in a git repository!"
    echo ""
    echo "🔧 Fix this by running:"
    echo "   cd /home/coder/workspace/labs/day3-gitops"
    echo "   rm -rf argocd"
    echo "   git clone -b student01 https://github.com/kevin-biot/argocd"
    echo "   cd argocd"
    echo "   ./setup-student-pipeline.sh"
    exit 1
fi

# Detect expected student namespace from git branch
expected_namespace="${current_branch}"

# Validate branch matches expected pattern
if [[ ! "${current_branch}" =~ ^student[0-9]+$ ]]; then
    echo "❌ ERROR: You're on branch '${current_branch}' but should be on a student branch!"
    echo ""
    echo "🔧 Fix this by running:"
    echo "   cd /home/coder/workspace/labs/day3-gitops"
    echo "   rm -rf argocd"
    echo "   git clone -b student01 https://github.com/kevin-biot/argocd  # Use YOUR student ID"
    echo "   cd argocd"
    echo "   ./setup-student-pipeline.sh"
    exit 1
fi

echo "✅ Branch validation passed!"
echo "   📋 Using namespace: ${expected_namespace}"
echo "   🎯 This matches your git branch: ${current_branch}"
echo ""

# ============================================================================
# Setup Configuration
# ============================================================================

# Auto-configure based on git branch
NAMESPACE="${expected_namespace}"
REPO_URL="https://github.com/kevin-biot/argocd.git"

echo "📋 Configuration auto-detected from your git branch:"
echo "   🏷️  Namespace: ${NAMESPACE}"
echo "   📦 Git Repo:  ${REPO_URL}"
echo "   🎯 Mode:      GitOps (ArgoCD manages deployments)"
echo ""
read -rp "❓ Proceed with auto-detected values? (y/n): " CONFIRM
[[ "$CONFIRM" != [yY] ]] && { echo "❌ Aborted."; exit 1; }

DEST_DIR="rendered_${NAMESPACE}"
mkdir -p "$DEST_DIR"

# ---------- Infrastructure resources (applied by script) ----------
INFRASTRUCTURE_FILES=(
  k8s/rbac/pipeline-app-role.yaml
  k8s/rbac/pipeline-app-binding.yaml
  tekton/pipeline-optimized.yaml
  shipwright/build/build-beta.yaml
)

# ---------- GitOps resources (applied by script) ----------
GITOPS_FILES=(
  argocd/application.yaml    # ArgoCD Application - manages deployments
)

# ---------- Tekton tasks (applied per-namespace, converted from ClusterTasks) ----------
TEKTON_TASKS=(
  tekton/tasks/shipwright-trigger-beta.yaml
  tekton/tasks/shipwright-trigger-day3.yaml
  tekton/tasks/update-manifests-day3.yaml
  tekton/tasks/update-manifests-optimized.yaml
)

# ---------- ClusterTasks converted to Tasks (applied per-namespace) ----------
CONVERTED_TASKS=(
  tekton/clustertasks/git-clone-optimized.yaml
  tekton/clustertasks/maven-build-optimized.yaml
  tekton/clustertasks/war-sanity-check-optimized.yaml
  tekton/clustertasks/git-clone-day3.yaml
  tekton/clustertasks/maven-build.yaml
  tekton/clustertasks/war-sanity-check.yaml
)

# ---------- Application resources (rendered only - ArgoCD manages) ----------
APP_FILES_RENDER_ONLY=(
  k8s/deployment.yaml        # ArgoCD will create this
  k8s/service.yaml          # ArgoCD will create this  
  k8s/route.yaml            # ArgoCD will create this
)

# ---------- Pipeline execution files (rendered only - student triggers) ----------
PIPELINE_FILES_RENDER_ONLY=(
  tekton/pvc.yaml
  shipwright/build/buildrun-beta.yaml
  tekton/pipeline-run.yaml
)

ALL_RENDER_FILES=("${INFRASTRUCTURE_FILES[@]}" "${GITOPS_FILES[@]}" "${APP_FILES_RENDER_ONLY[@]}" "${PIPELINE_FILES_RENDER_ONLY[@]}")

echo -e "\n🖨️  Rendering files into: $DEST_DIR"
for f in "${ALL_RENDER_FILES[@]}"; do
  tgt="$DEST_DIR/$(basename "$f")"
  sed -e "s|{{NAMESPACE}}|$NAMESPACE|g" \
      -e "s|{{GIT_REPO_URL}}|$REPO_URL|g" \
      -e "s|{{IMAGE_TAG}}|latest|g" \
      "$f" > "$tgt"
  echo "✅ Rendered: $tgt"
done

echo -e "\n🚀 Applying infrastructure resources:"

# Create ImageStream first (infrastructure)
echo "➡️  Creating ImageStream for namespace: $NAMESPACE"
cat << EOF | oc apply -n "$NAMESPACE" -f -
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  name: java-webapp
  namespace: $NAMESPACE
spec:
  lookupPolicy:
    local: false
EOF

for f in "${INFRASTRUCTURE_FILES[@]}"; do
  base_file=$(basename "$f")
  echo "➡️  Applying $base_file to namespace: $NAMESPACE"
  oc apply -n "$NAMESPACE" -f "$DEST_DIR/$base_file"
done

echo -e "\n🎯 Setting up GitOps (ArgoCD):"

# NEW: Copy rendered application manifests to k8s directory for ArgoCD
echo "📁 Copying rendered manifests to k8s directory..."
cp "$DEST_DIR/deployment.yaml" k8s/
cp "$DEST_DIR/service.yaml" k8s/
cp "$DEST_DIR/route.yaml" k8s/

# Remove any infrastructure files that shouldn't be managed by ArgoCD
rm -f k8s/*imagestream.yaml k8s/pipeline-*.yaml k8s/build*.yaml k8s/rbac/ 2>/dev/null || true

echo "🔄 Committing rendered manifests to git..."
# Check if we're on the student branch, if not switch to it
current_branch=$(git branch --show-current)
if [ "$current_branch" != "$NAMESPACE" ]; then
  echo "📋 Switching to branch: $NAMESPACE"
  git checkout "$NAMESPACE" 2>/dev/null || git checkout -b "$NAMESPACE"
fi

# Stage and commit the k8s manifests
git add k8s/deployment.yaml k8s/service.yaml k8s/route.yaml
if git diff --staged --quiet; then
  echo "ℹ️  No changes to commit - manifests already up to date"
else
  git commit -m "Deploy rendered k8s manifests for $NAMESPACE"
  echo "🚀 Pushing manifests to branch: $NAMESPACE"
  git push origin "$NAMESPACE"
fi

# NOW apply ArgoCD application (after manifests are in git)
for f in "${GITOPS_FILES[@]}"; do
  base_file=$(basename "$f")
  echo "➡️  Applying $base_file to namespace: openshift-gitops"
  oc apply -n openshift-gitops -f "$DEST_DIR/$base_file"
done

echo -e "\n🔧 Applying Tekton tasks (no templating needed):"
for f in "${TEKTON_TASKS[@]}"; do
  echo "➡️  Applying $(basename "$f") to namespace: $NAMESPACE"
  oc apply -n "$NAMESPACE" -f "$f"
done

echo -e "\n🔧 Installing converted ClusterTasks as regular Tasks:"
for f in "${CONVERTED_TASKS[@]}"; do
  echo "➡️  Converting and applying $(basename "$f") to namespace: $NAMESPACE"
  # Convert ClusterTask to Task and apply per-namespace
  sed 's/kind: ClusterTask/kind: Task/' "$f" | oc apply -n "$NAMESPACE" -f -
done

echo -e "\n⏳ Waiting for ArgoCD to sync application..."
sleep 5

# Check ArgoCD application status
echo "🔍 Checking ArgoCD Application status:"
oc get application java-webapp-$NAMESPACE -n openshift-gitops -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Application not ready yet"

# ---------------------- STUDENT COPY-PASTE INSTRUCTIONS ----------------------
cat <<EOF

🎉 GitOps Setup Complete for namespace: $NAMESPACE
📂 Rendered files are in: $DEST_DIR

📋 What was created:
   ✅ Infrastructure: RBAC, ImageStream, Optimized Pipeline, Beta Build
   ✅ ArgoCD Application: java-webapp-$NAMESPACE  
   ✅ Tekton Tasks: All tasks installed per-namespace (Tekton 1.19 compatible)
   ✅ Tekton 1.19 Fix: Converted ClusterTasks to regular Tasks with resolver syntax
   ✅ Resource Optimized: 1000m CPU total (fits in student quota)
   ✅ Shipwright Beta API: v1beta1 with system parameter auto-injection

📋 What ArgoCD will create:
   🎯 Deployment, Service, Route (managed by GitOps)

🌐 Your app will be available at:
      https://\$(oc get route java-webapp -n $NAMESPACE -o jsonpath='{.spec.host}')

================================================================================
📝 COPY-PASTE INSTRUCTIONS: Follow these steps EXACTLY
================================================================================

📝 STEP 1: Navigate to rendered directory

Copy and paste this command:

cd $DEST_DIR

✅ Validate: You should see files like buildrun-beta.yaml, pipeline-run.yaml

ls -la

---

📝 STEP 2: Check ArgoCD Application status

Copy and paste this command:

oc get application java-webapp-$NAMESPACE -n openshift-gitops

✅ Expected output: Should show your ArgoCD application

---

📝 STEP 3: Run complete CI/CD pipeline

Copy and paste these commands ONE BY ONE:

oc delete pipelinerun --all -n $NAMESPACE --ignore-not-found

oc apply -f pipeline-run.yaml -n $NAMESPACE

📝 STEP 4: Monitor pipeline progress

Copy and paste this command to watch pipeline logs:

tkn pipelinerun logs -f -n $NAMESPACE

(This will follow the logs until completion)

---

📝 STEP 5: Access ArgoCD UI to see GitOps magic

🌐 Open ArgoCD Console in your browser:

https://openshift-gitops-server-openshift-gitops.apps.bootcamp-ocs-cluster.bootcamp.tkmind.net

🔑 Login Instructions:
   1. Click "LOG IN VIA OPENSHIFT" button
   2. Username: $NAMESPACE
   3. Password: DevOps2025!

📱 Direct link to YOUR application:

https://openshift-gitops-server-openshift-gitops.apps.bootcamp-ocs-cluster.bootcamp.tkmind.net/applications/openshift-gitops/java-webapp-$NAMESPACE?view=tree&resource=

✅ What you should see in ArgoCD:
   • Application: java-webapp-$NAMESPACE
   • Status: "Synced" (green)
   • Health: "Healthy" (green)
   • Source: Your git branch ($NAMESPACE)
   • Resources: Deployment, Service, Route

💡 Copy these URLs to use in your browser:

echo "ArgoCD Console: https://openshift-gitops-server-openshift-gitops.apps.bootcamp-ocs-cluster.bootcamp.tkmind.net"

echo "Your Application: https://openshift-gitops-server-openshift-gitops.apps.bootcamp-ocs-cluster.bootcamp.tkmind.net/applications/openshift-gitops/java-webapp-$NAMESPACE?view=tree&resource="

---

📝 STEP 6: Verify your deployed application

Copy and paste these commands to check your app:

oc get pods -n $NAMESPACE

oc get route java-webapp -n $NAMESPACE

🌐 Get your application URL:

echo "https://\$(oc get route java-webapp -n $NAMESPACE -o jsonpath='{.spec.host}')"

================================================================================

✅ SUCCESS CRITERIA: Your workshop is successful when:
   ✅ Pipeline completes successfully (pipelinerun shows "Succeeded")
   ✅ ArgoCD shows your application as "Synced" and "Healthy"
   ✅ Your application URL responds with the Java webapp
   ✅ You can login to ArgoCD UI with your student credentials
   ✅ You can see your java-webapp-$NAMESPACE application in ArgoCD

🚨 IMPORTANT REMINDERS:
   • Copy-paste commands ONE BY ONE (don't copy multiple lines at once)
   • Wait for each step to complete before proceeding
   • Use the validation commands to check progress
   • If something fails, re-run from that step

🔧 TROUBLESHOOTING ArgoCD Access:
   
   If you can't see your application in ArgoCD UI:
   1. Verify you logged in with: $NAMESPACE / DevOps2025!
   2. Check application exists via CLI:
      oc get application java-webapp-$NAMESPACE -n openshift-gitops
   3. If application exists but not visible, this is an RBAC issue
      (instructor will address ArgoCD permissions in next update)

📚 GitOps Benefits you just experienced:
   • ArgoCD manages all application deployments automatically
   • Single source of truth (Git repository branch: $NAMESPACE)
   • Automatic drift detection and correction
   • Declarative deployment model

EOF