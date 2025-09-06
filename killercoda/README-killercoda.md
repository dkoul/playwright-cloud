# 🎭 Playwright Cloud on Killercoda Kubernetes Playground

Deploy and test a scalable Playwright cloud on Killercoda's free Kubernetes playground!

## 🚀 Quick Start

### Step 1: Access Killercoda
1. Go to [Killercoda Kubernetes Playground](https://killercoda.com/playgrounds/scenario/kubernetes)
2. Wait for the environment to initialize
3. You'll have a working Kubernetes cluster in your browser!

### Step 2: Deploy Playwright Cloud
```bash
# Clone this repository (or copy files)
curl -O https://raw.githubusercontent.com/your-repo/playwright-cloud/main/killercoda/killercoda-deployment.yaml
curl -O https://raw.githubusercontent.com/your-repo/playwright-cloud/main/killercoda/deploy-killercoda.sh

# Make script executable and run
chmod +x deploy-killercoda.sh
./deploy-killercoda.sh
```

### Step 3: Test the Deployment
```bash
# Option A: Use the included Node.js test
npm install playwright
node test-in-killercoda.js

# Option B: Use your existing Playwright tests
export PW_TEST_CONNECT_WS_ENDPOINT="ws://localhost:3000/"
kubectl port-forward -n playwright-cloud service/pw-server 3000:3000 &
npx playwright test --workers=3
```

## 🏗️ What Gets Deployed

### Resources Created:
- **Namespace**: `playwright-cloud` (isolated environment)
- **Deployment**: 2 Playwright server pods (optimized for Killercoda resources)
- **Service**: NodePort on port 30300 (external access)
- **HPA**: Auto-scaling 2-5 replicas based on CPU

### Resource Optimization for Killercoda:
```yaml
resources:
  requests:
    cpu: "200m"      # Light CPU usage
    memory: "256Mi"  # Minimal memory footprint
  limits:
    cpu: "500m"      # Reasonable limits
    memory: "1Gi"    # Conservative memory cap
```

## 🌐 Access Methods

### Method 1: Port Forward (Recommended)
```bash
kubectl port-forward -n playwright-cloud service/pw-server 3000:3000 &
export PW_TEST_CONNECT_WS_ENDPOINT="ws://localhost:3000/"
```

### Method 2: NodePort (External Access)
```bash
# Find the node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
export PW_TEST_CONNECT_WS_ENDPOINT="ws://$NODE_IP:30300/"
```

### Method 3: Killercoda Traffic Tab
1. Click on the "Traffic / Ports" tab in Killercoda
2. Access port 30300
3. Use the provided URL for WebSocket connections

## 🧪 Testing & Validation

### Built-in Test Script:
```javascript
// test-in-killercoda.js - Comprehensive test suite
- ✅ Connection test to remote browser
- ✅ Wikipedia navigation and search
- ✅ Screenshot generation
- ✅ Multiple tabs simulation
```

### Your Own Tests:
```bash
# Run Wikipedia test with 3 workers
PW_TEST_CONNECT_WS_ENDPOINT="ws://localhost:3000/" npx playwright test tests/wikipedia.spec.ts --workers=3

# Run all stable tests
PW_TEST_CONNECT_WS_ENDPOINT="ws://localhost:3000/" npx playwright test --workers=3 --grep="wikipedia|medium"
```

## 📊 Monitoring & Management

### Check Deployment Status:
```bash
# Pod status
kubectl get pods -n playwright-cloud -o wide

# Service details
kubectl get service pw-server -n playwright-cloud

# HPA scaling status
kubectl get hpa pw-server -n playwright-cloud

# View logs
kubectl logs -f -l app=pw-server -n playwright-cloud
```

### Scaling Operations:
```bash
# Scale up for more parallel tests
kubectl scale deployment pw-server --replicas=4 -n playwright-cloud

# Scale down to save resources
kubectl scale deployment pw-server --replicas=1 -n playwright-cloud
```

## 🎯 Use Cases Perfect for Killercoda

### 1. Learning Kubernetes + Playwright
- Understand how browser automation scales in K8s
- Practice WebSocket load balancing
- Learn resource management for GUI applications

### 2. Testing CI/CD Patterns
- Simulate pipeline testing with multiple workers
- Test auto-scaling under load
- Practice blue-green deployment strategies

### 3. Demonstrating Cloud-Native Testing
- Show stakeholders scalable test execution
- Demonstrate cost-effective browser automation
- Prototype testing infrastructure

## 🔧 Troubleshooting

### Pods Not Starting:
```bash
# Check resource constraints
kubectl describe pod -n playwright-cloud -l app=pw-server

# View detailed events
kubectl get events -n playwright-cloud --sort-by='.lastTimestamp'
```

### WebSocket Connection Issues:
```bash
# Test local connectivity
kubectl port-forward -n playwright-cloud service/pw-server 3000:3000 &
curl -I http://localhost:3000

# Check service endpoints
kubectl get endpoints pw-server -n playwright-cloud
```

### Resource Limits Hit:
```bash
# Reduce resource requests if needed
kubectl patch deployment pw-server -n playwright-cloud -p '{"spec":{"template":{"spec":{"containers":[{"name":"server","resources":{"requests":{"memory":"128Mi","cpu":"100m"}}}]}}}}'
```

## 🧹 Cleanup

```bash
# Remove everything
kubectl delete namespace playwright-cloud

# Or just scale down to save resources
kubectl scale deployment pw-server --replicas=0 -n playwright-cloud
```

## 🎓 Learning Outcomes

After completing this tutorial, you'll understand:
- ✅ How to deploy browser automation in Kubernetes
- ✅ WebSocket service exposure patterns
- ✅ Resource optimization for GUI applications
- ✅ Auto-scaling strategies for test workloads
- ✅ Cloud-native testing architecture

## 💡 Next Steps

1. **Try Different Ingress**: Experiment with Ingress controllers
2. **Add Monitoring**: Deploy Grafana to monitor test execution
3. **Implement Storage**: Add PVC for test artifacts
4. **Security Hardening**: Apply Pod Security Standards
5. **Multi-Region**: Test cross-region WebSocket latency

---

**🎉 Happy Testing on Killercoda!** 

*This setup demonstrates production-ready Playwright cloud architecture in a free, temporary environment - perfect for learning and experimentation!*
