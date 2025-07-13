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
  k8s/java-webapp-imagestream.yaml
  tekton/pipeline-optimized.yaml
  shipwright/build/build.yaml
)

# ---------- GitOps resources (applied by script) ----------
GITOPS_FILES=(
  argocd/application.yaml    # ArgoCD Application - manages deployments
)

# ---------- Tekton tasks (applied directly, no templating) ----------
TEKTON_TASKS=(
  tekton/tasks/update-manifests-day3.yaml
  tekton/tasks/shipwright-trigger-day3.yaml
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
  shipwright/build/buildrun.yaml
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
for f in "${INFRASTRUCTURE_FILES[@]}"; do
  base_file=$(basename "$f")
  echo "➡️  Applying $base_file to namespace: $NAMESPACE"
  oc apply -n "$NAMESPACE" -f "$DEST_DIR/$base_file"
done

echo -e "\n🎯 Setting up GitOps (ArgoCD):"
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
   ✅ Infrastructure: RBAC, ImageStream, Optimized Pipeline, Build
   ✅ ArgoCD Application: java-webapp-$NAMESPACE  
   ✅ Tekton Tasks: update-manifests-day3, shipwright-trigger-day3
   ✅ Resource Optimized: 550m CPU total (fits in student quota)

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
        oc create -f buildrun.yaml -n $NAMESPACE

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