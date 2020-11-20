param managedInstanceName string {
  metadata: {
    description: 'Enter managed instance name.'
  }
}
param administratorLogin string {
  metadata: {
    description: 'Enter user name.'
  }
}
param administratorLoginPassword string {
  metadata: {
    description: 'Enter password.'
  }
  secure: true
}
param location string {
  metadata: {
    description: 'Enter location. If you leave this field blank resource group location would be used.'
  }
  default: resourceGroup().location
}
param virtualNetworkName string {
  metadata: {
    description: 'Enter virtual network name. If you leave this field blank name will be created by the template.'
  }
  default: 'SQLMI-VNET'
}
param addressPrefix string {
  metadata: {
    description: 'Enter virtual network address prefix.'
  }
  default: '10.0.0.0/16'
}
param subnetName string {
  metadata: {
    description: 'Enter subnet name.'
  }
  default: 'ManagedInstance'
}
param subnetPrefix string {
  metadata: {
    description: 'Enter subnet address prefix.'
  }
  default: '10.0.0.0/24'
}
param skuName string {
  allowed: [
    'GP_Gen5'
    'BC_Gen5'
  ]
  metadata: {
    description: 'Enter sku name.'
  }
  default: 'GP_Gen5'
}
param vCores int {
  allowed: [
    8
    16
    24
    32
    40
    64
    80
  ]
  metadata: {
    description: 'Enter number of vCores.'
  }
  default: 16
}
param storageSizeInGB int {
  minValue: 32
  maxValue: 8192
  metadata: {
    description: 'Enter storage size.'
  }
  default: 256
}
param licenseType string {
  allowed: [
    'BasePrice'
    'LicenseIncluded'
  ]
  metadata: {
    description: 'Enter license type.'
  }
  default: 'LicenseIncluded'
}

var networkSecurityGroupName_var = 'SQLMI-${managedInstanceName}-NSG'
var routeTableName_var = 'SQLMI-${managedInstanceName}-Route-Table'

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow_tds_inbound'
        properties: {
          description: 'Allow access to data'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_redirect_inbound'
        properties: {
          description: 'Allow inbound redirect traffic to Managed Instance inside the virtual network'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '11000-11999'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1100
          direction: 'Inbound'
        }
      }
      {
        name: 'deny_all_inbound'
        properties: {
          description: 'Deny all other inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
      {
        name: 'deny_all_outbound'
        properties: {
          description: 'Deny all other outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource routeTableName 'Microsoft.Network/routeTables@2020-06-01' = {
  name: routeTableName_var
  location: location
  properties: {
    disableBgpRoutePropagation: false
  }
}

resource virtualNetworkName_res 'Microsoft.Network/virtualNetworks@2020-06-01' = {
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
          routeTable: {
            id: routeTableName.id
          }
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
          delegations: [
            {
              name: 'miDelegation'
              properties: {
                serviceName: 'Microsoft.Sql/managedInstances'
              }
            }
          ]
        }
      }
    ]
  }
}

resource managedInstanceName_res 'Microsoft.Sql/managedInstances@2020-02-02-preview' = {
  name: managedInstanceName
  location: location
  sku: {
    name: skuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
    storageSizeInGB: storageSizeInGB
    vCores: vCores
    licenseType: licenseType
  }
  dependsOn: [
    virtualNetworkName_res
  ]
}