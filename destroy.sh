#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$REPO_ROOT/terraform"
ANSIBLE_DIR="$REPO_ROOT/ansible"

echo "==> Destruyendo toda la infraestructura de Azure"
cd "$TF_DIR"
terraform destroy -auto-approve

echo "==> Limpiando artefactos locales generados"
rm -f "$ANSIBLE_DIR/clave_vm.pem" "$ANSIBLE_DIR/hosts" "$ANSIBLE_DIR/group_vars/secrets.yml"

echo "✅ Entorno destruido y limpio."