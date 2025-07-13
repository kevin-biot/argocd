#!/bin/bash
# ------------------------------------------------------------------
# Day 3 Student Cleanup Script
# Cleans only resources students have permissions to delete
# ------------------------------------------------------------------

set -euo pipefail

# Get the current user's namespace (assumes student01, student02, etc.)
STUDENT_NS=$(oc whoami | sed 's/system:serviceaccount://g' | cut -d':' -f1)

echo "🧹 Cleaning Day 2 resources in namespace: $STUDENT_NS"

# Delete Tekton Pipelines and PipelineRuns
echo "🗑 Deleting Tekton pipelines and runs..."
oc delete pipelinerun --all -n $STUDENT_NS --ignore-not-found || true
oc delete pipeline java-webapp-pipeline -n $STUDENT_NS --ignore-not-found || true

# Delete Tekton Tasks (Day 2 namespaced tasks only)
echo "🗑 Deleting Day 2 Tekton tasks..."
oc delete task shipwright-trigger -n $STUDENT_NS --ignore-not-found || true
oc delete task update-manifests -n $STUDENT_NS --ignore-not-found || true

# Delete Shipwright Builds and BuildRuns
echo "🗑 Deleting Shipwright builds..."
oc delete buildrun --all -n $STUDENT_NS --ignore-not-found || true
oc delete build java-webapp-build -n $STUDENT_NS --ignore-not-found || true

# Delete Java webapp resources
echo "🗑 Deleting Java webapp resources..."
oc delete deployment java-webapp -n $STUDENT_NS --ignore-not-found || true
oc delete svc java-webapp -n $STUDENT_NS --ignore-not-found || true
oc delete route java-webapp -n $STUDENT_NS --ignore-not-found || true
oc delete imagestream java-webapp -n $STUDENT_NS --ignore-not-found || true

# Delete RBAC bindings (if students created them)
echo "🗑 Deleting RBAC resources..."
oc delete role pipeline-app-role -n $STUDENT_NS --ignore-not-found || true
oc delete rolebinding pipeline-app-binding -n $STUDENT_NS --ignore-not-found || true

# Delete any ConfigMaps or Secrets created for the pipeline
echo "🗑 Deleting pipeline configs..."
oc delete configmap --selector=app=java-webapp -n $STUDENT_NS --ignore-not-found || true
oc delete secret --selector=app=java-webapp -n $STUDENT_NS --ignore-not-found || true

echo "🔍 Verifying cleanup in namespace $STUDENT_NS..."

# Check what's left (students can only see their own namespace)
echo "🔍 Checking for leftover pipelines..."
oc get pipeline -n $STUDENT_NS | grep java-webapp || echo "✅ No java-webapp pipelines found."

echo "🔍 Checking for leftover builds..."
oc get build -n $STUDENT_NS | grep java-webapp || echo "✅ No java-webapp builds found."

echo "🔍 Checking for leftover deployments..."
oc get deployment -n $STUDENT_NS | grep java-webapp || echo "✅ No java-webapp deployments found."

echo "🔍 Checking for leftover services..."
oc get svc -n $STUDENT_NS | grep java-webapp || echo "✅ No java-webapp services found."

echo "🔍 Checking for leftover routes..."
oc get route -n $STUDENT_NS | grep java-webapp || echo "✅ No java-webapp routes found."

echo "✅ Namespace $STUDENT_NS is clean and ready for Day 3 exercises."
echo "🎯 Instructor will apply Day 3 ClusterTasks before you run your setup script."