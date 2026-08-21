#!/usr/bin/env python3
"""
Script to check Kubernetes RBAC permissions for Odoo development.
Part of the odoo-oca-developer skill.
"""

import subprocess
import sys
import argparse
from typing import List, Dict, Optional, Tuple

def run_kubectl_command(command: List[str]) -> Tuple[bool, Optional[str]]:
    """Run kubectl command and return (success, output)."""
    try:
        result = subprocess.run(
            command, 
            capture_output=True, 
            text=True, 
            check=True
        )
        return True, result.stdout.strip()
    except subprocess.CalledProcessError as e:
        return False, e.stderr.strip()
    except FileNotFoundError:
        return False, "Error: kubectl command not found. Please install kubectl."

def check_permission(verb: str, resource: str, namespace: str, subresource: str = None) -> bool:
    """Check if a specific RBAC permission is granted."""
    command = ["kubectl", "auth", "can-i", verb, resource]
    if namespace:
        command.extend(["-n", namespace])
    if subresource:
        command.extend(["--subresource", subresource])
    
    success, output = run_kubectl_command(command)
    return success and output.lower() == "yes"

def check_common_permissions(namespace: str) -> Dict[str, bool]:
    """Check common permissions needed for Odoo development."""
    permissions = {
        # Basic read operations
        "get pods": check_permission("get", "pods", namespace),
        "list pods": check_permission("list", "pods", namespace),
        "get deployments": check_permission("get", "deployments", namespace),
        "get services": check_permission("get", "services", namespace),
        "get configmaps": check_permission("get", "configmaps", namespace),
        
        # Pod subresources
        "get pod logs": check_permission("get", "pods", namespace, "log"),
        "get pod exec": check_permission("get", "pods", namespace, "exec"),
        
        # Write operations (usually restricted)
        "create pods": check_permission("create", "pods", namespace),
        "delete pods": check_permission("delete", "pods", namespace),
        "update deployments": check_permission("update", "deployments", namespace),
        
        # Exec operations (often restricted)
        "create exec": check_permission("create", "pods/exec", namespace),
    }
    
    return permissions

def print_permission_report(permissions: Dict[str, bool], namespace: str):
    """Print a formatted permission report."""
    print(f"\n🔒 Kubernetes RBAC Permission Report for namespace '{namespace}'\n")
    print("=" * 60)
    
    # Group permissions by category
    categories = {
        "🟢 Read Operations (Safe)": [
            "get pods", "list pods", "get deployments", 
            "get services", "get configmaps", "get pod logs"
        ],
        "🟡 Subresource Access": [
            "get pod exec", "create exec"
        ],
        "🔴 Write Operations (Restricted)": [
            "create pods", "delete pods", "update deployments"
        ]
    }
    
    for category, perm_list in categories.items():
        print(f"\n{category}:")
        print("-" * 40)
        for perm in perm_list:
            status = "✅ ALLOWED" if permissions[perm] else "❌ DENIED"
            print(f"  {perm:20} {status}")
    
    # Summary
    allowed = sum(1 for v in permissions.values() if v)
    total = len(permissions)
    
    print(f"\n" + "=" * 60)
    print(f"Summary: {allowed}/{total} permissions allowed")
    
    if allowed == total:
        print("🟢 Full access - You have administrative privileges")
    elif allowed >= total * 0.6:
        print("🟡 Limited access - Sufficient for most monitoring tasks")
    else:
        print("🔴 Restricted access - Contact administrator for elevated permissions")
    
    print(f"\nCurrent service account: system:serviceaccount:ai-tools:hermes")
    print("This follows security best practices (Principle of Least Privilege)")

def suggest_workarounds(permissions: Dict[str, bool]):
    """Suggest workarounds for denied permissions."""
    print(f"\n💡 Workarounds for Denied Permissions:")
    print("-" * 40)
    
    if not permissions["create exec"]:
        print("❌ Cannot exec into pods:")
        print("  → Use 'kubectl logs' for debugging instead")
        print("  → Check version from 'kubectl describe pod | grep Image:'")
        print("  → Request temporary exec access if absolutely needed")
    
    if not permissions["delete pods"]:
        print("\n❌ Cannot delete pods:")
        print("  → Identify issues through logs and events")
        print("  → Contact operations team for pod restarts")
        print("  → Use 'kubectl scale' if deployment scaling is allowed")
    
    if not permissions["update deployments"]:
        print("\n❌ Cannot update deployments:")
        print("  → Use CI/CD pipelines for deployments")
        print("  → Request operations team assistance")
        print("  → Store configurations in Git for audit trail")

def main():
    parser = argparse.ArgumentParser(
        description="Check Kubernetes RBAC permissions for Odoo development"
    )
    parser.add_argument(
        "--namespace", "-n",
        help="Kubernetes namespace to check (default: fnfe-test)",
        default="fnfe-test"
    )
    parser.add_argument(
        "--check", "-c",
        help="Check specific permission (format: verb/resource[/subresource])",
        action="append"
    )
    parser.add_argument(
        "--suggest", "-s",
        help="Suggest workarounds for denied permissions",
        action="store_true"
    )
    
    args = parser.parse_args()
    
    if args.check:
        # Check specific permissions
        print(f"\nChecking specific permissions in namespace '{args.namespace}':\n")
        for perm in args.check:
            parts = perm.split('/')
            if len(parts) == 2:
                verb, resource = parts
                subresource = None
            elif len(parts) == 3:
                verb, resource, subresource = parts
            else:
                print(f"❌ Invalid permission format: {perm}")
                continue
            
            allowed = check_permission(verb, resource, args.namespace, subresource)
            status = "✅ ALLOWED" if allowed else "❌ DENIED"
            print(f"{perm:30} {status}")
    else:
        # Check all common permissions
        permissions = check_common_permissions(args.namespace)
        print_permission_report(permissions, args.namespace)
        
        if args.suggest:
            suggest_workarounds(permissions)

if __name__ == "__main__":
    main()