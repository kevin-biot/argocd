#!/bin/bash
# ------------------------------------------------------------------
# Setup GitHub credentials for ArgoCD workshop
# Students run this once on Day 3 to store their GitHub PAT
# ------------------------------------------------------------------
set -euo pipefail

echo "🔑 GitHub Credentials Setup for ArgoCD Workshop"
echo "================================================"

# Use environment variable or prompt
if [[ -z "${STUDENT_NAMESPACE:-}" ]]; then
    read -rp "🧑‍🎓 Enter your student namespace: " STUDENT_NAMESPACE
fi

echo ""
echo "🏷️  Namespace: $STUDENT_NAMESPACE"
echo ""
echo "📋 You'll need a GitHub Personal Access Token (PAT) with 'repo' permissions"
echo "   Create one at: https://github.com/settings/tokens"
echo ""

read -rsp "🔐 Enter your GitHub Personal Access Token: " GITHUB_TOKEN
echo ""

[[ -z "$GITHUB_TOKEN" ]] && { echo "❌ GitHub token is required."; exit 1; }

echo ""
echo "💾 Storing credentials securely in namespace $STUDENT_NAMESPACE..."

# Create or update the secret
oc create secret generic git-credentials \
  --from-literal=token="$GITHUB_TOKEN" \
  -n "$STUDENT_NAMESPACE" \
  --dry-run=client -o yaml | oc apply -f -

echo "✅ Git credentials stored successfully!"
echo "🔄 Your Tekton pipeline can now push changes to trigger ArgoCD sync"
echo ""
echo "Next steps:"
echo "1. Run your pipeline to build and update manifests"
echo "2. Check ArgoCD UI to see automatic deployment sync"
echo "3. Access ArgoCD at: https://openshift-gitops-server-openshift-gitops.apps-crc.testing"
