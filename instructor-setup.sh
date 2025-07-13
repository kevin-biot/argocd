#!/bin/bash
# ------------------------------------------------------------------
# Day 3 Instructor Setup Script
# Handles cluster-scoped resources that students can't manage
# ------------------------------------------------------------------

set -euo pipefail

echo "🔧 INSTRUCTOR: Managing Day 3 cluster-scoped resources..."

# Clean up Day 2 ClusterTasks (only instructor can do this)
echo "🚨 Deleting Day 2 ClusterTasks..."
oc delete clustertask git-clone --ignore-not-found || true
oc delete clustertask maven-build --ignore-not-found || true
oc delete clustertask war-sanity-check --ignore-not-found || true
oc delete clustertask shipwright-trigger --ignore-not-found || true
oc delete clustertask update-manifests --ignore-not-found || true

# Clean up Day 2 ClusterBuildStrategies
echo "🚨 Deleting Day 2 ClusterBuildStrategies..."
oc delete clusterbuildstrategy buildah-shipwright-managed-push --ignore-not-found || true

# Clean up ArgoCD Applications (if instructor manages them)
echo "🚨 Deleting ArgoCD Applications in openshift-gitops..."
oc delete application --all -n openshift-gitops --ignore-not-found || true

# Apply Day 3 Optimized ClusterTasks
echo "🚀 Applying Day 3 Optimized ClusterTasks..."
oc apply -f tekton/clustertasks/git-clone-optimized.yaml
oc apply -f tekton/clustertasks/maven-build-optimized.yaml
oc apply -f tekton/clustertasks/war-sanity-check-optimized.yaml

# Apply Day 3 Beta ClusterBuildStrategies
echo "🚀 Applying Day 3 Beta ClusterBuildStrategies..."
oc apply -f shipwright/buildstrategies/buildah-course-beta.yaml

# Verify Day 3 resources are ready
echo "✅ Verifying Day 3 Optimized ClusterTasks:"
oc get clustertask | grep -E 'git-clone-optimized|maven-build-optimized|war-sanity-check-optimized'

echo "✅ Verifying Day 3 Beta ClusterBuildStrategies:"
oc get clusterbuildstrategy buildah-course-beta

echo "✅ Verifying student namespaces:"
oc get ns | grep '^student'

echo "🎯 Cluster is ready for Day 3. Students can now run their cleanup scripts."