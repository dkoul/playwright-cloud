#!/bin/bash
set -e

echo "🎭 Deploying Playwright Cloud on Killercoda Kubernetes Playground"
echo "================================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in Killercoda environment
if [ -f "/etc/killercoda" ] || [ "$KILLERCODA" == "true" ]; then
    echo -e "${GREEN}✅ Running in Killercoda environment${NC}"
    KILLERCODA_ENV=true
else
    echo -e "${YELLOW}⚠️  Not detected as Killercoda environment - proceeding anyway${NC}"
    KILLERCODA_ENV=false
fi

# Function to wait with spinner
wait_with_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Step 1: Deploy Playwright Server
echo -e "${BLUE}📦 Step 1: Deploying Playwright Server...${NC}"
kubectl apply -f killercoda-deployment.yaml

# Step 2: Wait for deployment
echo -e "${BLUE}⏳ Step 2: Waiting for pods to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/pw-server -n playwright-cloud || {
    echo -e "${RED}❌ Deployment failed to become ready${NC}"
    echo "Pod status:"
    kubectl get pods -n playwright-cloud
    echo "Pod logs:"
    kubectl logs -l app=pw-server -n playwright-cloud --tail=50
    exit 1
}

# Step 3: Get service information
echo -e "${BLUE}🔍 Step 3: Getting service information...${NC}"
NODE_PORT=$(kubectl get service pw-server -n playwright-cloud -o jsonpath='{.spec.ports[0].nodePort}')

# In Killercoda, we can use the controlplane hostname
if [ "$KILLERCODA_ENV" == "true" ]; then
    # Killercoda specific endpoint discovery
    CONTROLPLANE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    WS_ENDPOINT="ws://$CONTROLPLANE_IP:$NODE_PORT/"
    
    # Killercoda also exposes services via their proxy
    KILLERCODA_PORT_URL="{{TRAFFIC_HOST1_30300}}"  # Killercoda magic variable
    echo -e "${GREEN}🌐 Killercoda Service URLs:${NC}"
    echo "   Internal: $WS_ENDPOINT"
    echo "   External: $KILLERCODA_PORT_URL (in browser tabs)"
else
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
    if [ -z "$NODE_IP" ]; then
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    fi
    WS_ENDPOINT="ws://$NODE_IP:$NODE_PORT/"
fi

# Step 4: Display status
echo -e "${BLUE}📊 Step 4: Deployment Status${NC}"
echo "Namespace: playwright-cloud"
echo "NodePort: $NODE_PORT"
echo "WebSocket Endpoint: $WS_ENDPOINT"
echo ""

echo -e "${GREEN}📦 Pod Status:${NC}"
kubectl get pods -n playwright-cloud -o wide

echo ""
echo -e "${GREEN}🔧 Service Details:${NC}"
kubectl get service pw-server -n playwright-cloud

echo ""
echo -e "${GREEN}🏗️ Deployment Details:${NC}"
kubectl get deployment pw-server -n playwright-cloud

echo ""
echo -e "${GREEN}📈 HPA Status:${NC}"
kubectl get hpa pw-server -n playwright-cloud

# Step 5: Test connectivity (basic)
echo ""
echo -e "${BLUE}🧪 Step 5: Testing connectivity...${NC}"

# Try to connect to the service
if kubectl get pods -n playwright-cloud -l app=pw-server --field-selector=status.phase=Running | grep -q "Running"; then
    echo -e "${GREEN}✅ Pods are running successfully${NC}"
else
    echo -e "${RED}❌ Some pods are not running${NC}"
fi

# Port forward for local testing
echo ""
echo -e "${BLUE}🔌 Setting up port-forward for local testing...${NC}"
kubectl port-forward -n playwright-cloud service/pw-server 3000:3000 &
PORT_FORWARD_PID=$!
sleep 3

# Test local connection
if curl -s --max-time 5 http://localhost:3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Port-forward connection successful${NC}"
else
    echo -e "${YELLOW}⚠️  Port-forward connection test inconclusive${NC}"
fi

# Clean up port-forward
kill $PORT_FORWARD_PID 2>/dev/null || true

# Step 6: Usage instructions
echo ""
echo -e "${GREEN}🎯 === DEPLOYMENT COMPLETE! ===${NC}"
echo ""
echo -e "${YELLOW}📝 Usage Instructions:${NC}"
echo ""
echo "1. For local testing (from within the cluster):"
echo "   kubectl port-forward -n playwright-cloud service/pw-server 3000:3000"
echo "   export PW_TEST_CONNECT_WS_ENDPOINT=\"ws://localhost:3000/\""
echo ""
echo "2. For NodePort access:"
echo "   export PW_TEST_CONNECT_WS_ENDPOINT=\"$WS_ENDPOINT\""
echo ""

if [ "$KILLERCODA_ENV" == "true" ]; then
    echo "3. For Killercoda external access:"
    echo "   Click the 'Traffic / Ports' tab in Killercoda"
    echo "   Access port 30300"
    echo ""
fi

echo "4. Run tests:"
echo "   npx playwright test --workers=3"
echo ""
echo -e "${YELLOW}🛠️  Management Commands:${NC}"
echo "   View pods:        kubectl get pods -n playwright-cloud"
echo "   View logs:        kubectl logs -f -l app=pw-server -n playwright-cloud"
echo "   Scale up:         kubectl scale deployment pw-server --replicas=4 -n playwright-cloud"
echo "   Delete:           kubectl delete namespace playwright-cloud"
echo ""
echo -e "${GREEN}✅ Playwright Cloud is ready on Killercoda!${NC}"
