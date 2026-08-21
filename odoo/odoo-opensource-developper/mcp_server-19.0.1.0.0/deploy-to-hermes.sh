#!/bin/bash
# Odoo MCP Server Deployment Script for Hermes Integration
# Usage: ./deploy-to-hermes.sh [setup|deploy|destroy|status]
# Reference: mcp_server-19.0.1.0.0/README-Hermes.md

set -euo pipefail

# Configuration
NAMESPACE="mcp"
MCP_CLIENT_DIR="/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/mcp_server-19.0.1.0.0"
REGISTRY="registry.gitlab.akretion.com/akretion/mcp"
IMAGE_NAME="mcp-odoo-client"
IMAGE_TAG="latest"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_header "Checking Prerequisites"
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    log_info "kubectl: $(kubectl version --client --short)"
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    log_info "Docker: $(docker --version)"
    
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    log_info "Connected to Kubernetes cluster"
    
    if [ ! -d "$MCP_CLIENT_DIR/mcp_server" ]; then
        log_error "Odoo MCP Server module not found at $MCP_CLIENT_DIR/mcp_server"
        exit 1
    fi
    log_info "Odoo MCP Server module found"
    
    if [ ! -d "$MCP_CLIENT_DIR/mcp-client" ]; then
        log_error "mcp-server-odoo client not found at $MCP_CLIENT_DIR/mcp-client"
        exit 1
    fi
    log_info "mcp-server-odoo client found"
}

# Setup namespace and secrets
setup() {
    log_header "Setting up MCP Infrastructure"
    
    # Create namespace
    if ! kubectl get ns "$NAMESPACE" &> /dev/null; then
        kubectl create ns "$NAMESPACE"
        log_info "Created namespace: $NAMESPACE"
    else
        log_info "Namespace $NAMESPACE already exists"
    fi
    
    # Generate API keys if not provided via Passbolt
    log_info ""
    log_info "API Key Configuration:"
    for version in 14 16 18; do
        if command -v pass &> /dev/null; then
            KEY=$(pass show odoo/mcp-${version}-api-key 2>/dev/null || echo "CHANGE_ME")
        else
            KEY="CHANGE_ME_$(openssl rand -hex 16)"
        fi
        log_info "  Odoo $version API Key: ${KEY:0:20}..."
    done
    
    log_info ""
    log_info "To create secrets, run:"
    log_info "  kubectl create secret generic mcp-odoo-secrets -n $NAMESPACE \\"
    log_info "    --from-literal=ODOO_14_API_KEY=\"$(pass show odoo/mcp-14-api-key)\" \\"
    log_info "    --from-literal=ODOO_16_API_KEY=\"$(pass show odoo/mcp-16-api-key)\" \\"
    log_info "    --from-literal=ODOO_18_API_KEY=\"$(pass show odoo/mcp-18-api-key)\""
}

# Build Docker image
build_image() {
    log_header "Building Docker Image"
    
    cd "$MCP_CLIENT_DIR/k8s"
    
    log_info "Building image: $REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
    docker build -t "$REGISTRY/$IMAGE_NAME:$IMAGE_TAG" -f Dockerfile ..
    
    log_info "Pushing image to registry"
    docker push "$REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
    
    log_info "Image built and pushed successfully"
}

# Deploy to Kubernetes
deploy() {
    log_header "Deploying to Kubernetes"
    
    cd "$MCP_CLIENT_DIR/k8s"
    
    # Check if secrets exist
    if ! kubectl get secret mcp-odoo-secrets -n "$NAMESPACE" &> /dev/null; then
        log_warn "Secrets not found. Creating placeholder secrets..."
        kubectl create secret generic mcp-odoo-secrets -n "$NAMESPACE" \
            --from-literal=ODOO_14_API_KEY="CHANGE_ME" \
            --from-literal=ODOO_16_API_KEY="CHANGE_ME" \
            --from-literal=ODOO_18_API_KEY="CHANGE_ME"
        log_warn "Please update secrets with actual API keys from Passbolt"
    fi
    
    # Apply Kubernetes manifests
    log_info "Applying Kubernetes manifests"
    kubectl apply -f mcp-odoo-client.yaml
    
    # Wait for deployment
    log_info "Waiting for deployment to be ready..."
    kubectl wait --for=condition=available deployment/mcp-odoo-client -n "$NAMESPACE" --timeout=300s
    
    log_info "MCP Odoo Client deployed successfully!"
    log_info ""
    log_info "Service: mcp-odoo-client.$NAMESPACE.svc.cluster.local:8000"
}

# Update Hermes configuration
configure_hermes() {
    log_header "Configuring Hermes"
    
    log_info "You need to update Hermes configuration to use the MCP Odoo Client"
    log_info ""
    log_info "Add to your Hermes config.json:"
    cat << 'EOF'

    "mcpServers": {
      "odoo-14-fnfe": {
        "url": "http://mcp-odoo-client.mcp.svc.cluster.local:8000",
        "transport": "stdio"
      },
      "odoo-18-erk": {
        "url": "http://mcp-odoo-client.mcp.svc.cluster.local:8000",
        "transport": "stdio"
      }
    }

EOF
    
    log_info ""
    log_info "Then apply and restart Hermes:"
    log_info "  kubectl create configmap hermes-config -n pre-prod --from-file=config.json -o yaml --dry-run=client | kubectl apply -f -"
    log_info "  kubectl rollout restart deployment/hermes -n pre-prod"
}

# Destroy deployment
destroy() {
    log_header "Destroying MCP Odoo Client"
    
    read -p "Are you sure you want to delete the MCP Odoo Client? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Aborted"
        exit 0
    fi
    
    kubectl delete -f "$MCP_CLIENT_DIR/k8s/mcp-odoo-client.yaml"
    log_info "MCP Odoo Client deleted"
}

# Show status
status() {
    log_header "MCP Odoo Client Status"
    
    if ! kubectl get ns "$NAMESPACE" &> /dev/null; then
        log_error "Namespace $NAMESPACE does not exist"
        exit 1
    fi
    
    echo ""
    echo "=== Pods ==="
    kubectl get pods -n "$NAMESPACE"
    echo ""
    
    echo "=== Services ==="
    kubectl get svc -n "$NAMESPACE"
    echo ""
    
    echo "=== Deployments ==="
    kubectl get deployments -n "$NAMESPACE"
    echo ""
    
    echo "=== Logs ==="
    kubectl logs -l app=mcp-odoo-client -n "$NAMESPACE" --tail=20
}

# Main
main() {
    check_prerequisites
    
    case "${1:-help}" in
        setup)
            setup
            ;;
        build)
            build_image
            ;;
        deploy)
            deploy
            configure_hermes
            ;;
        destroy)
            destroy
            ;;
        status)
            status
            ;;
        *)
            echo "Usage: $0 [setup|build|deploy|destroy|status]"
            echo ""
            echo "Commands:"
            echo "  setup     - Setup namespace and show API key configuration"
            echo "  build     - Build and push Docker image"
            echo "  deploy    - Deploy to Kubernetes and configure Hermes"
            echo "  destroy   - Delete deployment"
            echo "  status    - Show current status"
            exit 1
            ;;
    esac
}

main "$@"
