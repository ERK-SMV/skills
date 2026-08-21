#!/usr/bin/env python3
"""
Script to list Kubernetes pods for Odoo development environments.
Part of the odoo-oca-developer skill.
"""

import subprocess
import sys
import argparse
from typing import List, Dict, Optional

def run_kubectl_command(command: List[str]) -> Optional[str]:
    """Run kubectl command and return output or None if failed."""
    try:
        result = subprocess.run(
            command, 
            capture_output=True, 
            text=True, 
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error running kubectl command: {e.stderr.strip()}", file=sys.stderr)
        return None
    except FileNotFoundError:
        print("Error: kubectl command not found. Please install kubectl and configure your kubeconfig.", file=sys.stderr)
        return None

def list_pods(namespace: str = None) -> Optional[str]:
    """List pods in the specified namespace."""
    command = ["kubectl", "get", "pods"]
    if namespace:
        command.extend(["-n", namespace])
    
    return run_kubectl_command(command)

def get_pod_details(pod_name: str, namespace: str) -> Optional[str]:
    """Get detailed information about a specific pod."""
    command = ["kubectl", "describe", "pod", pod_name]
    if namespace:
        command.extend(["-n", namespace])
    
    return run_kubectl_command(command)

def get_pod_logs(pod_name: str, namespace: str, lines: int = 100) -> Optional[str]:
    """Get logs from a specific pod."""
    command = ["kubectl", "logs", pod_name, "--tail", str(lines)]
    if namespace:
        command.extend(["-n", namespace])
    
    return run_kubectl_command(command)

def main():
    parser = argparse.ArgumentParser(
        description="List and manage Kubernetes pods for Odoo development"
    )
    parser.add_argument(
        "--namespace", "-n", 
        help="Kubernetes namespace",
        default=None
    )
    parser.add_argument(
        "--pod", "-p",
        help="Specific pod name for details or logs",
        default=None
    )
    parser.add_argument(
        "--logs", "-l",
        help="Get logs from pod (specify number of lines)",
        type=int,
        default=None
    )
    
    args = parser.parse_args()
    
    if args.pod:
        if args.logs:
            # Get pod logs
            logs = get_pod_logs(args.pod, args.namespace, args.logs)
            if logs:
                print(f"Logs from pod {args.pod}:")
                print(logs)
        else:
            # Get pod details
            details = get_pod_details(args.pod, args.namespace)
            if details:
                print(f"Details for pod {args.pod}:")
                print(details)
    else:
        # List all pods
        pods = list_pods(args.namespace)
        if pods:
            print(f"Pods in namespace '{args.namespace or 'default'}':")
            print(pods)

if __name__ == "__main__":
    main()