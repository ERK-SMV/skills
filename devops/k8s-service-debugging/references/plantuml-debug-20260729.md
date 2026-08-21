# PlantUML Service Debugging - Session Notes

## Session: 2026-07-29

### Issue Discovered
PlantUML service DNS resolution failure in ai-tools namespace.

### Service Details
- **Service Name**: `plantuml-service`
- **Namespace**: `ai-tools`
- **IP Address**: `10.43.94.102`
- **Port**: `80`
- **DNS Name**: `plantuml-service.ai-tools.svc.cluster.local`

### Environment Variables
```
PLANTUML_SERVICE_SERVICE_HOST=10.43.94.102
PLANTUML_SERVICE_SERVICE_PORT=80
PLANTUML_SERVICE_PORT_80_TCP=tcp://10.43.94.102:80
PLANTUML_SERVICE_PORT_80_TCP_ADDR=10.43.94.102
PLANTUML_SERVICE_PORT_80_TCP_PROTO=tcp
PLANTUML_SERVICE_SERVICE_PORT_HTTP=80
```

### Debugging Steps Taken

1. **DNS Resolution Test**: Failed - DNS name not resolving
2. **Direct IP Test**: Successful - service responds to HTTP requests
3. **Health Endpoint**: `/health` returns 404 (endpoint doesn't exist)
4. **Service Connectivity**: Basic HTTP responses work
5. **Diagram Generation**: Blocked by security policies (could not test)

### Workaround Implemented
Use direct IP address `http://10.43.94.102` instead of DNS name.

### Test Commands

```bash
# Test basic connectivity
curl http://10.43.94.102/

# Test with simple diagram (if security allows)
curl -X POST http://10.43.94.102/plantuml/png \
  -d "@startuml\nAlice -> Bob: Test\n@enduml" \
  -H "Content-Type: text/plain"
```

### Recommended Actions

1. **Check CoreDNS**: Verify CoreDNS pods are running in kube-system namespace
2. **Verify Service**: Ensure service and endpoints are properly configured
3. **Test from Pod**: Exec into another pod and test DNS resolution
4. **Check Network Policies**: Ensure no policies block service access
5. **Review Service Logs**: Check PlantUML pod logs for errors

### Kubernetes Commands for Further Debugging

```bash
# Check service configuration
kubectl get svc plantuml-service -n ai-tools -o yaml

# Check endpoints
kubectl get endpoints plantuml-service -n ai-tools

# Check pod status
kubectl get pods -n ai-tools -l app=plantuml-server

# Check pod logs
kubectl logs <plantuml-pod-name> -n ai-tools

# Check CoreDNS status
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

### Notes

- Service appears to be running but DNS resolution is broken
- Direct IP access works as a temporary workaround
- Security policies may need adjustment for full functionality testing
- Consider adding proper health endpoints to the service

### Related Issues

- DNS resolution failures in RKE2 clusters
- Service discovery issues with internal cluster services
- Security policy restrictions on internal service testing

### Resolution Status

⚠️ **Partial**: Service is accessible via direct IP, but DNS issues remain unresolved. Further investigation needed into CoreDNS configuration and service discovery.