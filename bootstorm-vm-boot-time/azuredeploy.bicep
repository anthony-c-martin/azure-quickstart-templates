@description('Azure account SPN user name to authenticate inside controller VM.')
param azureAccountUsername string

@description('Azure account SPN password to authenticate inside controller VM.')
@secure()
param azureAccountPassword string

@description('Azure Subscription Tenant Id.')
param tenantId string

@description('Number of VMs to create.')
param vmCount int = 2

@description('Location for all resources.')
param location string = resourceGroup().location

var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var addressPrefix = '10.0.0.0/16'
var location_var = location
var subnetName = 'vsn${uniqueString(resourceGroup().id)}'
var subnetPrefix = '10.0.0.0/24'
var storageAccountType = 'Standard_LRS'
var publicIPAddressType = 'Dynamic'
var publicIPAddressName_var = 'ip${uniqueString(resourceGroup().id)}'
var uniqueDnsNameForPublicIP = 'dns${uniqueString(resourceGroup().id)}'
var uniqueStorageAccountName_var = 'sa${uniqueString(resourceGroup().id)}'
var uniqueStorageAccountContainerName = 'sc${uniqueString(resourceGroup().id)}'
var adResourceID = 'null'
var vmOsSku = '2012-R2-Datacenter'
var vmAdminUsername = 'vmadministrator'
var vmAdminPassword = 'pwd0a!8b7'
var vmName_var = 'vm${uniqueString(resourceGroup().id)}'
var vmOsDiskName = 'od${uniqueString(resourceGroup().id)}'
var vmSize = 'Standard_A2'
var vmNicName_var = 'nc${uniqueString(resourceGroup().id)}'
var virtualNetworkName_var = 'vn${uniqueString(resourceGroup().id)}'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var nsgName_var = 'ng${uniqueString(resourceGroup().id)}'
var nsgID = nsgName.id
var modulesPath = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/bootstorm-vm-boot-time/'
var moduleVMBootAll = 'VMBootAll.zip'
var modulesUrlVMBootAll = concat(modulesPath, moduleVMBootAll)
var configurationFunctionVMBootAll = 'VMBootAll.ps1\\ConfigureVMBootAll'

resource uniqueStorageAccountName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: toLower(uniqueStorageAccountName_var)
  location: location_var
  properties: {
    accountType: storageAccountType
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: publicIPAddressName_var
  location: location_var
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: uniqueDnsNameForPublicIP
    }
  }
}

resource nsgName 'Microsoft.Network/networkSecurityGroups@2015-05-01-preview' = {
  name: nsgName_var
  location: location_var
  properties: {
    securityRules: [
      {
        name: 'nsgsrule'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
  name: virtualNetworkName_var
  location: location_var
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
            id: nsgID
          }
        }
      }
    ]
  }
}

resource vmNicName 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: vmNicName_var
  location: location_var
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfigpublic'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource Microsoft_Network_networkInterfaces_vmNicName 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = [for i in range(0, vmCount): {
  name: concat(vmNicName_var, i)
  location: location_var
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfigprivate'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}]

resource vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName_var
  location: location_var
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: vmOsSku
        version: 'latest'
      }
      osDisk: {
        name: '${vmName_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference('Microsoft.Storage/storageAccounts/${uniqueStorageAccountName_var}', '2015-06-15').primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    'Microsoft.Storage/storageAccounts/${uniqueStorageAccountName_var}'
  ]
}

resource Microsoft_Compute_virtualMachines_vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, vmCount): {
  name: concat(vmName_var, i)
  location: location_var
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: vmOsSku
        version: 'latest'
      }
      osDisk: {
        name: '${vmName_var}${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(vmNicName_var, i))
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference('Microsoft.Storage/storageAccounts/${uniqueStorageAccountName_var}', '2015-06-15').primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    'Microsoft.Storage/storageAccounts/${uniqueStorageAccountName_var}'
    'Microsoft.Network/networkInterfaces/${vmNicName_var}${i}'
  ]
}]

resource vmName_dscExtension 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  parent: vmName
  name: 'dscExtension'
  location: location_var
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.15'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: modulesUrlVMBootAll
      configurationFunction: configurationFunctionVMBootAll
      properties: {
        azureAccountUsername: azureAccountUsername
        azureAccountPassword: azureAccountPassword
        AdResourceID: adResourceID
        TenantId: tenantId
        VMName: vmName_var
        VMCount: vmCount
        VMAdminUserName: vmAdminUsername
        VMAdminPassword: vmAdminPassword
        AzureStorageAccount: uniqueStorageAccountName_var
        AzureStorageAccessKey: listKeys('Microsoft.Storage/storageAccounts/${uniqueStorageAccountName_var}', '2015-06-15').key1
      }
    }
  }
}