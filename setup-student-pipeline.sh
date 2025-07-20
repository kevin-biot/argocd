#!/bin/bash
# ------------------------------------------------------------------
# GitOps-Compatible Student Pipeline Setup Script
# Applies only infrastructure resources, lets ArgoCD manage app deployments
# ------------------------------------------------------------------
set -euo pipefail
echo "🔧 Student Pipeline Setup Script (GitOps Mode)"

read -rp "🧑‍🎓  Enter student namespace: " NAMESPACE
read -rp "🌐  Enter Git repo URL [default: https://github.com/kevin-biot/argocd.git]: " REPO_URL
REPO_URL=${REPO_URL:-https://github.com/kevin-biot/argocd.git}
[[ -z "$NAMESPACE" ]] && { echo "❌ Namespace is required."; exit 1; }

echo -e "\n📁 Rendering YAMLs for GitOps workflow:"
echo "   🏷️  Namespace: $NAMESPACE"
echo "   📦 Git Repo:  $REPO_URL"
echo "   🎯 Mode:      GitOps (ArgoCD manages deployments)"
read -rp "❓ Proceed with these values? (y/n): " CONFIRM
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

# ---------------------- student instructions ----------------------
cat <<EOF

🎯 GitOps Setup Complete for namespace: $NAMESPACE
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

📌 Next steps for the student:
  1.  cd $DEST_DIR

  2.  Check ArgoCD Application sync status:
        oc get application java-webapp-$NAMESPACE -n openshift-gitops
        
  3.  Trigger a Shipwright build (re-run safe):
        oc delete buildrun --all -n $NAMESPACE --ignore-not-found
        oc create -f buildrun-beta.yaml -n $NAMESPACE

  4.  Kick off the full pipeline (re-run safe):
        oc delete pipelinerun --all -n $NAMESPACE --ignore-not-found
        oc apply  -f pipeline-run.yaml -n $NAMESPACE

🔎 Validate with:
        oc get buildrun -n $NAMESPACE
        oc get pipelinerun -n $NAMESPACE
        tkn pipelinerun list -n $NAMESPACE

🎯 ArgoCD GitOps Workflow:
        ArgoCD UI: https://openshift-gitops-server-openshift-gitops.apps.<your-domain>
        Your ArgoCD Application: java-webapp-$NAMESPACE
        oc get application java-webapp-$NAMESPACE -n openshift-gitops

📝 GitOps Benefits:
   • ArgoCD manages all application deployments
   • Single source of truth (Git repository)
   • Automatic drift detection and correction
   • Declarative deployment model

EOF