# 🎭 Complete Killercoda Tutorial: Playwright Cloud Deployment

**⏱️ Estimated time: 10-15 minutes**  
**🎯 Goal: Deploy and test a scalable Playwright cloud on Killercoda's free Kubernetes playground**

## 📋 Prerequisites
- No local setup required! 
- Just a web browser and internet connection
- Basic familiarity with command line (we'll guide you through everything)

---

## 🚀 Step-by-Step Tutorial

### Step 1: Access Killercoda Playground
1. Go to: **[killercoda.com/playgrounds/scenario/kubernetes](https://killercoda.com/playgrounds/scenario/kubernetes)**
2. Wait for "Terminal Ready" message (usually takes 30-60 seconds)
3. You now have a real Kubernetes cluster in your browser! 🎉

### Step 2: Verify Kubernetes is Ready
```bash
# Check cluster status
kubectl get nodes

# You should see something like:
# NAME           STATUS   ROLES           AGE   VERSION
# controlplane   Ready    control-plane   60s   v1.28.x
```

### Step 3: Create the Deployment Files
Copy and paste these commands one by one:

```bash
# Create killercoda directory
mkdir -p killercoda && cd killercoda
```

```bash
# Create the deployment manifest
cat > killercoda-deployment.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: playwright-cloud
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pw-server
  namespace: playwright-cloud
  labels:
    app: pw-server
spec:
  replicas: 2
  selector:
    matchLabels:
      app: pw-server
  template:
    metadata:
      labels:
        app: pw-server
    spec:
      containers:
        - name: server
          image: mcr.microsoft.com/playwright:v1.54.0-noble
          command: ["/bin/sh","-c"]
          args:
            - "npx -y playwright@1.54.0 run-server --port 3000 --host 0.0.0.0"
          env:
            - name: HOME
              value: "/tmp"
          ports:
            - containerPort: 3000
          resources:
            requests:
              cpu: "200m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "1Gi"
          volumeMounts:
            - name: dshm
              mountPath: /dev/shm
      volumes:
        - name: dshm
          emptyDir:
            medium: Memory
            sizeLimit: "512Mi"
---
apiVersion: v1
kind: Service
metadata:
  name: pw-server
  namespace: playwright-cloud
spec:
  selector:
    app: pw-server
  type: NodePort
  ports:
    - port: 3000
      targetPort: 3000
      nodePort: 30300
EOF
```

### Step 4: Deploy Playwright Cloud
```bash
# Apply the deployment
kubectl apply -f killercoda-deployment.yaml

# Wait for pods to be ready (this may take 2-3 minutes)
kubectl wait --for=condition=available --timeout=300s deployment/pw-server -n playwright-cloud
```

### Step 5: Verify Deployment
```bash
# Check if pods are running
kubectl get pods -n playwright-cloud

# You should see 2 pods in "Running" status:
# NAME                         READY   STATUS    RESTARTS   AGE
# pw-server-xxxxxxxxx-xxxxx    1/1     Running   0          2m
# pw-server-xxxxxxxxx-xxxxx    1/1     Running   0          2m
```

### Step 6: Test the Connection
```bash
# Create a simple test script
cat > test-connection.js << 'EOF'
const { chromium } = require('playwright');

async function test() {
    console.log('🎭 Testing Playwright Cloud...');
    try {
        const browser = await chromium.connect('ws://localhost:3000/');
        const page = await browser.newPage();
        await page.goto('https://www.wikipedia.org/');
        const title = await page.title();
        console.log('✅ SUCCESS! Page title:', title);
        await browser.close();
    } catch (error) {
        console.log('❌ FAILED:', error.message);
    }
}
test();
EOF
```

### Step 7: Install Playwright and Test
```bash
# Install Playwright
npm init -y
npm install playwright@1.54.0
```

```bash
# Start port-forward in background
kubectl port-forward -n playwright-cloud service/pw-server 3000:3000 &

# Wait a moment for port-forward to establish
sleep 3

# Run the test
node test-connection.js
```

**🎉 You should see:** `✅ SUCCESS! Page title: Wikipedia`

### Step 8: Test with Multiple Workers (Parallel Execution)
```bash
# Create the existing Wikipedia test
mkdir -p tests
cat > tests/wikipedia.spec.js << 'EOF'
const { test, expect } = require('@playwright/test');

test('wikipedia search', async ({ page }) => {
  await page.goto('https://www.wikipedia.org/');
  await page.locator('input#searchInput').fill('Kubernetes');
  await page.locator('input#searchInput').press('Enter');
  
  const heading = page.locator('#firstHeading');
  await expect(heading).toBeVisible();
  await expect(heading).toContainText(/kubernetes/i);
});
EOF
```

```bash
# Install Playwright Test
npm install @playwright/test@1.54.0

# Run with 3 parallel workers
PW_TEST_CONNECT_WS_ENDPOINT="ws://localhost:3000/" npx playwright test tests/wikipedia.spec.js --workers=3
```

### Step 9: Monitor Scaling (Optional)
```bash
# In a new terminal tab, watch the pods
kubectl get pods -n playwright-cloud -w

# In another terminal, generate load
for i in {1..5}; do
  echo "Test run $i"
  PW_TEST_CONNECT_WS_ENDPOINT="ws://localhost:3000/" npx playwright test tests/wikipedia.spec.js --workers=3 &
done
```

### Step 10: Access via Killercoda's Traffic Tab
1. Click on the **"Traffic / Ports"** tab at the top of Killercoda
2. Enter port `30300`
3. Click **"Access"**
4. You'll get a public URL you can use from anywhere!

---

## 🎯 What You've Accomplished

✅ **Deployed a production-ready Playwright cloud on Kubernetes**  
✅ **Connected remote browsers via WebSocket**  
✅ **Ran parallel tests across multiple workers**  
✅ **Experienced cloud-native browser automation**  
✅ **Learned Kubernetes service exposure patterns**

## 🔍 Key Concepts Demonstrated

1. **Containerized Browser Automation**: Playwright server running in pods
2. **WebSocket Load Balancing**: Multiple browser connections distributed across pods  
3. **Resource Management**: CPU/memory limits for stable operation
4. **Service Discovery**: NodePort for external access
5. **Horizontal Scaling**: Multiple replicas handling concurrent requests

## 🧹 Cleanup (Optional)
```bash
# Remove everything
kubectl delete namespace playwright-cloud

# Stop port-forward
pkill -f "kubectl port-forward"
```

## 🚀 Next Steps

- **Try your own tests**: Upload your Playwright test suite
- **Scale up**: Increase replicas for more parallel capacity  
- **Add monitoring**: Deploy Grafana to visualize test execution
- **Security**: Explore Pod Security Standards
- **Production**: Apply these patterns to your real Kubernetes clusters

---

## 🎊 Congratulations!

You've successfully deployed and tested a scalable Playwright cloud on Kubernetes! This same architecture can be deployed on any Kubernetes cluster - AWS EKS, Google GKE, Azure AKS, or your own infrastructure.

**📚 Want to learn more?** Check out the full repository for advanced configurations, monitoring setup, and production best practices.

---

*🎭 Happy testing with Playwright Cloud!*
