# BARONos 

An immutible, bootable, a/b upgradable k8s-serving distribution.

This isn't so much an OS, as much as it's a rebranding of Ubuntu, and a packaging of Kairos.

This repo implements that as a Kairos "custom build" option, merging an Ubuntu 22-lts image with Kairos framework, and a fork of github.com/kairos-io/provider-microk8s.

## What's next

- Registration & Backhaul Option 1
  - Bootstrap AWS Greengrass in microk8s
  - Authenticate using yubiHSM
- Registration & Backhaul Option 2
  - Use flux2 repo https://github.com/cmbaron/blade-config
  - Authenticate with yubikey using PKCS#11
  - setup openvpn for backhaul, authenticated with PKCS#11

## Configuration

`cluster_token`: a token all members of the cluster must have to join the cluster.

`control_plane_host`: the host of the cluster control plane.  This is used to join nodes to a cluster.  If this is a single node cluster this is not required.

`role`: defines what operations is this device responsible for. The roles are described in detail below.
- `init` This role denotes a device that should initialize the dqlite cluster and operate as a Microk8s control plane.  There should only be one device with this role per cluster.
- `controlplane`: runs the Microk8s control plane.
- `worker`: runs the  Microk8s worker.

`config`: User provided configuration for microk8s. It supports the following configuration entries
 - `clusterConfiguration`: Defense cluster level parameters
 
          # Changes the default cluster agent port and the dqlite ports to use 30000 and 6443 which might be more likely to be open in firewalls
          `portCompatibilityRemap` : true
          
          # Writes the kubeconfig to a specified location
          `writeKubeconfig`: "/run/kubeconfig" 
          
          # Switch dqlite to use the internal IP of the Node instead of the 127.0.0.1 
          `dqliteUseHostIPV4Address`: true
          
          # Uses the  DNS server entries from the host for the coredns configuration(reads from /etc/resolv.conf)
          `useHostDNS`: true
          
          # Specifies custom DNs server. Overrides the previous setting
          `DNS` : 75.75.74.74
          # Customize calico settings
          `calico`: 
             # Enable IpinIP
             `calicoIPinIP`: true
             # Change the calico IP_AUTODETECTION_METHOD env . By default When forming a MicroK8s cluster, Calico is updated to use address that was used in the microk8s join command (IP_AUTODETECTION_METHOD=can-reach=10.10.10.10)
             `calicoAutoDetect`: "cidr=10.10.128.0/18"  
  -  `initConfiguration`: Configuration only for the init node

           addons:
              - dns

### Example
```yaml
#cloud-config

cluster:
  cluster_token: randomstring
  control_plane_host: cluster.example.com
  role: init
  config: |
    clusterConfiguration:
          # Changes the default cluster agent port 
          portCompatibilityRemap : true
          writeKubeconfig: "/run/kubeconfig"
          dqliteUseHostIPV4Address: true
          useHostDNS: true
          calico: 
             calicoIPinIP: true
             calicoAutoDetect: "cidr=10.10.128.0/18"
    initConfiguration:
                  addons:
                    - dns
