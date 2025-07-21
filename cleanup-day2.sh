#!/bin/bash
echo "🧹 Cleaning up Day 2 workshop artifacts from namespace..."
NAMESPACE=$(oc config view --minify -o jsonpath='{..namespace}' 2>/dev/null || echo "student01")
echo "   Cleaning namespace: $NAMESPACE"

# Clean up Day 2 java-webapp components
oc delete deployment,service,route,imagestream java-webapp -n $NAMESPACE --ignore-not-found
oc delete pipelinerun,taskrun,buildrun --all -n $NAMESPACE --ignore-not-found

echo "✅ Day 2 cleanup complete - ready for Day 3 GitOps!"
