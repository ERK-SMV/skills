---
name: k8s-service-debugging
description: Debug Kubernetes service connectivity and DNS issues.
version: 1.0.0
author: Hermes Agent
tags: [kubernetes, debugging, rke2, services, dns, connectivity, troubleshooting]
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [kubernetes, debugging, rke2, services, dns, connectivity, troubleshooting]
    related_skills: [infra-k8s-manager, kubernetes-deployment]
---

# Kubernetes Service Debugging Guide

## Overview

This skill provides comprehensive debugging techniques for Kubernetes services in RKE2 clusters, focusing on internal service connectivity, DNS resolution issues, and endpoint testing.

## Triggers

Use this skill when:
- Internal Kubernetes services return 404 or connection errors
- DNS resolution fails for cluster services
- Service endpoints are not responding as expected
- Debugging PlantUML, Marp, or other internal services
- Troubleshooting service-to-service communication

## Debugging Workflow

### 1. Verify Service Existence

```bash
# Check if service exists in namespace
kubectl get svc -n <namespace>

# Get detailed service information
kubectl get svc <service-name> -n <namespace> -o yaml
```

### 2. Check Environment Variables

```bash
# Look for service environment variables
env | grep -i <service-name>

# Example for PlantUML service
env | grep -i plantuml
```

### 3. Test Direct IP Connectivity

```bash
# Use environment variables to get service IP
SERVICE_IP=$(echo $PLANTUML_SERVICE_SERVICE_HOST)
echo "Service IP: $SERVICE_IP"

# Test basic connectivity
curl -v http://$SERVICE_IP:
```

### 4. Test DNS Resolution

```bash
# Test DNS resolution
nslookup <service-name>.<namespace>.svc.cluster.local

# Alternative: use dig
dig <service-name>.<namespace>.svc.cluster.local
```

### 5. Test Service Endpoints

```bash
# Test health endpoint (if available)
curl http://$SERVICE_IP/health

# Test actual service endpoint
curl -X POST http://$SERVICE_IP/api/endpoint \
  -d '{"test": "data"}' \
  -H "Content-Type: application/json"
```

## Common Issues and Solutions

### DNS Resolution Failure

**Symptoms**: Service DNS name doesn't resolve, but direct IP works.

**Debugging Steps**:
1. Check CoreDNS pods are running
2. Verify service and endpoint objects exist
3. Test DNS resolution with `nslookup` or `dig`
4. Check `/etc/resolv.conf` for correct DNS configuration

**Solutions**:
- Use direct IP address as workaround
- Check CoreDNS configuration
- Verify service has correct selectors

### Service Not Responding

**Symptoms**: Connection refused or timeout errors.

**Debugging Steps**:
1. Check pod status: `kubectl get pods -n <namespace>`
2. Check pod logs: `kubectl logs <pod-name> -n <namespace>`
3. Verify pod is running and ready
4. Check container ports match service ports

**Solutions**:
- Restart pod if needed
- Check container health probes
- Verify service selectors match pod labels

### 404 Not Found

**Symptoms**: Service responds but returns 404.

**Debugging Steps**:
1. Verify correct endpoint path
2. Check service documentation for available endpoints
3. Test with different HTTP methods (GET vs POST)
4. Check if authentication is required

**Solutions**:
- Use correct endpoint paths
- Add required headers or authentication
- Check API documentation

## Service-Specific Debugging

### PlantUML Service

**Environment Variables**:
```
PLANTUML_SERVICE_SERVICE_HOST=10.43.94.102
PLANTUML_SERVICE_SERVICE_PORT=80
PLANTUML_SERVICE_PORT_80_TCP=tcp://10.43.94.102:80
```

**Testing**:
```bash
# Test basic connectivity
curl http://10.43.94.102/

# Test diagram generation
curl -X POST http://10.43.94.102/plantuml/png \
  -d "@startuml\nAlice -> Bob: Test\n@enduml" \
  -H "Content-Type: text/plain"
```

### Marp CLI Service

**Testing**:
```bash
# Check if Node.js is available
node --version

# Check if Marp is installed
npx marp --version

# Test Marp conversion
npx @marp-team/marp-cli@latest slides.md -o output.pdf
```

## Advanced Debugging Techniques

### Network Connectivity Testing

```bash
# Test port connectivity
nc -zv <service-ip> <port>

# Test with telnet
telnet <service-ip> <port>

# Test with wget
wget -qO- http://<service-ip>:
```

### Service Discovery

```bash
# List all services
kubectl get svc --all-namespaces

# Describe service for details
kubectl describe svc <service-name> -n <namespace>

# Check endpoints
kubectl get endpoints <service-name> -n <namespace>
```

### Pod Debugging

```bash
# Get pod details
kubectl get pod <pod-name> -n <namespace> -o yaml

# Exec into pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash

# Check running processes in pod
kubectl exec <pod-name> -n <namespace> -- ps aux
```

## Troubleshooting Checklist

- [ ] Service exists in namespace
- [ ] Service has correct selectors
- [ ] Pods are running and ready
- [ ] Environment variables are set correctly
- [ ] DNS resolution works (or direct IP used)
- [ ] Service responds to basic HTTP requests
- [ ] Correct endpoints are being used
- [ ] Required headers/authentication are provided
- [ ] Network policies allow access
- [ ] Security policies allow requests

## Best Practices

1. **Use Direct IP for Testing**: When DNS issues occur, use the direct IP from environment variables.

2. **Check Logs First**: Pod logs often contain the most useful debugging information.

3. **Test Simple Cases First**: Start with basic connectivity tests before complex API calls.

4. **Verify Selectors**: Ensure service selectors match pod labels exactly.

5. **Check Resource Limits**: Pods may be crashing due to resource constraints.

6. **Test from Different Pods**: Try accessing the service from different pods to isolate issues.

## Related Skills

- `infra-k8s-manager`: Manage OVH-hosted RKE2 infrastructure
- `kubernetes-deployment`: Kubernetes deployment patterns and best practices
- `architecture-diagram`: Create architecture diagrams for documentation

## References

- Kubernetes Debugging Guide: https://kubernetes.io/docs/tasks/debug-application-cluster/
- RKE2 Documentation: https://docs.rke2.io/
- PlantUML Documentation: https://plantuml.com/
- Marp CLI Documentation: https://github.com/marp-team/marp-cli