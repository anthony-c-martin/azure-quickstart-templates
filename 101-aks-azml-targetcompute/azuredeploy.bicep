@description('The name of the Managed Cluster resource.')
param clusterName string

@description('The location of the Managed Cluster resource.')
param location string = resourceGroup().location

@minValue(30)
@maxValue(1023)
@description('Disk size (in GB) to provision for each of the agent pool nodes. This value minimun 30 to 1023. Specifying 100 is the default value required to be attached to Azure ML.')
param osDiskSizeGB int = 100

@minValue(1)
@maxValue(50)
@description('The number of nodes for the cluster.')
param agentCount int = 3

@description('A CIDR notation IP range from which to assign pod IPs when kubenet is used')
param podCidr string = '10.244.0.0/16'

@description('A CIDR notation IP range from which to assign service cluster IPs.')
param serviceCidr string = '10.0.0.0/16'

@description('An IP address assigned to the Kubernetes DNS service')
param dnsServiceIP string = '10.0.0.10'

@description('A specific IP address and netmask for the Docker bridge, using standard CIDR notation.')
param dockerBridgeCidr string = '172.17.0.1/16'

@description('The size of the VM instances.')
param agentVMSize string = 'Standard_D3_v2'

@description('Supported Azure Kubernetes version')
param kuberneteVersion string = '1.16.9'

@description('User name for the Linux Virtual Machines.')
param linuxAdminUsername string

@description('Configure all linux machines with the SSH RSA public key string. Your key should include three parts, for example \'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm\'')
param sshRSAPublicKey string

var dnsPrefix = clusterName

resource clusterName_resource 'Microsoft.ContainerService/managedClusters@2020-03-01' = {
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
      loadBalancerSku: 'basic'
      podCidr: podCidr
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP
      dockerBridgeCidr: dockerBridgeCidr
      outboundType: 'loadBalancer'
    }
  }
}

resource clusterName_agentpool 'Microsoft.ContainerService/managedClusters/agentPools@2020-03-01' = {
  parent: clusterName_resource
  name: 'agentpool'
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
}