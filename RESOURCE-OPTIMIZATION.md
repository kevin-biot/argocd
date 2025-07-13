# Resource-Optimized Pipeline Tasks

## Overview
This directory contains optimized ClusterTasks designed for the DevOps course environment with 25 students on a 6-worker OpenShift cluster.

## Resource Allocation Strategy

### Student Quota (per namespace)
- **Total CPU Limit**: 4 cores (4000m)
- **Total Memory Limit**: 8Gi
- **Pods**: 15 maximum

### Code-Server Allocation
- **CPU Request**: 300m
- **CPU Limit**: 800m  
- **Memory**: 512Mi request, 1200Mi limit

### Pipeline Resource Budget
- **Available for pipelines**: 4000m - 800m = 3200m CPU
- **Optimized pipeline total**: 550m CPU (fits comfortably)

## Optimized ClusterTasks

### git-clone-optimized
- **CPU**: 50m request, 100m limit
- **Memory**: 64Mi request, 128Mi limit
- **Purpose**: Fast git clone with minimal resources

### maven-build-optimized  
- **CPU**: 200m request, 400m limit
- **Memory**: 512Mi request, 1Gi limit
- **Optimizations**:
  - Maven heap limited to 768m
  - Single threaded builds
  - Skip tests for speed
  - Local repository caching

### war-sanity-check-optimized
- **CPU**: 50m request, 100m limit  
- **Memory**: 64Mi request, 128Mi limit
- **Purpose**: Quick WAR file validation

## Total Pipeline Resources
- **CPU Requests**: 300m (git: 50m + maven: 200m + sanity: 50m)
- **CPU Limits**: 550m (git: 100m + maven: 400m + sanity: 100m)
- **Memory Requests**: 640Mi
- **Memory Limits**: 1256Mi

## Cluster-Wide Capacity
- **6 workers × 4 cores = 24 cores total**
- **25 students × 550m pipeline = 13.75 cores peak**
- **Utilization**: ~57% during peak pipeline activity
- **Safety margin**: 10+ cores available

## Benefits
✅ **Fits in student quotas**: 550m < 3200m available
✅ **Scales to 25 students**: 13.75 cores < 24 cores available  
✅ **Resource efficient**: Optimized Maven settings
✅ **Fast execution**: Reduced memory allocation overhead
✅ **Reliable**: Prevents resource exhaustion

## Usage

### Apply ClusterTasks (Instructor)
```bash
oc apply -f tekton/clustertasks/git-clone-optimized.yaml
oc apply -f tekton/clustertasks/maven-build-optimized.yaml
oc apply -f tekton/clustertasks/war-sanity-check-optimized.yaml
```

### Use in Pipelines (Students)
The optimized pipeline template automatically references these ClusterTasks:
```bash
./setup-student-pipeline.sh  # Uses pipeline-optimized.yaml
```

## Comparison with Original

| Resource | Original | Optimized | Reduction |
|----------|----------|-----------|-----------|
| CPU Limits | 950m | 550m | 42% |
| Memory Limits | ~2.7Gi | 1.25Gi | 54% |
| Pipeline Capacity | 4 concurrent | 7+ concurrent | 75% improvement |

This optimization allows the cluster to handle the full course load of 25 students reliably.