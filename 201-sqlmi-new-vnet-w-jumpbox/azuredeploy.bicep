@description('Enter managed instance name.')
param managedInstanceName string

@description('Enter user name.')
param administratorLogin string

@description('Enter password.')
@secure()
param administratorLoginPassword string

@description('Enter location. If you leave this field blank resource group location would be used.')
param location string = resourceGroup().location

@description('Enter virtual network name. If you leave this field blank name will be created by the template.')
param virtualNetworkName string = 'SQLMI-VNET'

@description('Enter virtual network address prefix.')
param addressPrefix string = '10.0.0.0/16'

@description('Enter subnet name.')
param subnetName string = 'ManagedInstance'

@description('Enter subnet address prefix.')
param subnetPrefix string = '10.0.0.0/24'

@description('Enter management subnet name.')
param managementSubnetName string = 'Management'

@description('Enter management subnet address prefix.')
param managementSubnetPrefix string = '10.0.1.0/24'

@allowed([
  'GP_Gen5'
  'BC_Gen5'
])
@description('Enter sku name.')
param skuName string = 'GP_Gen5'

@allowed([
  8
  16
  24
  32
  40
  64
  80
])
@description('Enter number of vCores.')
param vCores int = 16

@minValue(32)
@maxValue(8192)
@description('Enter storage size.')
param storageSizeInGB int = 256

@allowed([
  'BasePrice'
  'LicenseIncluded'
])
@description('Enter license type.')
param licenseType string = 'LicenseIncluded'

@description('Enter virtual machine size.')
param virtualMachineSize string = 'Standard_B2s'

@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

var networkSecurityGroupName_var = 'SQLMI-${managedInstanceName}-NSG'
var routeTableName_var = 'SQLMI-${managedInstanceName}-Route-Table'
var virtualMachineName_var = '${take(managedInstanceName, 13)}JB'
var networkInterfaceName_var = 'SQLMI-${managedInstanceName}-JB-NIC'
var publicIpAddressName_var = 'SQLMI-${managedInstanceName}-JB-IP'
var jbNetworkSecurityGroupName_var = 'SQLMI-${managedInstanceName}-JB-NSG'
var scriptFileUri = uri(artifactsLocation, 'installSSMS.ps1${artifactsLocationSasToken}')

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-06-01' = {
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

resource routeTableName 'Microsoft.Network/routeTables@2019-06-01' = {
  name: routeTableName_var
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
      {
        name: managementSubnetName
        properties: {
          addressPrefix: managementSubnetPrefix
        }
      }
    ]
  }
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

resource virtualMachineName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: virtualMachineName_var
  location: location
  properties: {
    osProfile: {
      computerName: virtualMachineName_var
      adminUsername: administratorLogin
      adminPassword: administratorLoginPassword
      windowsConfiguration: {
        provisionVMAgent: 'true'
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
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName.id
        }
      ]
    }
  }
}

resource virtualMachineName_SetupSSMS 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  parent: virtualMachineName
  name: 'SetupSSMS'
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
}

resource networkInterfaceName 'Microsoft.Network/networkInterfaces@2019-06-01' = {
  name: networkInterfaceName_var
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
          publicIPAddress: {
            id: publicIpAddressName.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: jbNetworkSecurityGroupName.id
    }
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource publicIpAddressName 'Microsoft.Network/publicIpAddresses@2019-06-01' = {
  name: publicIpAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  sku: {
    name: 'Basic'
  }
}

resource jbNetworkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-06-01' = {
  name: jbNetworkSecurityGroupName_var
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