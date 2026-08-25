FROM ubuntu:22.04

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates \
      iproute2 \
      suricata \
      tcpdump && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/suricata /etc/suricata/rules && \
    touch /etc/suricata/rules/local.rules

ENV SURICATA_IFACE=upfgtp
ENV SURICATA_CONFIG=/etc/suricata/suricata.yaml
ENV SURICATA_RULE_FILE=/etc/suricata/rules/local.rules
ENV SURICATA_LOG_DIR=/var/log/suricata

CMD set -eu; \
    iface="${SURICATA_IFACE:-upfgtp}"; \
    config="${SURICATA_CONFIG:-/etc/suricata/suricata.yaml}"; \
    rules="${SURICATA_RULE_FILE:-/etc/suricata/rules/local.rules}"; \
    log_dir="${SURICATA_LOG_DIR:-/var/log/suricata}"; \
    wait_seconds="${SURICATA_WAIT_SECONDS:-60}"; \
    mkdir -p "$log_dir"; \
    elapsed=0; \
    while ! ip link show "$iface" >/dev/null 2>&1; do \
      if [ "$elapsed" -ge "$wait_seconds" ]; then \
        if ip link show eth1 >/dev/null 2>&1; then iface=eth1; break; fi; \
        if ip link show eth0 >/dev/null 2>&1; then iface=eth0; break; fi; \
        echo "Suricata interface not found: ${SURICATA_IFACE:-upfgtp}" >&2; \
        exit 1; \
      fi; \
      sleep 1; \
      elapsed=$((elapsed + 1)); \
    done; \
    touch "$log_dir/fast.log" "$log_dir/eve.json"; \
    tail -n +1 -F "$log_dir/fast.log" "$log_dir/eve.json" & \
    echo "Starting Suricata on interface: $iface"; \
    exec suricata -c "$config" -i "$iface" -l "$log_dir" -S "$rules" -k none ${SURICATA_EXTRA_ARGS:-}
