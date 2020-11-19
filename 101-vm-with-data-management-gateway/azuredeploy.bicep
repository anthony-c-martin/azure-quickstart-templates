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
var virtualMachineName = take('vm-${prefix}', 15)
var nsglink = '${artifactsLocation}nested/${enableToSetDataStorePasswordsFromInternet}IncomingRemote.json${artifactsLocationSasToken}'
var nsgTemplateName = '${virtualMachineName}NSGTemplate'
var storageAccountName = take(concat(toLower(prefix), uniqueString(resourceGroup().id, virtualMachineName)), 24)
var nicName = '${virtualMachineName}Nic'
var publicIPAddressName = '${virtualMachineName}-ip'
var networkSecurityGroupName = '${virtualMachineName}nsg'
var scriptURL = '${artifactsLocation}scripts/gatewayInstall.ps1${artifactsLocationSasToken}'

resource existingDataFactoryName_GatewayName 'Microsoft.DataFactory/dataFactories/gateways@2015-10-01' = {
  name: '${existingDataFactoryName}/${GatewayName}'
  properties: {
    description: 'my gateway'
  }
}

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: storageAccountName
  location: existingVnetLocation
  tags: {
    vmname: virtualMachineName
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
  dependsOn: [
    existingDataFactoryName_GatewayName
  ]
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2016-03-30' = {
  name: nicName
  location: existingVnetLocation
  tags: {
    vmname: virtualMachineName
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
  dependsOn: [
    nsgTemplateName_resource
  ]
}

resource virtualMachineName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: virtualMachineName
  location: existingVnetLocation
  tags: {
    vmname: virtualMachineName
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_A3'
    }
    osProfile: {
      computerName: virtualMachineName
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
        name: '${virtualMachineName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      dataDisks: [
        {
          name: '${virtualMachineName}_DataDisk1'
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
          id: nicName_resource.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccountName_resource.properties.primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    storageAccountName_resource
    nicName_resource
  ]
}

resource virtualMachineName_virtualMachineName_installGW 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${virtualMachineName}/${virtualMachineName}installGW'
  location: existingVnetLocation
  tags: {
    vmname: virtualMachineName
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
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File gatewayInstall.ps1 ${listAuthKeys(existingDataFactoryName_GatewayName.id, '2015-10-01').key1} ${reference(nsgTemplateName).outputs.hostname.Value} ${enableToSetDataStorePasswordsFromInternet}'
    }
  }
  dependsOn: [
    virtualMachineName_resource
  ]
}

module nsgTemplateName_resource '<failed to parse [variables(\'nsglink\')]>' = {
  name: nsgTemplateName
  params: {
    vmName: virtualMachineName
    networkSecurityGroupName: networkSecurityGroupName
    publicIPAddressName: publicIPAddressName
    existingVnetLocation: existingVnetLocation
  }
  dependsOn: [
    existingDataFactoryName_GatewayName
  ]
}