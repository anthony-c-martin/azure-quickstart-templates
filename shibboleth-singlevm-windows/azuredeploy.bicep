param adminUsername string {
  metadata: {
    description: 'User name for the Virtual Machine administrator. Do not use simple names such as \'admin\'.'
  }
}
param adminPassword string {
  metadata: {
    description: 'Password for the Virtual Machine administrator.'
  }
  secure: true
}
param uniqueNamePrefix string {
  metadata: {
    description: 'Unique name that will be used to generate various other names including the name of the Public IP used to access the Virtual Machine.'
  }
}
param windowsOSVersion string {
  allowed: [
    '2016-Datacenter'
  ]
  metadata: {
    description: 'The Windows version for the VM. This will pick a fully patched image of this given Windows version. Allowed values: 2008-R2-SP1, 2012-Datacenter, 2012-R2-Datacenter.'
  }
  default: '2016-Datacenter'
}
param vmSize string {
  allowed: [
    'Standard_A0'
    'Standard_A1'
    'Standard_A2'
    'Standard_A3'
    'Standard_A4'
    'Standard_A5'
    'Standard_A6'
    'Standard_A7'
    'Standard_A8'
    'Standard_A9'
    'Standard_A10'
    'Standard_A11'
    'Standard_D1'
    'Standard_D2'
    'Standard_D3'
    'Standard_D4'
    'Standard_D11'
    'Standard_D12'
    'Standard_D13'
    'Standard_D14'
  ]
  metadata: {
    description: 'The size of the VM.'
  }
  default: 'Standard_D11'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var newStorageAccountName = '${uniqueString(resourceGroup().id)}shs'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var OSDiskName = '${uniqueNamePrefix}Disk'
var nicName = '${uniqueNamePrefix}Nic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var storageAccountType = 'Standard_LRS'
var publicIPAddressName = '${uniqueNamePrefix}IP'
var publicIPAddressType = 'Dynamic'
var vmStorageAccountContainerName = 'vhds'
var vmName = '${uniqueNamePrefix}VM'
var virtualNetworkName = '${uniqueNamePrefix}VNet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var installScriptName = 'install_shibboleth_idp.ps1'
var installScriptUri = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/shibboleth-singlevm-windows/${installScriptName}'
var installCommand = 'powershell.exe -File ${installScriptName} ${uniqueNamePrefix} ${location}'

resource newStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  location: location
  name: newStorageAccountName
  properties: {
    accountType: storageAccountType
  }
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: uniqueNamePrefix
    }
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-06-15' = {
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
        }
      }
    ]
  }
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName_resource.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
    virtualNetworkName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccountName_resource
    nicName_resource
  ]
}

resource vmName_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName}/CustomScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        installScriptUri
      ]
      commandToExecute: installCommand
    }
  }
  dependsOn: [
    vmName_resource
  ]
}