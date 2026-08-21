# infra-k8s-manager

## Overview

This skill provides comprehensive guidance for managing your OVH-hosted RKE2 infrastructure. All sensitive information (IPs, tokens, SSH keys, passwords, certificates) is stored in the referenced README files, which are already part of your `2.erk-infra` project.

> **Important**: This project uses **GitLab** for version control, not GitHub. Prioritize `glab` commands which are already installed and configured on this system for GitLab operations.

### Kubernetes Configuration

The `kubectl` tool is installed and configured to interact with the Kubernetes cluster. The `kubeconfig` file is located at `/tmp/kubeconfig` and includes the necessary credentials and server details to communicate with the cluster. The configuration uses service account credentials for authentication.

**KUBECONFIG Location**: `/tmp/kubeconfig`

**Cluster Server**: `https://10.43.0.1:443`

**Authentication**: Service account token

To use `kubectl`, ensure the `KUBECONFIG` environment variable is set:

```bash
export KUBECONFIG=/tmp/kubeconfig
```

This configuration allows you to manage Kubernetes resources, including listing pods, deploying applications, and troubleshooting cluster issues.

### Kubernetes Operations

**List Pods in Namespace**:
```bash
export KUBECONFIG=/tmp/kubeconfig
kubectl get pods -n ai-tools
```

**Get Pod Logs**:
```bash
export KUBECONFIG=/tmp/kubeconfig
kubectl logs <pod-name> -n ai-tools
```

**Describe Resources**:
```bash
export KUBECONFIG=/tmp/kubeconfig
kubectl describe <resource-type> <resource-name> -n ai-tools
```

**Apply Manifests**:
```bash
export KUBECONFIG=/tmp/kubeconfig
kubectl apply -f <manifest-file> -n ai-tools
```

**Delete Resources**:
```bash
export KUBECONFIG=/tmp/kubeconfig
kubectl delete <resource-type> <resource-name> -n ai-tools
```