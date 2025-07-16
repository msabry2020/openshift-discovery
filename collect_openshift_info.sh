#!/bin/bash

# Output directory
OUTPUT_DIR="openshift_diagnostic_outputs"
mkdir -p "$OUTPUT_DIR"

echo "[INFO] Collecting OpenShift configuration and diagnostic data..."

#########################################
# Registry Info
#########################################
echo "[INFO] Exporting Image Registry configurations..."
oc get configs.imageregistry.operator.openshift.io cluster -o yaml > "$OUTPUT_DIR/image-registry-config.yaml"
oc get image.config.openshift.io cluster -o yaml > "$OUTPUT_DIR/image-cluster-config.yaml"
oc get deployments/image-registry -n openshift-image-registry -o yaml > "$OUTPUT_DIR/image-registry-deployment.yaml"

#########################################
# Network Info
#########################################
echo "[INFO] Exporting Network configurations..."
oc get networks.config.openshift.io cluster -o yaml > "$OUTPUT_DIR/network-config.yaml"
oc get -o yaml proxy/cluster > "$OUTPUT_DIR/network-config.yaml"

#########################################
# Storage Info
#########################################
echo "[INFO] Exporting Storage resources (summary and YAML)..."
oc get localvolumesets,storagecluster,cephcluster,sc,pv,pvc -A > "$OUTPUT_DIR/storage-summary.txt"
oc get localvolumesets,storagecluster,cephcluster,sc,pv,pvc -A -o yaml > "$OUTPUT_DIR/storage-resources.yaml"

#########################################
# Security Info
#########################################
echo "[INFO] Exporting Security configurations..."
oc get oauth/cluster -o yaml > "$OUTPUT_DIR/oauth-cluster.yaml"
oc get user,group > "$OUTPUT_DIR/users-and-groups.txt"
oc get clusterrolebindings -o yaml > "$OUTPUT_DIR/clusterrolebindings.yaml"
oc get rolebindings -A -o yaml > "$OUTPUT_DIR/rolebindings.yaml"

#########################################
# Certificate Info
#########################################
echo "[INFO] Exporting Certificate details..."

# Ingress certificate
ingressCert=$(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.spec.defaultCertificate.name}')
if [ -n "$ingressCert" ]; then
  echo "[INFO] Found ingress certificate: $ingressCert"
  oc get secret $ingressCert -n openshift-ingress -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -text > "$OUTPUT_DIR/ingress-certificate-details.txt"
else
  oc get secret router-certs-default -n openshift-ingress -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -text > "$OUTPUT_DIR/ingress-certificate-details.txt"
fi

# API certificate
apiCert=$(oc get apiserver cluster -o jsonpath='{.spec.servingCerts.namedCertificates[].servingCertificate.name}')
if [ -n "$apiCert" ]; then
  echo "[INFO] Found API server certificate: $apiCert"
  oc get secret $apiCert -n openshift-config -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -text > "$OUTPUT_DIR/api-certificate-details.txt"
else
  oc get secret external-loadbalancer-serving-certkey -n openshift-kube-apiserver -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -text > "$OUTPUT_DIR/api-certificate-details.txt"
fi

echo "[DONE] All outputs saved in: $OUTPUT_DIR"
