param existingDataFactoryName string {
  metadata: {
    description: 'your existing data factory name'
  }
}
param GatewayName string {
  metadata: {
    description: 'Gateway name must be unique in subscription'
  }
}
param adminUsername string {
  metadata: {
    description: 'User name for the virtual machine'
  }
}
param adminPassword string {
  metadata: {
    description: 'Password for the virtual machine'
  }
  secure: true
}
param existingVirtualNetworkName string {
  metadata: {
    description: 'your existing vnet name'
  }
}
param existingVnetLocation string {
  metadata: {
    description: 'your virtual machine will be create in the same datacenter with VNET'
  }
}
param existingVnetResourceGroupName string {
  metadata: {
    description: 'Name of the existing VNET resource group'
  }
}
param existingSubnetInYourVnet string {
  metadata: {
    description: 'Name of the subnet in the virtual network you want to use'
  }
}
param enableToSetDataStorePasswordsFromInternet string {
  allowed: [
    'yes'
    'no'
  ]
  metadata: {
    description: 'If you choose yes, we will create a dns name label for your machine and open one inbound port for our service to access your machine and set data store passwords.'
  }
  default: 'yes'
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-vm-with-data-management-gateway/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}

var delimiters = [
  '-'
  '_'
]
var prefix = split(GatewayName, delimiters)[0]
var virtualMachineName_var = take('vm-${prefix}', 15)
var nsglink = '${artifactsLocation}nested/${enableToSetDataStorePasswordsFromInternet}IncomingRemote.json${artifactsLocationSasToken}'
var nsgTemplateName_var = '${virtualMachineName_var}NSGTemplate'
var storageAccountName_var = take(concat(toLower(prefix), uniqueString(resourceGroup().id, virtualMachineName_var)), 24)
var nicName_var = '${virtualMachineName_var}Nic'
var publicIPAddressName = '${virtualMachineName_var}-ip'
var networkSecurityGroupName = '${virtualMachineName_var}nsg'
var scriptURL = '${artifactsLocation}scripts/gatewayInstall.ps1${artifactsLocationSasToken}'

resource existingDataFactoryName_GatewayName 'Microsoft.DataFactory/dataFactories/gateways@2015-10-01' = {
  name: '${existingDataFactoryName}/${GatewayName}'
  properties: {
    description: 'my gateway'
  }
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: storageAccountName_var
  location: existingVnetLocation
  tags: {
    vmname: virtualMachineName_var
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource nicName 'Microsoft.Network/networkInterfaces@2016-03-30' = {
  name: nicName_var
  location: existingVnetLocation
  tags: {
    vmname: virtualMachineName_var
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', publicIPAddressName)
          }
          subnet: {
            id: resourceId(existingVnetResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', existingVirtualNetworkName, existingSubnetInYourVnet)
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: resourceId('Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)
    }
  }
}

resource virtualMachineName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: virtualMachineName_var
  location: existingVnetLocation
  tags: {
    vmname: virtualMachineName_var
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_A3'
    }
    osProfile: {
      computerName: virtualMachineName_var
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2016-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: '${virtualMachineName_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      dataDisks: [
        {
          name: '${virtualMachineName_var}_DataDisk1'
          diskSizeGB: 128
          lun: 0
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccountName.properties.primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    storageAccountName
  ]
}

resource virtualMachineName_virtualMachineName_installGW 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${virtualMachineName_var}/${virtualMachineName_var}installGW'
  location: existingVnetLocation
  tags: {
    vmname: virtualMachineName_var
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.7'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        scriptURL
      ]
    }
    protectedSettings: {
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File gatewayInstall.ps1 ${listAuthKeys(existingDataFactoryName_GatewayName.id, '2015-10-01').key1} ${reference(nsgTemplateName_var).outputs.hostname.Value} ${enableToSetDataStorePasswordsFromInternet}'
    }
  }
}

module nsgTemplateName '?' /*TODO: replace with correct path to [variables('nsglink')]*/ = {
  name: nsgTemplateName_var
  params: {
    vmName: virtualMachineName_var
    networkSecurityGroupName: networkSecurityGroupName
    publicIPAddressName: publicIPAddressName
    existingVnetLocation: existingVnetLocation
  }
  dependsOn: [
    existingDataFactoryName_GatewayName
  ]
}