# Day 3 Cleanup & Setup Process

This document explains the revised approach for transitioning from Day 2 to Day 3 exercises, addressing student permission limitations.

## Problem
Students don't have cluster-level permissions to:
- Delete/create ClusterTasks
- Delete/create ClusterBuildStrategies  
- List resources across all namespaces
- Delete ArgoCD Applications

## Solution
**Two-script approach**: Separate instructor and student responsibilities based on RBAC permissions.

## Usage

### 1. Instructor Setup (Run First)
```bash
# Run as cluster-admin
./instructor-setup.sh
```

**What it does:**
- Deletes Day 2 ClusterTasks (git-clone, maven-build, war-sanity-check, etc.)
- Deletes Day 2 ClusterBuildStrategies
- Deletes ArgoCD Applications in openshift-gitops
- Applies Day 3 ClusterTasks (git-clone-day3, maven-build, war-sanity-check)
- Applies Day 3 ClusterBuildStrategies
- Verifies cluster readiness

### 2. Student Cleanup (Run After Instructor)
```bash
# Run as student user
./cleanup.sh
```

**What it does:**
- Auto-detects student namespace using `oc whoami`
- Deletes Day 2 resources in student's namespace only:
  - Tekton pipelines and pipeline runs
  - Tekton tasks (namespaced)
  - Shipwright builds and build runs
  - Java webapp deployments, services, routes
  - RBAC roles and bindings
  - ConfigMaps and Secrets
- Verifies namespace cleanup

## Key Features

### Student Script Safety
- **Namespace-scoped only**: No cluster-level operations
- **Auto-detection**: Uses `oc whoami` to determine namespace
- **Permission-aware**: Only attempts operations students can perform
- **Comprehensive cleanup**: Removes all Day 2 artifacts thoroughly

### Instructor Script Efficiency
- **Cluster-scoped focus**: Handles only what students can't
- **Day 3 preparation**: Applies necessary cluster resources
- **Verification**: Confirms readiness before student exercises

## File Structure
```
argocd/
├── cleanup.sh              # Student cleanup script
├── instructor-setup.sh     # Instructor setup script
├── tekton/
│   ├── clustertasks/       # Day 3 ClusterTasks
│   └── tasks/              # Day 3 namespaced tasks
└── shipwright/
    └── buildstrategies/    # Day 3 ClusterBuildStrategies
```

## Execution Order
1. **Instructor** runs `instructor-setup.sh` (cluster-admin required)
2. **Students** run `cleanup.sh` (student permissions sufficient)
3. **Students** proceed with Day 3 exercises

## Benefits
- ✅ Respects RBAC boundaries
- ✅ No permission errors for students
- ✅ Comprehensive cleanup
- ✅ Clear separation of concerns
- ✅ Automated namespace detection
- ✅ Thorough verification steps