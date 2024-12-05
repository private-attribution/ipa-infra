#!/usr/bin/env python3

import subprocess
import sys

def get_pod_name(label):
    """Get the name of a pod with a given label"""
    command = f"kubectl get pods -l {label} --output=jsonpath='{{.items[0].metadata.name}}'"
    output = subprocess.check_output(command, shell=True).decode().strip()
    return output

def connect_to_pod(pod_name):
    """Connect to a pod using kubectl exec"""
    command = f"kubectl exec --stdin --tty {pod_name} -- /bin/bash"
    subprocess.run(command, shell=True)

def main():
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print("Usage: python connect_to.py <option> [shard]")
        print("Options:")
        print("  rc: Connect to report collector")
        print("  h1, h2, h3: Connect to helper shard (e.g., h1 3 for helper 1 shard 3)")
        sys.exit(1)

    option = sys.argv[1]

    if option == "rc":
        label = "app=report-collector"
    elif option in ["h1", "h2", "h3"]:
        if len(sys.argv) != 3:
            print("Error: Shard number is required for helper connection")
            sys.exit(1)
        shard_number = int(sys.argv[2])
        label = f"statefulset.kubernetes.io/pod-name={option}-helper-shard-{shard_number}"
    else:
        print("Invalid option")
        sys.exit(1)

    pod_name = get_pod_name(label)
    if not pod_name:
        print(f"No pod found with label '{label}'")
        sys.exit(1)

    print(f"Found pod: {pod_name}")
    connect_to_pod(pod_name)

if __name__ == "__main__":
    main()
