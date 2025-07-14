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

# Use student namespace as GitHub username for workshop simplicity
# This avoids requiring real GitHub usernames while maintaining functionality
GITHUB_USERNAME="workshop-student-$STUDENT_NAMESPACE"

echo ""
echo "🏷️  Namespace: $STUDENT_NAMESPACE"
echo "👤 Workshop User: $GITHUB_USERNAME (auto-generated)"
echo ""
echo "📋 You'll need a GitHub Personal Access Token (PAT) with 'repo' permissions"
echo "   Create one at: https://github.com/settings/tokens"
echo "   Required scopes: repo (full repository access)"
echo ""

read -rsp "🔐 Enter your GitHub Personal Access Token: " GITHUB_TOKEN
echo ""

[[ -z "$GITHUB_TOKEN" ]] && { echo "❌ GitHub token is required."; exit 1; }

echo ""
echo "🔧 Configuring git for push operations..."

# Configure git user identity
git config --global user.name "Student-$STUDENT_NAMESPACE"
git config --global user.email "$GITHUB_USERNAME@workshop.local"

# Configure git credential storage
git config --global credential.helper store

# Configure git editor and behavior to avoid prompts
git config --global core.editor "true"  # Use 'true' command as editor (no-op)
git config --global merge.tool "false"   # Disable merge tool prompts
git config --global push.default simple  # Simple push behavior
git config --global pull.rebase false    # Default merge behavior for pulls
git config --global init.defaultBranch main  # Set default branch name

# Set environment variables for git operations
export GIT_EDITOR="true"
export GIT_MERGE_AUTOEDIT=no
export GIT_SEQUENCE_EDITOR="true"

# Store the credentials for HTTPS authentication
mkdir -p ~/.git-credentials.d
echo "https://$GITHUB_USERNAME:$GITHUB_TOKEN@github.com" > ~/.git-credentials

# Set git credentials file
git config --global credential.helper "store --file=$HOME/.git-credentials"

# Test git configuration
echo "🧪 Testing git configuration..."
echo "   User Name: $(git config user.name)"
echo "   User Email: $(git config user.email)"
echo "   Credential Helper: $(git config credential.helper)"
echo "   Editor: $(git config core.editor)"
echo "   Push Default: $(git config push.default)"

echo ""
echo "💾 Storing credentials securely in namespace $STUDENT_NAMESPACE..."

# Create or update the secret with both token and username
oc create secret generic git-credentials \
  --from-literal=token="$GITHUB_TOKEN" \
  --from-literal=username="$GITHUB_USERNAME" \
  -n "$STUDENT_NAMESPACE" \
  --dry-run=client -o yaml | oc apply -f -

# Also create a secret for git authentication in pipelines
oc create secret generic git-auth \
  --from-literal=username="$GITHUB_USERNAME" \
  --from-literal=password="$GITHUB_TOKEN" \
  --type=kubernetes.io/basic-auth \
  -n "$STUDENT_NAMESPACE" \
  --dry-run=client -o yaml | oc apply -f -

# Annotate the secret for Tekton
oc annotate secret git-auth tekton.dev/git-0=https://github.com -n "$STUDENT_NAMESPACE" --overwrite

echo "✅ Git credentials configured successfully!"
echo "✅ Kubernetes secrets created in namespace $STUDENT_NAMESPACE"
echo ""
echo "🔄 Your git operations and Tekton pipelines can now:"
echo "   • Push changes to trigger ArgoCD sync"
echo "   • Authenticate with GitHub using your PAT"
echo "   • Maintain proper commit attribution"
echo ""
echo "🧪 Testing git push capability..."
# Quick test to verify git can authenticate (non-destructive)
if git ls-remote https://github.com/kevin-biot/argocd.git HEAD >/dev/null 2>&1; then
    echo "✅ Git authentication test successful!"
else
    echo "⚠️  Git authentication test failed - please verify your PAT token"
fi

echo ""
echo "Next steps:"
echo "1. Run your pipeline to build and update manifests"
echo "2. Check ArgoCD UI to see automatic deployment sync"
echo "3. Access ArgoCD at: https://openshift-gitops-server-openshift-gitops.apps-crc.testing"
echo ""
echo "🔍 Troubleshooting:"
echo "   • Check git config: git config --list"
echo "   • Test git auth: git ls-remote https://github.com/kevin-biot/argocd.git"
echo "   • View secrets: oc get secrets -n $STUDENT_NAMESPACE"
echo ""
echo "🔧 Git Environment Configured:"
echo "   • No editor prompts during commits"
echo "   • No merge tool prompts" 
echo "   • Simple push/pull behavior"
echo "   • All git operations will be non-interactive"
