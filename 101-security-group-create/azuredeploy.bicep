param addressPrefix string {
  metadata: {
    description: 'Address prefix'
  }
  default: '10.0.0.0/16'
}
param subnetPrefix string {
  metadata: {
    description: 'Subnet-1 Prefix'
  }
  default: '10.0.0.0/24'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var networkSecurityGroupName = 'networkSecurityGroup1'
var virtualNetworkName = 'virtualNetwork1'
var subnetName = 'subnet'

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'first_rule'
        properties: {
          description: 'This is the first rule'
          protocol: 'Tcp'
          sourcePortRange: '23-45'
          destinationPortRange: '46-56'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 123
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroupName_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    networkSecurityGroupName_resource
  ]
}