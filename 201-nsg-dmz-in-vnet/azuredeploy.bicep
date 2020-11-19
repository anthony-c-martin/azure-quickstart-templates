param virtualNetworkName string {
  metadata: {
    description: 'This is your Virtual Network'
  }
  default: 'First_ARM_VNet'
}
param addressPrefix string {
  metadata: {
    description: 'The CIDR address space for your Virtual Network in Azure'
  }
  default: '10.0.0.0/16'
}
param FESubnetPrefix string {
  metadata: {
    description: 'This is CIDR prefix for the FrontEnd Subnet'
  }
  default: '10.0.0.0/24'
}
param AppSubnetPrefix string {
  metadata: {
    description: 'This is CIDR prefix for the Application Subnet'
  }
  default: '10.0.1.0/24'
}
param DBSubnetPrefix string {
  metadata: {
    description: 'This is CIDR prefix for the Database Subnet'
  }
  default: '10.0.2.0/24'
}
param FENSGName string {
  metadata: {
    description: 'This is name of the networkSecurityGroup that will be assigned to FrontEnd Subnet'
  }
  default: 'FE_NSG'
}
param AppNSGName string {
  metadata: {
    description: 'This is name of the networkSecurityGroup that will be assigned to Application Subnet'
  }
  default: 'App_NSG'
}
param DBNSGName string {
  metadata: {
    description: 'This is name of the networkSecurityGroup that will be assigned to Database Subnet'
  }
  default: 'DB_NSG'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource FENSGName_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: FENSGName
  location: location
  properties: {
    securityRules: [
      {
        name: 'rdp_rule'
        properties: {
          description: 'Allow RDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'web_rule'
        properties: {
          description: 'Allow WEB'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource AppNSGName_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: AppNSGName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow_FE'
        properties: {
          description: 'Allow FE Subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: FESubnetPrefix
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Block_RDP_Internet'
        properties: {
          description: 'Block RDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 101
          direction: 'Inbound'
        }
      }
      {
        name: 'Block_Internet_Outbound'
        properties: {
          description: 'Block Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Deny'
          priority: 200
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource DBNSGName_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: DBNSGName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow_App'
        properties: {
          description: 'Allow APP Subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: AppSubnetPrefix
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Block_FE'
        properties: {
          description: 'Block FE Subnet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: FESubnetPrefix
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 101
          direction: 'Inbound'
        }
      }
      {
        name: 'Block_App'
        properties: {
          description: 'Block App Subnet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: AppSubnetPrefix
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 102
          direction: 'Inbound'
        }
      }
      {
        name: 'Block_Internet'
        properties: {
          description: 'Block Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Deny'
          priority: 200
          direction: 'Outbound'
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
        name: 'FESubnet'
        properties: {
          addressPrefix: FESubnetPrefix
          networkSecurityGroup: {
            id: FENSGName_resource.id
          }
        }
      }
      {
        name: 'AppSubnet'
        properties: {
          addressPrefix: AppSubnetPrefix
          networkSecurityGroup: {
            id: AppNSGName_resource.id
          }
        }
      }
      {
        name: 'DBSubnet'
        properties: {
          addressPrefix: DBSubnetPrefix
          networkSecurityGroup: {
            id: DBNSGName_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    FENSGName_resource
    AppNSGName_resource
    DBNSGName_resource
  ]
}