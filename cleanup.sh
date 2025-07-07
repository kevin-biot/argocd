#!/bin/bash
# ------------------------------------------------------------------
# Day 3 Admin Cleanup and Bootstrap Script (Full Namespace Cleanup)
# Cleans up all Day 2 artifacts and prepares cluster for Day 3.
# ------------------------------------------------------------------

set -euo pipefail

echo "🚨 Deleting all ClusterTasks..."
oc delete clustertask --all --ignore-not-found || true

echo "🚨 Deleting Day 2 Shipwright ClusterBuildStrategies..."
oc delete clusterbuildstrategy buildah-shipwright-managed-push --ignore-not-found || true

echo "🚨 Deleting all ArgoCD Applications in openshift-gitops..."
oc delete application --all -n openshift-gitops --ignore-not-found || true

echo "🗑 Cleaning all Day 2 resources in student namespaces..."
for ns in $(oc get ns --no-headers | awk '/^student/ {print $1}'); do
  echo "🧹 Namespace: $ns"

  # Delete Tekton pipelines
  oc delete pipeline java-webapp-pipeline -n $ns --ignore-not-found || true

  # Delete Tekton Tasks (Day 2 only)
  oc delete task shipwright-trigger -n $ns --ignore-not-found || true
  oc delete task update-manifests -n $ns --ignore-not-found || true

  # Delete Shipwright builds
  oc delete build java-webapp-build -n $ns --ignore-not-found || true

  # Delete Java webapp resources
  oc delete imagestream java-webapp -n $ns --ignore-not-found || true
  oc delete deployment java-webapp -n $ns --ignore-not-found || true
  oc delete service java-webapp -n $ns --ignore-not-found || true
  oc delete route java-webapp -n $ns --ignore-not-found || true

  # Delete RBAC bindings
  oc delete role pipeline-app-role -n $ns --ignore-not-found || true
  oc delete rolebinding pipeline-app-binding -n $ns --ignore-not-found || true

done

echo "🔍 Verifying cleanup..."
echo "🔍 Checking for leftover ClusterTasks..."
oc get clustertask || echo "✅ No ClusterTasks found."

echo "🔍 Checking for leftover ClusterBuildStrategies..."
oc get clusterbuildstrategy || echo "✅ No ClusterBuildStrategies found."

echo "🔍 Checking for leftover ArgoCD Applications..."
oc get application -n openshift-gitops || echo "✅ No ArgoCD Applications found."

echo "🔍 Checking for leftover Java deployments..."
oc get deployment -A | grep java-webapp || echo "✅ No java-webapp deployments found."

echo "🔍 Checking for leftover pipelines..."
oc get pipeline -A | grep java-webapp-pipeline || echo "✅ No pipelines found."

echo "🚀 Applying Day 3 ClusterTasks from tekton/clustertasks/..."
oc apply -f tekton/clustertasks/git-clone-day3.yaml
oc apply -f tekton/clustertasks/maven-build.yaml
oc apply -f tekton/clustertasks/war-sanity-check.yaml
oc apply -f tekton/tasks/shipwright-trigger-day3.yaml
oc apply -f tekton/tasks/update-manifests-day3.yaml

echo "🚀 Applying Day 3 Shipwright ClusterBuildStrategy..."
oc apply -f shipwright/buildstrategies/buildah-shipwright-managed-push.yaml

echo "✅ Day 3 ClusterTasks:"
oc get clustertask | grep -E 'git-clone|maven|sanity|shipwright|update'

echo "✅ Day 3 ClusterBuildStrategies:"
oc get clusterbuildstrategy

echo "✅ Student namespaces:"
oc get ns | grep '^student'

echo "🎯 Cluster is now fully reset and ready for Day 3 student setup scripts."

