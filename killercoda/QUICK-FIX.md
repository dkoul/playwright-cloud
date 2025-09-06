# 🚨 Quick Fix for "no objects passed to apply" Error

## 📋 Troubleshooting Steps

### Step 1: Check if the file exists and has content
```bash
# List files in current directory
ls -la

# Check if the YAML file has content
cat killercoda-deployment.yaml
# OR if using the clean version:
cat killercoda-deployment-clean.yaml
```

### Step 2: Verify YAML syntax
```bash
# Validate YAML syntax
kubectl apply --dry-run=client -f killercoda-deployment.yaml
# OR
kubectl apply --dry-run=client -f killercoda-deployment-clean.yaml
```

### Step 3: Use the Clean Version (No Comments)
```bash
# Create the clean YAML file (copy-paste this entire block):
cat > killercoda-deployment-clean.yaml << 'EOF'
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

### Step 4: Apply the Clean Version
```bash
# Apply the deployment
kubectl apply -f killercoda-deployment-clean.yaml
```

### Step 5: Alternative - Apply Each Resource Separately
If the combined file still doesn't work:

```bash
# Create namespace first
kubectl create namespace playwright-cloud

# Create deployment
cat > deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pw-server
  namespace: playwright-cloud
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
          ports:
            - containerPort: 3000
          resources:
            requests:
              cpu: "200m"
              memory: "256Mi"
          volumeMounts:
            - name: dshm
              mountPath: /dev/shm
      volumes:
        - name: dshm
          emptyDir:
            medium: Memory
            sizeLimit: "512Mi"
EOF

kubectl apply -f deployment.yaml

# Create service
cat > service.yaml << 'EOF'
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

kubectl apply -f service.yaml
```

### Step 6: Verify Deployment
```bash
# Check if resources were created
kubectl get all -n playwright-cloud

# Wait for pods to be ready
kubectl wait --for=condition=available --timeout=300s deployment/pw-server -n playwright-cloud
```

## 🎯 Most Common Causes

1. **YAML Comments**: Some kubectl versions don't like `# comments` in YAML
2. **File Not Created**: The file creation command didn't work properly
3. **Wrong Directory**: You're not in the directory where you created the file
4. **Encoding Issues**: File has wrong encoding (use `cat` command instead of copy-paste)

## 🚀 Quick Success Path

```bash
# 1. Create clean namespace
kubectl create namespace playwright-cloud

# 2. Simple deployment (minimal)
kubectl create deployment pw-server --image=mcr.microsoft.com/playwright:v1.54.0-noble --port=3000 -n playwright-cloud

# 3. Patch the deployment with proper command
kubectl patch deployment pw-server -n playwright-cloud -p '{"spec":{"template":{"spec":{"containers":[{"name":"playwright","command":["/bin/sh","-c"],"args":["npx -y playwright@1.54.0 run-server --port 3000 --host 0.0.0.0"]}]}}}}'

# 4. Expose as NodePort
kubectl expose deployment pw-server --type=NodePort --port=3000 --target-port=3000 -n playwright-cloud

# 5. Patch to use specific NodePort
kubectl patch service pw-server -n playwright-cloud -p '{"spec":{"ports":[{"port":3000,"nodePort":30300}]}}'

# 6. Test connection
kubectl port-forward -n playwright-cloud service/pw-server 3000:3000 &
```

This will get you running quickly! 🎉
