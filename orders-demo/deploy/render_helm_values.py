#!/usr/bin/env python3
"""Render Helm override files from Bicep deployment outputs."""

import argparse
import json
from pathlib import Path
from typing import Any, Dict


def load_outputs(path: Path) -> Dict[str, Any]:
    data = json.loads(path.read_text())
    return {k: (v.get("value") if isinstance(v, dict) else v) for k, v in data.items()}


def write_values_file(path: Path, env: Dict[str, Any], secret_env: Dict[str, Any]) -> None:
    content = {
        "config": {
            "env": env,
            "secretEnv": secret_env,
        }
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(content, indent=2))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--outputs", required=True, type=Path)
    parser.add_argument("--api-values", required=True, type=Path)
    parser.add_argument("--worker-values", required=True, type=Path)
    args = parser.parse_args()

    outputs = load_outputs(args.outputs)

    namespace = outputs.get("eventHubNamespace")
    hub_name = outputs.get("eventHubName")
    storage_account = outputs.get("storageAccountName")
    storage_connection = outputs.get("storageConnectionString")
    ai_connection = outputs.get("applicationInsightsConnectionString")
    send_connection = outputs.get("eventHubSendConnection")
    listen_connection = outputs.get("eventHubListenConnection")

    fqdn = f"{namespace}.servicebus.windows.net" if namespace else None

    api_env: Dict[str, Any] = {"BACKEND_MODE": "eventhub"}
    worker_env: Dict[str, Any] = {"BACKEND_MODE": "eventhub"}

    if fqdn:
        api_env["EVENTHUB_NAMESPACE"] = fqdn
        worker_env["EVENTHUB_NAMESPACE"] = fqdn
    if hub_name:
        api_env["EVENTHUB_NAME"] = hub_name
        worker_env["EVENTHUB_NAME"] = hub_name
    if storage_account:
        worker_env["STORAGE_ACCOUNT"] = storage_account

    api_secret: Dict[str, Any] = {}
    worker_secret: Dict[str, Any] = {}

    if send_connection:
        api_secret["EVENTHUB_CONNECTION_STRING"] = send_connection
    if listen_connection:
        worker_secret["EVENTHUB_CONNECTION_STRING"] = listen_connection
    if storage_connection:
        worker_secret["STORAGE_CONNECTION_STRING"] = storage_connection
    if ai_connection:
        api_secret["APPLICATIONINSIGHTS_CONNECTION_STRING"] = ai_connection
        worker_secret["APPLICATIONINSIGHTS_CONNECTION_STRING"] = ai_connection

    write_values_file(args.api_values, api_env, api_secret)
    write_values_file(args.worker_values, worker_env, worker_secret)


if __name__ == "__main__":
    main()
