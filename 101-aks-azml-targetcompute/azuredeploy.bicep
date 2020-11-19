param clusterName string {
  metadata: {
    description: 'The name of the Managed Cluster resource.'
  }
}
param location string {
  metadata: {
    description: 'The location of the Managed Cluster resource.'
  }
  default: resourceGroup().location
}
param osDiskSizeGB int {
  minValue: 30
  maxValue: 1023
  metadata: {
    description: 'Disk size (in GB) to provision for each of the agent pool nodes. This value minimun 30 to 1023. Specifying 100 is the default value required to be attached to Azure ML.'
  }
  default: 100
}
param agentCount int {
  minValue: 1
  maxValue: 50
  metadata: {
    description: 'The number of nodes for the cluster.'
  }
  default: 3
}
param podCidr string {
  metadata: {
    description: 'A CIDR notation IP range from which to assign pod IPs when kubenet is used'
  }
  default: '10.244.0.0/16'
}
param serviceCidr string {
  metadata: {
    description: 'A CIDR notation IP range from which to assign service cluster IPs.'
  }
  default: '10.0.0.0/16'
}
param dnsServiceIP string {
  metadata: {
    description: 'An IP address assigned to the Kubernetes DNS service'
  }
  default: '10.0.0.10'
}
param dockerBridgeCidr string {
  metadata: {
    description: 'A specific IP address and netmask for the Docker bridge, using standard CIDR notation.'
  }
  default: '172.17.0.1/16'
}
param agentVMSize string {
  metadata: {
    description: 'The size of the VM instances.'
  }
  default: 'Standard_D3_v2'
}
param kuberneteVersion string {
  metadata: {
    description: 'Supported Azure Kubernetes version'
  }
  default: '1.16.9'
}
param linuxAdminUsername string {
  metadata: {
    description: 'User name for the Linux Virtual Machines.'
  }
}
param sshRSAPublicKey string {
  metadata: {
    description: 'Configure all linux machines with the SSH RSA public key string. Your key should include three parts, for example \'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm\''
  }
}

var dnsPrefix = clusterName

resource clusterName_res 'Microsoft.ContainerService/managedClusters@2020-03-01' = {
  name: clusterName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Free'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: kuberneteVersion
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 3
        vmSize: agentVMSize
        osDiskSizeGB: osDiskSizeGB
        maxPods: 110
        type: 'VirtualMachineScaleSets'
        orchestratorVersion: kuberneteVersion
        mode: 'System'
        osType: 'Linux'
      }
    ]
    linuxProfile: {
      adminUsername: linuxAdminUsername
      ssh: {
        publicKeys: [
          {
            keyData: sshRSAPublicKey
          }
        ]
      }
    }
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    nodeResourceGroup: 'MC_${resourceGroup().name}_${clusterName}_${location}'
    enableRBAC: true
    networkProfile: {
      networkPlugin: 'kubenet'
      loadBalancerSku: 'Basic'
      podCidr: podCidr
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP
      dockerBridgeCidr: dockerBridgeCidr
      outboundType: 'loadBalancer'
    }
  }
}

resource clusterName_agentpool 'Microsoft.ContainerService/managedClusters/agentPools@2020-03-01' = {
  name: '${clusterName}/agentpool'
  properties: {
    count: agentCount
    vmSize: agentVMSize
    osDiskSizeGB: osDiskSizeGB
    maxPods: 110
    type: 'VirtualMachineScaleSets'
    orchestratorVersion: kuberneteVersion
    mode: 'System'
    osType: 'Linux'
  }
  dependsOn: [
    clusterName_res
  ]
}