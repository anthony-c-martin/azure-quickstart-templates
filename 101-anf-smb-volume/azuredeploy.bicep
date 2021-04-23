@description('Same location of resource group for all resources')
param location string = resourceGroup().location

@description('Name for the Account. The account name must be unique within the subscription')
param netappAccountName string = 'anfacc${uniqueString(resourceGroup().id)}'

@description('The value of Active Directory username')
param adUsername string

@description('The value of Active Directory password')
@secure()
param adPassword string

@description('SMB server name')
param smbServerName string

@description('Name for the capacity pool. The capacity pool name must be unique for each NetApp account.')
param netAppPoolName string = 'pool${uniqueString(resourceGroup().id)}'

@minValue(4398046511104)
@maxValue(549755813888000)
@description('Size of the capacity pool. The minimum  size is 4 TiB.')
param poolSizeBytes int = 4398046511104

@description('Name for the Volume. A volume name must be unique within each capacity pool. It must be at aleast three characters long and you can use any alphanumeric characters.')
param netAppVolumeName string = 'volume${uniqueString(resourceGroup().id)}'

@minValue(107374182400)
@maxValue(109951162777600)
@description('Amount of logical storage that is allocated to the volume.')
param volSizeBytes int = 107374182400

@description('The name of the subnet where the ANF volume will be created. This subnet will be delegated to Microsoft.NetApp/volumes.')
param anfSubnetName string = 'anfsubnet${uniqueString(resourceGroup().id)}'

@description('Subnet address range.')
param anfSubnetAddressPrefix string

@allowed([
  'Premium'
  'Ultra'
  'Standard'
])
@description('Target performance for the capacity pool. Service level: Ultra, Premium, or Standard.')
param serviceLevel string = 'Standard'

@description('IP Address of the existing AD DNS Controller')
param dnsIpAddress string

@description('Domain name for AD')
param domainName string

@description('SubscriptionId of the existing virtual network')
param virtualNetworkSubscriptionId string

@description('ResourceGroup name of the existing virtual network')
param virtualNetworkResourceGroupName string

@description('Name of the existing virtual network')
param virtualNetworkName string

module AddSubnet './nested_AddSubnet.bicep' = {
  name: 'AddSubnet'
  scope: resourceGroup(virtualNetworkSubscriptionId, virtualNetworkResourceGroupName)
  params: {
    virtualNetworkName: virtualNetworkName
    anfSubnetName: anfSubnetName
    location: location
    anfSubnetAddressPrefix: anfSubnetAddressPrefix
  }
}

resource netAppAccountName_resource 'Microsoft.NetApp/netAppAccounts@2020-06-01' = {
  name: netappAccountName
  location: location
  properties: {
    activeDirectories: [
      {
        username: adUsername
        password: adPassword
        domain: domainName
        dns: dnsIpAddress
        smbServerName: smbServerName
      }
    ]
  }
}

resource netAppAccountName_netAppPoolName 'Microsoft.NetApp/netAppAccounts/capacityPools@2020-06-01' = {
  parent: netAppAccountName_resource
  name: '${netAppPoolName}'
  location: location
  properties: {
    serviceLevel: serviceLevel
    size: poolSizeBytes
  }
}

resource netAppAccountName_netAppPoolName_netAppVolumeName 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2020-06-01' = {
  parent: netAppAccountName_netAppPoolName
  name: netAppVolumeName
  location: location
  properties: {
    serviceLevel: serviceLevel
    creationToken: netAppVolumeName
    usageThreshold: volSizeBytes
    subnetId: resourceId(virtualNetworkSubscriptionId, virtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, anfSubnetName)
  }
  dependsOn: [
    AddSubnet
  ]
}

output smbServerFQDN string = netAppAccountName_netAppPoolName_netAppVolumeName.properties.mountTargets[0].smbServerFqdn