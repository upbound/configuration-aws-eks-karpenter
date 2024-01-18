#!/usr/bin/env bash
set -aeuo pipefail

echo "Running setup.sh"
echo "Waiting until all configurations are healthy/installed..."
"${KUBECTL}" wait configuration.pkg --all --for=condition=Healthy --timeout 5m
"${KUBECTL}" wait configuration.pkg --all --for=condition=Installed --timeout 5m
"${KUBECTL}" wait configurationrevisions.pkg --all --for=condition=Healthy --timeout 5m

echo "Creating cloud credential secret..."
"${KUBECTL}" -n upbound-system create secret generic aws-creds --from-literal=credentials="${UPTEST_CLOUD_CREDENTIALS}" \
    --dry-run=client -o yaml | "${KUBECTL}" apply -f -

echo "Waiting until all installed provider packages are healthy..."
"${KUBECTL}" wait provider.pkg --all --for condition=Healthy --timeout 5m

echo "Waiting for all pods to come online..."
"${KUBECTL}" -n upbound-system wait --for=condition=Available deployment --all --timeout=5m

echo "Waiting for all XRDs to be established..."
"${KUBECTL}" wait xrd --all --for condition=Established

echo "Creating a default provider config..."
cat <<EOF | "${KUBECTL}" apply -f -
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    secretRef:
      key: credentials
      name: aws-creds
      namespace: upbound-system
    source: Secret
EOF

SCRIPT_DIR=$( cd -- $( dirname -- "${BASH_SOURCE[0]}" ) &> /dev/null && pwd )

"${KUBECTL}" apply -f ${SCRIPT_DIR}/../examples/eks-xr.yaml

# Function to extract the annotation from a resource
get_annotation() {
    local resource_json="$1"
    local annotation="$2"
    annotation_value=$(echo "$resource_json" | grep -o "\"$annotation\": \"[^\"]*\"" | cut -d '"' -f 4)
    echo "$annotation_value"
}

# Watch for changes to the resource and extract the annotation
while true; do
    resource_info=$(kubectl get cluster.eks.aws.upbound.io -o json)
    annotation_value=$(get_annotation "$resource_info" "crossplane.io/external-name")

    if [ -n "$annotation_value" ]; then
        cat <<EOF | "${KUBECTL}" apply -f -
apiVersion: aws.platform.upbound.io/v1alpha1
kind: XKarpenter
metadata:
  name: configuration-aws-eks-karpenter
spec:
  parameters:
    clusterName: $annotation_value
    id: configuration-aws-eks-karpenter
    region: us-west-2
EOF
        exit 0
    fi

    sleep 1
done
