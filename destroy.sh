#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$REPO_ROOT/terraform"
ANSIBLE_DIR="$REPO_ROOT/ansible"

echo "==> Inicializando Terraform"
cd "$TF_DIR"
terraform init -input=false

echo "==> Destruyendo toda la infraestructura de Azure"
terraform destroy -auto-approve

echo "==> Limpiando artefactos locales generados"
rm -f "$ANSIBLE_DIR/clave_vm.pem" "$ANSIBLE_DIR/kubeconfig" "$ANSIBLE_DIR/hosts" "$ANSIBLE_DIR/group_vars/secrets.yml" "$ANSIBLE_DIR/.encuesta_external_ip"

echo "✅ Entorno destruido y limpio."
