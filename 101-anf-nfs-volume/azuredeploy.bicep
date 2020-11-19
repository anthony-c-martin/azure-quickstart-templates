param location string {
  metadata: {
    description: 'Same Location of resource group for all resources in the same deployment.'
  }
  default: resourceGroup().location
}
param netAppAccountName string {
  metadata: {
    description: 'Name for the Account. The account name must be unique within the subscription'
  }
  default: 'anfacc${uniqueString(resourceGroup().id)}'
}
param netAppPoolName string {
  metadata: {
    description: 'Name for the capacity pool. The capacity pool name must be unique for each NetApp account.'
  }
  default: 'pool${uniqueString(resourceGroup().id)}'
}
param poolSizeBytes int {
  minValue: '4398046511104'
  maxValue: '549755813888000'
  metadata: {
    description: 'Size of the capacity pool. The minimum  size is 4 TiB.'
  }
  default: '4398046511104'
}
param netAppVolumeName string {
  metadata: {
    description: 'Name for the NFS Volume. A volume name must be unique within each capacity pool. It must be at aleast three characters long and you can use any alphanumeric characters.'
  }
  default: 'volume${uniqueString(resourceGroup().id)}'
}
param volSizeBytes int {
  minValue: '107374182400'
  maxValue: '109951162777600'
  metadata: {
    description: 'Amount of logical storage that is allocated to the volume.'
  }
  default: '107374182400'
}
param virtualNetworkName string {
  metadata: {
    description: 'Name of the Virtual Network (VNet) from which you want to access the volume. The VNet must have a subnet delegated to Azure NetApp Files.'
  }
  default: 'anfvnet${uniqueString(resourceGroup().id)}'
}
param vnetAddressPrefix string {
  metadata: {
    description: 'Virtual Network address range.'
  }
  default: '10.0.0.0/16'
}
param allowedClients string {
  metadata: {
    description: 'Root Access to the volume.'
  }
  default: '0.0.0.0/0'
}
param subnetName string {
  metadata: {
    description: 'Subnet name that you want to use for the volume. The subnet must be delegated to Azure NetApp Files.'
  }
  default: 'anfsubnet${uniqueString(resourceGroup().id)}'
}
param subnetAddressPrefix string {
  metadata: {
    description: 'Subnet address range.'
  }
  default: '10.0.0.0/24'
}
param serviceLevel string {
  allowed: [
    'Premium'
    'Ultra'
    'Standard'
  ]
  metadata: {
    description: 'Target performance for the capacity pool. Service level: Ultra, Premium, or Standard.'
  }
  default: 'Standard'
}
param protocolTypes string {
  allowed: [
    'NFSv3'
    'NFSv4.1'
  ]
  metadata: {
    description: 'NFS version (NFSv3 or NFSv4.1) for the volume.'
  }
  default: 'NFSv3'
}
param unixReadOnly bool {
  allowed: [
    false
    true
  ]
  metadata: {
    description: 'Read only flag.'
  }
  default: false
}
param unixReadWrite bool {
  allowed: [
    false
    true
  ]
  metadata: {
    description: 'Read/write flag.'
  }
  default: true
}
param snapshotDirectoryVisible bool {
  allowed: [
    false
    true
  ]
  metadata: {
    description: 'Snapshot directory visible flag.'
  }
  default: false
}

var capacityPoolName = '${netAppAccountName}/${netAppPoolName}'
var volumeName = '${netAppAccountName}/${netAppPoolName}/${netAppVolumeName}'

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          delegations: [
            {
              name: 'NetAppDelegation'
              properties: {
                serviceName: 'Microsoft.NetApp/volumes'
              }
            }
          ]
        }
      }
    ]
  }
}

resource netAppAccountName_resource 'Microsoft.NetApp/netAppAccounts@2020-06-01' = {
  name: netAppAccountName
  location: location
  properties: {}
}

resource capacityPoolName_resource 'Microsoft.NetApp/netAppAccounts/capacityPools@2020-06-01' = {
  name: capacityPoolName
  location: location
  properties: {
    serviceLevel: serviceLevel
    size: poolSizeBytes
  }
  dependsOn: [
    netAppAccountName_resource
  ]
}

resource volumeName_resource 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2020-06-01' = {
  name: volumeName
  location: location
  properties: {
    serviceLevel: serviceLevel
    creationToken: netAppVolumeName
    usageThreshold: volSizeBytes
    exportPolicy: {
      rules: [
        {
          ruleIndex: 1
          unixReadOnly: unixReadOnly
          unixReadWrite: unixReadWrite
          cifs: false
          nfsv3: ((protocolTypes == 'NFSv3') ? bool('true') : bool('false'))
          nfsv41: ((protocolTypes == 'NFSv4.1') ? bool('true') : bool('false'))
          allowedClients: allowedClients
        }
      ]
    }
    protocolTypes: [
      protocolTypes
    ]
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
    snapshotDirectoryVisible: snapshotDirectoryVisible
  }
  dependsOn: [
    resourceId('Microsoft.NetApp/netAppAccounts/capacityPools', netAppAccountName, netAppPoolName)
    virtualNetworkName_resource
  ]
}