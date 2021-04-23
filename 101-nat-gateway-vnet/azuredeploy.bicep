@description('Name of the virtual network')
param vnetname string = 'myVnet'

@description('Name of the subnet for virtual network')
param subnetname string = 'mySubnet'

@description('Address space for virtual network')
param vnetaddressspace string = '192.168.0.0/16'

@description('Subnet prefix for virtual network')
param vnetsubnetprefix string = '192.168.0.0/24'

@description('Name of the NAT gateway resource')
param natgatewayname string = 'myNATgateway'

@description('dns of the public ip address, leave blank for no dns')
param publicipdns string = 'gw-${uniqueString(resourceGroup().id)}'

@description('Location of resources')
param location string = resourceGroup().location

var publicIpName_var = '${natgatewayname}ip'
var publicIpAddresses = [
  {
    id: publicIpName.id
  }
]

resource publicIpName 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: publicIpName_var
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: publicipdns
    }
  }
}

resource natgatewayname_resource 'Microsoft.Network/natGateways@2019-11-01' = {
  name: natgatewayname
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: ((!empty(publicipdns)) ? publicIpAddresses : json('null'))
  }
}

resource vnetname_resource 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: vnetname
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetaddressspace
      ]
    }
    subnets: [
      {
        name: subnetname
        properties: {
          addressPrefix: vnetsubnetprefix
          natGateway: {
            id: natgatewayname_resource.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
    enableVmProtection: false
  }
}

resource vnetname_mySubnet 'Microsoft.Network/virtualNetworks/subnets@2019-11-01' = {
  parent: vnetname_resource
  name: 'mySubnet'
  properties: {
    addressPrefix: vnetsubnetprefix
    natGateway: {
      id: natgatewayname_resource.id
    }
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}