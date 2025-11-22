#!/usr/bin/env python3
"""Validate that the role IDs embedded in roles.bicep match live Azure definitions."""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROLE_NAME_BY_VAR = {
    "acrPullRoleDefinitionId": "AcrPull",
    "eventHubSendRoleDefinitionId": "Azure Event Hubs Data Sender",
    "eventHubListenRoleDefinitionId": "Azure Event Hubs Data Receiver",
    "storageBlobContributorRoleDefinitionId": "Storage Blob Data Contributor",
}

REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
BICEP_PATH = REPOSITORY_ROOT / "infra" / "modules" / "roles.bicep"


def extract_role_id(var_name: str) -> str:
    pattern = rf"var\s+{re.escape(var_name)}\s*=\s*subscriptionResourceId\('[^']+',\s*'([^']+)'\)"
    text = BICEP_PATH.read_text(encoding="utf-8")
    match = re.search(pattern, text)
    if not match:
        raise SystemExit(f"Unable to find definition for {var_name} in {BICEP_PATH}")
    return match.group(1)


def fetch_live_role_id(role_name: str) -> str:
    command = [
        "az",
        "role",
        "definition",
        "list",
        "--name",
        role_name,
        "--query",
        "[0].name",
        "-o",
        "tsv",
    ]
    result = subprocess.run(command, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        sys.stderr.write(result.stdout)
        sys.stderr.write(result.stderr)
        raise SystemExit(f"Failed to look up role definition for '{role_name}'. Did you login first?")
    role_id = result.stdout.strip()
    if not role_id:
        raise SystemExit(f"Azure CLI returned no role ID for '{role_name}'.")
    return role_id


def main() -> None:
    mismatches: list[str] = []
    for var_name, role_name in ROLE_NAME_BY_VAR.items():
        declared = extract_role_id(var_name)
        live = fetch_live_role_id(role_name)
        if declared.lower() != live.lower():
            mismatches.append(
                f"{var_name} expected '{live}' for '{role_name}', but roles.bicep has '{declared}'."
            )
    if mismatches:
        sys.stderr.write("Role definition mismatches detected:\n")
        sys.stderr.write("\n".join(f"- {msg}" for msg in mismatches) + "\n")
        raise SystemExit(1)
    print("Role definition IDs match Azure built-in roles.")


if __name__ == "__main__":
    main()
