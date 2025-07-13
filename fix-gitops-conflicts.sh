#!/bin/bash
# ------------------------------------------------------------------
# Immediate Fix: Clean up conflicting resources 
# Run this to fix existing deployments that conflict with GitOps
# ------------------------------------------------------------------

set -euo pipefail

# Get the current user's namespace (assumes student01, student02, etc.)
STUDENT_NS=$(oc whoami | sed 's/system:serviceaccount://g' | cut -d':' -f1)

echo "🧹 Cleaning up conflicting resources in namespace: $STUDENT_NS"
echo "This will remove script-created deployments so ArgoCD can manage them properly"

# Remove the deployment/service/route that was created by script
echo "🗑️ Removing script-created application resources..."
oc delete deployment java-webapp -n $STUDENT_NS --ignore-not-found
oc delete service java-webapp -n $STUDENT_NS --ignore-not-found  
oc delete route java-webapp -n $STUDENT_NS --ignore-not-found

# Keep the ArgoCD Application - it should recreate the resources
echo "✅ Keeping ArgoCD Application (will recreate resources via GitOps)"

# Check ArgoCD app status
echo "🔍 Current ArgoCD Application status:"
oc get application java-webapp-$STUDENT_NS -n openshift-gitops 2>/dev/null || echo "ArgoCD Application not found"

echo ""
echo "🎯 What happens next:"
echo "1. ArgoCD will detect the missing resources and recreate them from Git"
echo "2. Check ArgoCD UI to see the sync happening"
echo "3. Once synced, your app will be managed purely by GitOps"
echo "4. Run your pipeline as normal to build and deploy new versions"

echo ""
echo "🔍 Monitor ArgoCD sync status:"
echo "oc get application java-webapp-$STUDENT_NS -n openshift-gitops -w"

echo ""
echo "✅ Cleanup complete! GitOps workflow is now properly configured."