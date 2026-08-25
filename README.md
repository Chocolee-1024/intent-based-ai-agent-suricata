# intent-based-ai-agent-suricata

Minimal Suricata assets for the intent-based 5G UPF environment.

## One Script

```bash
SURICATA_IMAGE=your-registry/suricata-upf:latest PUSH_SURICATA_IMAGE=1 ./suricata.sh all
```

Only build the image:

```bash
./suricata.sh build
```

Only apply UPF rules:

```bash
NAMESPACE=default ./suricata.sh rules
```

Patch the UPF manifest image only:

```bash
UPF_MANIFEST=../free5gmano_SecurityManagement/deploy/free5gc-stage-3.0.6/03-free5gc-upf.yaml \
SURICATA_IMAGE=your-registry/suricata-upf:latest \
./suricata.sh patch-manifest
```

UPF logs:

```bash
kubectl logs deploy/free5gc-upf-deployment -c suricata-upf-container
```
