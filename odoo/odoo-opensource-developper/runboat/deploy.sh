#!/bin/bash
# Runboat Deployment Script for OCA/vertical-association
# Usage: ./deploy.sh [setup|deploy|destroy|status]
# Reference: odoo-k8s-readme.md, odoo18-AK-template_README.md

set -euo pipefail

NAMESPACE="runboat"
REPO="OCA/vertical-association"
RUNBOAT_URL="https://runboat.flows.cab"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster. Please configure your kubeconfig."
        exit 1
    fi
}

# Check if Passbolt CLI is available
check_passbolt() {
    if ! command -v pass &> /dev/null; then
        log_warn "Passbolt CLI not found. Using random passwords instead."
        return 1
    fi
    return 0
}

# Generate random passwords
generate_passwords() {
    DB_PASSWORD=$(openssl rand -hex 24)
    WEBHOOK_SECRET=$(openssl rand -hex 32)
    ADMIN_PASSWORD=$(openssl rand -hex 16)
}

# Get passwords from Passbolt or generate new ones
get_passwords() {
    generate_passwords
    
    if check_passbolt; then
        if pass show odoo/runbot-db &> /dev/null; then
            DB_PASSWORD=$(pass show odoo/runbot-db)
            log_info "Using Passbolt for DB password"
        fi
        
        if pass show runboat/webhook-secret &> /dev/null; then
            WEBHOOK_SECRET=$(pass show runboat/webhook-secret)
            log_info "Using Passbolt for webhook secret"
        fi
        
        if pass show runboat/admin-password &> /dev/null; then
            ADMIN_PASSWORD=$(pass show runboat/admin-password)
            log_info "Using Passbolt for admin password"
        fi
    fi
}

# Setup namespace and secrets
setup() {
    log_info "Setting up Runboat for ${REPO}..."
    
    # Create namespace
    if ! kubectl get ns ${NAMESPACE} &> /dev/null; then
        kubectl create ns ${NAMESPACE}
        log_info "Created namespace: ${NAMESPACE}"
    else
        log_info "Namespace ${NAMESPACE} already exists"
    fi
    
    # Create secrets
    get_passwords
    
    kubectl create secret generic runboat-secrets -n ${NAMESPACE} \
        --from-literal=db-password="$DB_PASSWORD" \
        --from-literal=webhook-secret="$WEBHOOK_SECRET" \
        --from-literal=admin-password="$ADMIN_PASSWORD" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    log_info "Created secrets in namespace: ${NAMESPACE}"
    log_info ""
    log_info "✅ Setup completed!"
    log_info ""
    log_info "Webhook Secret: $WEBHOOK_SECRET"
    log_info ""
    log_info "To configure GitHub webhook:"
    log_info "  1. Go to: https://github.com/${REPO}/settings/hooks"
    log_info "  2. Add webhook with URL: ${RUNBOAT_URL}/runboat/hook/github"
    log_info "  3. Use secret: $WEBHOOK_SECRET"
    log_info "  4. Select events: Push, Pull request, Issue comment"
    
    # Store passwords in Passbolt for future reference
    if check_passbolt; then
        log_info ""
        log_info "Storing passwords in Passbolt..."
        echo -n "$DB_PASSWORD" | pass insert --echo odoo/runbot-db
        echo -n "$WEBHOOK_SECRET" | pass insert --echo runboat/webhook-secret
        echo -n "$ADMIN_PASSWORD" | pass insert --echo runboat/admin-password
        log_info "Passwords stored in Passbolt"
    fi
}

# Deploy Runboat
deploy() {
    log_info "Deploying Runboat..."
    
    # Apply Kubernetes manifests
    kubectl apply -f k8s/runboat-vertical-association.yaml
    
    log_info "Waiting for Runboat to be ready..."
    kubectl wait --for=condition=available deployment/runboat -n ${NAMESPACE} --timeout=300s
    
    log_info "✅ Runboat deployed successfully!"
    log_info ""
    log_info "Access Runboat at: ${RUNBOAT_URL}"
    log_info "Admin password: $(kubectl get secret runboat-secrets -n ${NAMESPACE} -o jsonpath='{.data.admin-password}' | base64 -d)"
    log_info ""
    log_info "API Endpoints:"
    log_info "  - Health:    ${RUNBOAT_URL}/runboat/api/health"
    log_info "  - Builds:    ${RUNBOAT_URL}/runboat/api/builds"
    log_info "  - Webhook:   ${RUNBOAT_URL}/runboat/hook/github"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Configure GitHub webhook (see setup)"
    log_info "  2. Push to OCA/vertical-association to trigger builds"
}

# Destroy Runboat
destroy() {
    log_warn "This will delete the Runboat namespace and all its resources!"
    read -p "Are you sure? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Aborted"
        exit 0
    fi
    
    log_info "Deleting Runboat namespace: ${NAMESPACE}..."
    kubectl delete ns ${NAMESPACE} --wait
    log_info "✅ Namespace deleted"
    
    # Remove from Passbolt
    if check_passbolt; then
        log_info "Removing passwords from Passbolt..."
        pass rm -f odoo/runbot-db runboat/webhook-secret runboat/admin-password
        log_info "Passwords removed from Passbolt"
    fi
}

# Show status
status() {
    log_info "Runboat Status:"
    echo ""
    
    if ! kubectl get ns ${NAMESPACE} &> /dev/null; then
        log_error "Runboat namespace does not exist"
        exit 1
    fi
    
    echo "=== Pods ==="
    kubectl get pods -n ${NAMESPACE}
    echo ""
    
    echo "=== Deployments ==="
    kubectl get deployments -n ${NAMESPACE}
    echo ""
    
    echo "=== Services ==="
    kubectl get svc -n ${NAMESPACE}
    echo ""
    
    echo "=== Ingress ==="
    kubectl get ingress -n ${NAMESPACE}
    echo ""
    
    echo "=== Builds ==="
    if command -v curl &> /dev/null; then
        curl -sf ${RUNBOAT_URL}/runboat/api/builds | jq '.[] | {id, repo, branch, status, created}' || echo "No builds yet"
    else
        log_warn "curl not installed, cannot list builds"
    fi
    echo ""
    
    echo "=== Health ==="
    if command -v curl &> /dev/null; then
        curl -sf ${RUNBOAT_URL}/runboat/api/health | jq || echo "Health check failed"
    else
        log_warn "curl not installed, cannot check health"
    fi
}

# Main
main() {
    check_kubectl
    
    case "${1:-help}" in
        setup)
            setup
            ;;
        deploy)
            deploy
            ;;
        destroy)
            destroy
            ;;
        status)
            status
            ;;
        *)
            echo "Usage: $0 [setup|deploy|destroy|status]"
            echo ""
            echo "Commands:"
            echo "  setup     - Create namespace and secrets"
            echo "  deploy    - Deploy Runboat controller"
            echo "  destroy   - Delete Runboat namespace and resources"
            echo "  status    - Show current Runboat status"
            exit 1
            ;;
    esac
}

main "$@"
