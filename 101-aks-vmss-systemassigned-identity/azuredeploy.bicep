param aksClusterName string {
  metadata: {
    description: 'The name of the Managed Cluster resource.'
  }
  default: 'aks101cluster-vmss'
}
param location string {
  metadata: {
    description: 'The location of AKS resource.'
  }
  default: resourceGroup().location
}
param dnsPrefix string {
  metadata: {
    description: 'Optional DNS prefix to use with hosted Kubernetes API server FQDN.'
  }
}
param osDiskSizeGB int {
  minValue: 0
  maxValue: 1023
  metadata: {
    description: 'Disk size (in GiB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.'
  }
  default: 0
}
param agentCount int {
  minValue: 1
  maxValue: 100
  metadata: {
    description: 'The number of nodes for the cluster. 1 Node is enough for Dev/Test and minimum 3 nodes, is recommended for Production'
  }
  default: 3
}
param agentVMSize string {
  metadata: {
    description: 'The size of the Virtual Machine.'
  }
  default: 'Standard_DS2_v2'
}
param osType string {
  allowed: [
    'Linux'
    'Windows'
  ]
  metadata: {
    description: 'The type of operating system.'
  }
  default: 'Linux'
}

resource aksClusterName_resource 'Microsoft.ContainerService/managedClusters@2020-07-01' = {
  location: location
  name: aksClusterName
  tags: {
    displayname: 'AKS Cluster'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enableRBAC: true
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: osDiskSizeGB
        count: agentCount
        vmSize: agentVMSize
        osType: osType
        storageProfile: 'ManagedDisks'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
      }
    ]
  }
}

output controlPlaneFQDN string = aksClusterName_resource.properties.fqdn