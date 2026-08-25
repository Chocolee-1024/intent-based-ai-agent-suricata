#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ACTION="${1:-all}"
SURICATA_IMAGE="${SURICATA_IMAGE:-free5gmano/suricata-upf:latest}"
NAMESPACE="${NAMESPACE:-default}"
PUSH_SURICATA_IMAGE="${PUSH_SURICATA_IMAGE:-0}"
UPF_MANIFEST="${UPF_MANIFEST:-}"

build_image() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "找不到 docker，無法建置 Suricata image" >&2
    exit 1
  fi

  docker build -t "$SURICATA_IMAGE" "$SCRIPT_DIR"
  echo "已建置 Suricata image: $SURICATA_IMAGE"

  if [ "$PUSH_SURICATA_IMAGE" = "1" ]; then
    docker push "$SURICATA_IMAGE"
    echo "已推送 Suricata image: $SURICATA_IMAGE"
  fi
}

apply_rules() {
  kubectl apply -n "$NAMESPACE" -f "$SCRIPT_DIR/upf-suricata-rules.yaml"
}

patch_manifest() {
  if [ -z "$UPF_MANIFEST" ]; then
    echo "UPF_MANIFEST 未設定，略過 manifest image 同步"
    return
  fi

  if [ ! -f "$UPF_MANIFEST" ]; then
    echo "找不到 UPF manifest: $UPF_MANIFEST" >&2
    exit 1
  fi

  tmp_file="$(mktemp)"
  if ! awk -v image="$SURICATA_IMAGE" '
    /^[[:space:]]*- name:[[:space:]]*suricata-upf-container[[:space:]]*$/ {
      in_suricata = 1
      print
      next
    }
    in_suricata && /^[[:space:]]*image:[[:space:]]*/ {
      match($0, /^[[:space:]]*/)
      print substr($0, RSTART, RLENGTH) "image: " image
      in_suricata = 0
      changed = 1
      next
    }
    in_suricata && /^[[:space:]]*- name:/ {
      in_suricata = 0
    }
    { print }
    END {
      if (!changed) {
        exit 3
      }
    }
  ' "$UPF_MANIFEST" > "$tmp_file"; then
    rm -f "$tmp_file"
    echo "沒有找到 suricata-upf-container image 欄位，請檢查 manifest" >&2
    exit 1
  fi

  mv "$tmp_file" "$UPF_MANIFEST"
  echo "UPF manifest 已使用 Suricata image: $SURICATA_IMAGE"
}

case "$ACTION" in
  build)
    build_image
    ;;
  patch-manifest)
    patch_manifest
    ;;
  rules)
    apply_rules
    ;;
  all)
    build_image
    patch_manifest
    apply_rules
    ;;
  *)
    echo "Usage: SURICATA_IMAGE=<image> NAMESPACE=<ns> UPF_MANIFEST=<path> PUSH_SURICATA_IMAGE=0 $0 [build|patch-manifest|rules|all]" >&2
    exit 2
    ;;
esac
