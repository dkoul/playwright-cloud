#!/bin/bash
set -e

echo "🚀 Testing Playwright Cloud on Kubernetes"
echo "=========================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check cluster connection
echo "📡 Checking cluster connection..."
kubectl cluster-info --request-timeout=5s > /dev/null 2>&1 || {
    echo "❌ Cannot connect to Kubernetes cluster"
    exit 1
}
echo "✅ Connected to cluster: $(kubectl config current-context)"

# Deploy the application
echo "🏗️  Deploying Playwright server..."
kubectl apply -k . || {
    echo "❌ Failed to deploy application"
    exit 1
}

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/pw-server || {
    echo "❌ Deployment failed to become ready"
    kubectl describe deployment pw-server
    exit 1
}

# Check service endpoint
echo "🔍 Checking service endpoint..."
SERVICE_TYPE=$(kubectl get service pw-server -o jsonpath='{.spec.type}')
echo "   Service type: $SERVICE_TYPE"

case $SERVICE_TYPE in
    "LoadBalancer")
        echo "   Waiting for LoadBalancer IP..."
        kubectl wait --for=jsonpath='{.status.loadBalancer.ingress[0]}' service/pw-server --timeout=120s || {
            echo "⚠️  LoadBalancer IP not assigned yet"
        }
        LB_IP=$(kubectl get service pw-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        if [ -n "$LB_IP" ]; then
            WS_ENDPOINT="ws://$LB_IP:3000/"
            echo "   LoadBalancer IP: $LB_IP"
        else
            echo "⚠️  LoadBalancer IP not available yet - check cloud provider configuration"
        fi
        ;;
    "NodePort")
        NODE_PORT=$(kubectl get service pw-server -o jsonpath='{.spec.ports[0].nodePort}')
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
        WS_ENDPOINT="ws://$NODE_IP:$NODE_PORT/"
        echo "   NodePort: $NODE_PORT on $NODE_IP"
        ;;
    "ClusterIP")
        echo "   ClusterIP service - checking for Ingress..."
        if kubectl get ingress pw-server &> /dev/null; then
            INGRESS_HOST=$(kubectl get ingress pw-server -o jsonpath='{.spec.rules[0].host}')
            WS_ENDPOINT="wss://$INGRESS_HOST/"
            echo "   Ingress host: $INGRESS_HOST"
        else
            echo "   Using port-forward for testing..."
            kubectl port-forward service/pw-server 3000:3000 &
            PORT_FORWARD_PID=$!
            WS_ENDPOINT="ws://localhost:3000/"
            echo "   Port-forward PID: $PORT_FORWARD_PID"
        fi
        ;;
esac

echo ""
echo "🎭 Playwright Server Status:"
echo "   Endpoint: $WS_ENDPOINT"
echo "   Replicas: $(kubectl get deployment pw-server -o jsonpath='{.status.replicas}')"
echo "   Ready: $(kubectl get deployment pw-server -o jsonpath='{.status.readyReplicas}')"

# Show pod status
echo ""
echo "📦 Pod Status:"
kubectl get pods -l app=pw-server

# Test WebSocket connection if possible
if [ -n "$WS_ENDPOINT" ] && command -v curl &> /dev/null; then
    echo ""
    echo "🔧 Testing WebSocket endpoint..."
    # Try a simple HTTP request first
    HTTP_ENDPOINT=$(echo "$WS_ENDPOINT" | sed 's/ws:/http:/' | sed 's/wss:/https:/')
    HTTP_ENDPOINT="${HTTP_ENDPOINT%/}"  # Remove trailing slash
    
    if curl -s --max-time 10 "$HTTP_ENDPOINT" > /dev/null 2>&1; then
        echo "✅ HTTP endpoint is reachable"
    else
        echo "⚠️  HTTP endpoint test failed - this might be normal for WebSocket-only servers"
    fi
fi

echo ""
echo "🎯 To run tests against this deployment:"
echo "   export PW_TEST_CONNECT_WS_ENDPOINT=\"$WS_ENDPOINT\""
echo "   npx playwright test"

# Clean up port-forward if it was started
if [ -n "$PORT_FORWARD_PID" ]; then
    sleep 2  # Give a moment for testing
    kill $PORT_FORWARD_PID 2>/dev/null || true
fi

echo ""
echo "✅ Kubernetes deployment test completed!"
