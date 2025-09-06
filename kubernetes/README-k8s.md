# Playwright Cloud on Standard Kubernetes

This setup adapts the OpenShift deployment for standard Kubernetes clusters.

## Deployment Options

### Option 1: With Ingress Controller (Recommended)
```bash
# Deploy with Ingress (requires NGINX/Traefik ingress controller)
kubectl apply -k kubernetes/

# Update the domain in pw-server-ingress.yaml first:
# Replace "pw-server.your-domain.com" with your actual domain

# Get ingress endpoint
kubectl get ingress pw-server
```

### Option 2: With LoadBalancer Service
```bash
# Deploy core resources
kubectl apply -f openshift/pw-server-deployment.yaml
kubectl apply -f openshift/pw-server-hpa.yaml
kubectl apply -f kubernetes/pw-server-service-loadbalancer.yaml

# Get LoadBalancer IP/endpoint
kubectl get service pw-server-lb
```

### Option 3: With NodePort (Development/Local)
```bash
# Deploy core resources  
kubectl apply -f openshift/pw-server-deployment.yaml
kubectl apply -f openshift/pw-server-hpa.yaml

# Create NodePort service
kubectl patch service pw-server -p '{"spec":{"type":"NodePort","ports":[{"port":3000,"targetPort":3000,"nodePort":30300}]}}'

# Access via: ws://<node-ip>:30300/
```

## Key Differences from OpenShift

| Component | OpenShift | Kubernetes |
|-----------|-----------|------------|
| **Ingress** | Route | Ingress + Controller |
| **TLS** | Automatic edge termination | cert-manager or manual certs |
| **WebSocket** | Built-in support | Requires ingress annotations |
| **Security** | SCC (Security Context Constraints) | Pod Security Standards |

## Usage Examples

### With Ingress
```bash
# Test connection
PW_TEST_CONNECT_WS_ENDPOINT=wss://pw-server.your-domain.com/ npx playwright test
```

### With LoadBalancer  
```bash
# Get external IP first
EXTERNAL_IP=$(kubectl get service pw-server-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
PW_TEST_CONNECT_WS_ENDPOINT=ws://$EXTERNAL_IP:3000/ npx playwright test
```

### With NodePort
```bash
# Get node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
PW_TEST_CONNECT_WS_ENDPOINT=ws://$NODE_IP:30300/ npx playwright test
```

## Prerequisites for Standard Kubernetes

### For Ingress Option:
- NGINX Ingress Controller or Traefik
- cert-manager (for automatic TLS)
- DNS domain pointing to your cluster

### For LoadBalancer Option:
- Cloud provider with LoadBalancer support (AWS ELB, GCP GLB, Azure LB)
- Or MetalLB for bare-metal clusters

### For NodePort Option:
- Node IPs accessible from your client
- Firewall rules allowing port 30300

## Security Considerations

The deployment uses the same security hardening as OpenShift:
- `runAsNonRoot: true`
- `allowPrivilegeEscalation: false`  
- `capabilities: drop: ["ALL"]`
- Sized `/dev/shm` via `emptyDir`

For additional security in Kubernetes:
- Apply Pod Security Standards
- Use Network Policies for egress control
- Consider using a service mesh for mTLS
