#!/bin/bash
# ------------------------------------------------------------------
# Render & apply everything a student needs *except* the two
# "one-shot" objects they must run by hand (BuildRun + PipelineRun).
# ------------------------------------------------------------------
set -euo pipefail
echo "🔧 Student Pipeline Setup Script"

read -rp "🧑‍🎓  Enter student namespace: " NAMESPACE
read -rp "🌐  Enter Git repo URL [default: https://github.com/kevin-biot/devops-workshop.git]: " REPO_URL
REPO_URL=${REPO_URL:-https://github.com/kevin-biot/devops-workshop.git}
[[ -z "$NAMESPACE" ]] && { echo "❌ Namespace is required."; exit 1; }

echo -e "\n📁 Rendering YAMLs for:"
echo "   🏷️  Namespace: $NAMESPACE"
echo "   📦 Git Repo:  $REPO_URL"
read -rp "❓ Proceed with these values? (y/n): " CONFIRM
[[ "$CONFIRM" != [yY] ]] && { echo "❌ Aborted."; exit 1; }

DEST_DIR="rendered_${NAMESPACE}"
mkdir -p "$DEST_DIR"

# ---------- files that will be rendered **and** applied ----------
FILES_RENDER_AND_APPLY=(
  k8s/rbac/pipeline-app-role.yaml
  k8s/rbac/pipeline-app-binding.yaml
  k8s/java-webapp-imagestream.yaml
  k8s/deployment.yaml
  k8s/service.yaml
  k8s/route.yaml
  tekton/pipeline.yaml
  shipwright/build/build.yaml
  argocd/application.yaml    # <-- ArgoCD Application for GitOps
)

# ---------- tekton tasks applied directly (no templating) ----------
TEKTON_TASKS=(
  tekton/tasks/update-manifests-day3.yaml
  tekton/tasks/shipwright-trigger-day3.yaml
)
# ---------- rendered only (student applies manually) --------------
FILES_RENDER_ONLY=(
  tekton/pvc.yaml
  shipwright/build/buildrun.yaml
  tekton/pipeline-run.yaml
)

echo -e "\n��️  Rendering files into: $DEST_DIR"
for f in "${FILES_RENDER_AND_APPLY[@]}" "${FILES_RENDER_ONLY[@]}"; do
  tgt="$DEST_DIR/$(basename "$f")"
  sed -e "s|{{NAMESPACE}}|$NAMESPACE|g" \
      -e "s|{{GIT_REPO_URL}}|$REPO_URL|g" \
      -e "s|{{IMAGE_TAG}}|latest|g" \
      "$f" > "$tgt"
  echo "✅ Rendered: $tgt"
done

echo -e "\n🚀 Applying initial resources:"
for f in "${FILES_RENDER_AND_APPLY[@]}"; do
  base_file=$(basename "$f")
  if [[ "$base_file" == "application.yaml" ]]; then
    echo "➡️  Applying $base_file to namespace: openshift-gitops"
    oc apply -n openshift-gitops -f "$DEST_DIR/$base_file"
  else
    echo "➡️  Applying $base_file to namespace: $NAMESPACE"
    oc apply -n "$NAMESPACE" -f "$DEST_DIR/$base_file"
  fi
done

echo -e "\n🎯 Applying Tekton tasks (no templating needed):"
for f in "${TEKTON_TASKS[@]}"; do
  echo "➡️  Applying $(basename "$f") to namespace: $NAMESPACE"
  oc apply -n "$NAMESPACE" -f "$f"
done

# ---------------------- student instructions ----------------------
cat <<EOF

🎯 All YAMLs rendered for namespace: $NAMESPACE
📂 Rendered files are in: $DEST_DIR

🌐 Your app will be available at:
      https://\$(oc get route java-webapp -n $NAMESPACE -o jsonpath='{.spec.host}')

📌 Next steps for the student:
  1.  cd $DEST_DIR

  2.  Trigger a Shipwright build (re-run safe):
        oc delete buildrun --all -n $NAMESPACE --ignore-not-found
        oc create -f buildrun.yaml -n $NAMESPACE

  3.  Kick off the full pipeline (re-run safe):
        oc delete pipelinerun --all -n $NAMESPACE --ignore-not-found
        oc apply  -f pipeline-run.yaml -n $NAMESPACE

🔎 Validate with:
        oc get buildrun -n $NAMESPACE
        oc get pipelinerun -n $NAMESPACE
        tkn pipelinerun list -n $NAMESPACE

🌐 Access your deployed application:
        export APP_URL="https://\$(oc get route java-webapp -n $NAMESPACE -o jsonpath='{.spec.host}')"
        echo "App URL: \$APP_URL"
        curl -k \$APP_URL

🎯 ArgoCD GitOps Workflow:
        ArgoCD UI: https://openshift-gitops-server-openshift-gitops.apps.<your-domain>
        Your ArgoCD Application: java-webapp-$NAMESPACE
        oc get application java-webapp-$NAMESPACE -n openshift-gitops

EOF
