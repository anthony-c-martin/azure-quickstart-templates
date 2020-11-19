param vnetname string {
  metadata: {
    description: 'Name of the virtual network'
  }
  default: 'myVnet'
}
param subnetname string {
  metadata: {
    description: 'Name of the subnet for virtual network'
  }
  default: 'mySubnet'
}
param vnetaddressspace string {
  metadata: {
    description: 'Address space for virtual network'
  }
  default: '192.168.0.0/16'
}
param vnetsubnetprefix string {
  metadata: {
    description: 'Subnet prefix for virtual network'
  }
  default: '192.168.0.0/24'
}
param natgatewayname string {
  metadata: {
    description: 'Name of the NAT gateway resource'
  }
  default: 'myNATgateway'
}
param publicipdns string {
  metadata: {
    description: 'dns of the public ip address, leave blank for no dns'
  }
  default: 'gw-${uniqueString(resourceGroup().id)}'
}
param location string {
  metadata: {
    description: 'Location of resources'
  }
  default: resourceGroup().location
}

var publicIpName = '${natgatewayname}ip'
var publicIpAddresses = [
  {
    id: publicIpName_resource.id
  }
]

resource publicIpName_resource 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: publicIpName
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
  dependsOn: [
    publicIpName_resource
  ]
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
  dependsOn: [
    natgatewayname_resource
  ]
}

resource vnetname_mySubnet 'Microsoft.Network/virtualNetworks/subnets@2019-11-01' = {
  name: '${vnetname}/mySubnet'
  properties: {
    addressPrefix: vnetsubnetprefix
    natGateway: {
      id: natgatewayname_resource.id
    }
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  dependsOn: [
    vnetname_resource
    natgatewayname_resource
  ]
}