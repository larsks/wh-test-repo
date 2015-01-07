#!/bin/sh

. /etc/sysconfig/heat-params

if [ "$FLANNEL_USE_VXLAN" == "true" ]; then
	use_vxlan=1
fi

# Generate a flannel configuration that we will
# store into etcd using curl.
cat > /etc/sysconfig/flannel-network.json <<EOF
{
  "Network": "$FLANNEL_NETWORK_CIDR",
  "Subnetlen": $FLANNEL_NETWORK_SUBNETLEN${use_vxlan:+",
  "Backend": {
    "Type": "vxlan"
  }"}
}
EOF

# wait for etcd to become active (we will need it to push the flanneld config)
while ! curl -sf http://localhost:4001/v2/keys/; do
  echo "waiting for etcd"
  sleep 1
done

# put the flannel config in etcd
echo "creating flanneld config in etcd"
curl -sf -L http://localhost:4001/v2/keys/coreos.com/network/config \
  -X PUT \
  --data-urlencode value@/etc/sysconfig/flannel-network.json


