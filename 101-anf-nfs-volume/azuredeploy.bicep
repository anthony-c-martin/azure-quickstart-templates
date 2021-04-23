@description('Same Location of resource group for all resources in the same deployment.')
param location string = resourceGroup().location

@description('Name for the Account. The account name must be unique within the subscription')
param netAppAccountName string = 'anfacc${uniqueString(resourceGroup().id)}'

@description('Name for the capacity pool. The capacity pool name must be unique for each NetApp account.')
param netAppPoolName string = 'pool${uniqueString(resourceGroup().id)}'

@minValue(4398046511104)
@maxValue(549755813888000)
@description('Size of the capacity pool. The minimum  size is 4 TiB.')
param poolSizeBytes int = 4398046511104

@description('Name for the NFS Volume. A volume name must be unique within each capacity pool. It must be at aleast three characters long and you can use any alphanumeric characters.')
param netAppVolumeName string = 'volume${uniqueString(resourceGroup().id)}'

@minValue(107374182400)
@maxValue(109951162777600)
@description('Amount of logical storage that is allocated to the volume.')
param volSizeBytes int = 107374182400

@description('Name of the Virtual Network (VNet) from which you want to access the volume. The VNet must have a subnet delegated to Azure NetApp Files.')
param virtualNetworkName string = 'anfvnet${uniqueString(resourceGroup().id)}'

@description('Virtual Network address range.')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Root Access to the volume.')
param allowedClients string = '0.0.0.0/0'

@description('Subnet name that you want to use for the volume. The subnet must be delegated to Azure NetApp Files.')
param subnetName string = 'anfsubnet${uniqueString(resourceGroup().id)}'

@description('Subnet address range.')
param subnetAddressPrefix string = '10.0.0.0/24'

@allowed([
  'Premium'
  'Ultra'
  'Standard'
])
@description('Target performance for the capacity pool. Service level: Ultra, Premium, or Standard.')
param serviceLevel string = 'Standard'

@allowed([
  'NFSv3'
  'NFSv4.1'
])
@description('NFS version (NFSv3 or NFSv4.1) for the volume.')
param protocolTypes string = 'NFSv3'

@allowed([
  false
  true
])
@description('Read only flag.')
param unixReadOnly bool = false

@allowed([
  false
  true
])
@description('Read/write flag.')
param unixReadWrite bool = true

@allowed([
  false
  true
])
@description('Snapshot directory visible flag.')
param snapshotDirectoryVisible bool = false

var capacityPoolName_var = '${netAppAccountName}/${netAppPoolName}'
var volumeName_var = '${netAppAccountName}/${netAppPoolName}/${netAppVolumeName}'

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

resource capacityPoolName 'Microsoft.NetApp/netAppAccounts/capacityPools@2020-06-01' = {
  name: capacityPoolName_var
  location: location
  properties: {
    serviceLevel: serviceLevel
    size: poolSizeBytes
  }
  dependsOn: [
    netAppAccountName_resource
  ]
}

resource volumeName 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2020-06-01' = {
  name: volumeName_var
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