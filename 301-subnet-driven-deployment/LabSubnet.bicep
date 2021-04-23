@description('VNet prefix (CIDR)')
param labVNetPrefix string

@description('Array of subnets to be created')
param subnets array

@description('Unique public DNS label for the deployment. The fqdn will look something like \'<dnsname>.<region>.cloudapp.azure.com\'. Up to 62 chars, digits or dashes, lowercase, should start with a letter: must conform to \'^[a-z][a-z0-9-]{1,61}[a-z0-9]$\'.')
param dnsLabel string

@description('Virtual Network name')
param vnetName string = 'labVNet'

@description('Public address name, for lb configuration.')
param publicIPAddressName string = 'PublicIP'

@description('Name of the subnet to add')
param addedSubnetName string

@description('CIDR prefix of the subnet to add')
param addedSubnetPrefix string

@description('Location for all resources.')
param location string = resourceGroup().location

var location_var = location
var publicIPAddressName_var = uniqueString(resourceGroup().id, 'PublicIP')
var lbName_var = uniqueString(resourceGroup().id, 'labLB')
var sbn = [
  {
    name: addedSubnetName
    properties: {
      addressPrefix: addedSubnetPrefix
    }
  }
]

resource lbName 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: lbName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontend'
        properties: {
          publicIPAddress: {
            id: publicIPAddressName_resource.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'LoadBalancerBackend'
      }
    ]
  }
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName
  location: location_var
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsLabel
    }
  }
}

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: vnetName
  location: location
  tags: {
    displayName: vnetName
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        labVNetPrefix
      ]
    }
    subnets: concat(subnets, sbn)
  }
  dependsOn: [
    publicIPAddressName_resource
  ]
}

output vnetSubnets array = reference(vnetName).subnets
output vnetLength int = length(reference(vnetName).subnets)
output publicIPAddressName string = publicIPAddressName_var
output lbName string = lbName_var