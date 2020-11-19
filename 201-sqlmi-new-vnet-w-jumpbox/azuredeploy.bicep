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
param managementSubnetName string {
  metadata: {
    description: 'Enter management subnet name.'
  }
  default: 'Management'
}
param managementSubnetPrefix string {
  metadata: {
    description: 'Enter management subnet address prefix.'
  }
  default: '10.0.1.0/24'
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
param virtualMachineSize string {
  metadata: {
    description: 'Enter virtual machine size.'
  }
  default: 'Standard_B2s'
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located including a trailing \'/\''
  }
  default: deployment().properties.templateLink.uri
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.'
  }
  secure: true
  default: ''
}

var networkSecurityGroupName = 'SQLMI-${managedInstanceName}-NSG'
var routeTableName = 'SQLMI-${managedInstanceName}-Route-Table'
var virtualMachineName = '${take(managedInstanceName, 13)}JB'
var networkInterfaceName = 'SQLMI-${managedInstanceName}-JB-NIC'
var publicIpAddressName = 'SQLMI-${managedInstanceName}-JB-IP'
var jbNetworkSecurityGroupName = 'SQLMI-${managedInstanceName}-JB-NSG'
var scriptFileUri = uri(artifactsLocation, 'installSSMS.ps1${artifactsLocationSasToken}')

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-06-01' = {
  name: networkSecurityGroupName
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

resource routeTableName_resource 'Microsoft.Network/routeTables@2019-06-01' = {
  name: routeTableName
  location: location
  properties: {
    disableBgpRoutePropagation: false
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-06-01' = {
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
            id: routeTableName_resource.id
          }
          networkSecurityGroup: {
            id: networkSecurityGroupName_resource.id
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
      {
        name: managementSubnetName
        properties: {
          addressPrefix: managementSubnetPrefix
        }
      }
    ]
  }
  dependsOn: [
    routeTableName_resource
    networkSecurityGroupName_resource
  ]
}

resource managedInstanceName_resource 'Microsoft.Sql/managedInstances@2019-06-01-preview' = {
  identity: {
    type: 'SystemAssigned'
  }
  location: location
  name: managedInstanceName
  sku: {
    name: skuName
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
    virtualNetworkName_resource
  ]
}

resource virtualMachineName_resource 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: virtualMachineName
  location: location
  properties: {
    osProfile: {
      computerName: virtualMachineName
      adminUsername: administratorLogin
      adminPassword: administratorLoginPassword
      windowsConfiguration: {
        provisionVmAgent: 'true'
      }
    }
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2016-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    networkInterfaceName_resource
  ]
}

resource virtualMachineName_SetupSSMS 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  name: '${virtualMachineName}/SetupSSMS'
  location: location
  tags: {
    displayName: 'SetupSSMS'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        scriptFileUri
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File installSSMS.ps1'
    }
  }
  dependsOn: [
    virtualMachineName_resource
  ]
}

resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2019-06-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, managementSubnetName)
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIpAddress: {
            id: publicIpAddressName_resource.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: jbNetworkSecurityGroupName_resource.id
    }
  }
  dependsOn: [
    virtualNetworkName_resource
    publicIpAddressName_resource
    jbNetworkSecurityGroupName_resource
  ]
}

resource publicIpAddressName_resource 'Microsoft.Network/publicIpAddresses@2019-06-01' = {
  name: publicIpAddressName
  location: location
  properties: {
    publicIpAllocationMethod: 'Dynamic'
  }
  sku: {
    name: 'Basic'
  }
}

resource jbNetworkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-06-01' = {
  name: jbNetworkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP'
        properties: {
          priority: 300
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
    ]
  }
}