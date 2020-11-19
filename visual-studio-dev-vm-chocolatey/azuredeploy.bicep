param storageType string {
  allowed: [
    'Premium_LRS'
    'Standard_LRS'
  ]
  metadata: {
    description: 'Which type of storage you want to use'
  }
  default: 'Premium_LRS'
}
param vmName string {
  metadata: {
    description: 'Local name for the VM can be whatever you want'
  }
}
param vmAdminUserName string {
  metadata: {
    description: 'VM admin user name'
  }
}
param vmAdminPassword string {
  metadata: {
    description: 'VM admin password. The supplied password must be between 8-123 characters long and must satisfy at least 3 of password complexity requirements from the following: 1) Contains an uppercase character 2) Contains a lowercase character 3) Contains a numeric digit 4) Contains a special character.'
  }
  secure: true
}
param vmSize string {
  metadata: {
    description: 'Desired Size of the VM. Any valid option accepted but if you choose premium storage type you must choose a DS class VM size.'
  }
  default: 'Standard_DS2'
}
param vmVisualStudioVersion string {
  allowed: [
    'VS-2013-Comm-VSU5-AzureSDK-295-WS2012R2'
    'VS-2013-Prem-VSU5-AzureSDK-295-WS2012R2'
    'VS-2013-Ult-VSU5-AzureSDK-295-WS2012R2'
    'VS-2015-Comm-AzureSDK-2.9-W10T-Win10-N'
    'VS-2015-Comm-AzureSDK-2.9-WS2012R2'
    'VS-2015-Comm-VSU3-AzureSDK-29-Win10-N'
    'VS-2015-Comm-VSU3-AzureSDK-291-Win10-N'
    'VS-2015-Comm-VSU3-AzureSDK-291-WS2012R2'
    'VS-2015-Ent-AzureSDK-2.9-WS2012R2'
    'VS-2015-Ent-AzureSDK-29-W10T-Win10-N'
    'VS-2015-Ent-VSU3-AzureSDK-29-Win10-N'
    'VS-2015-Ent-VSU3-AzureSDK-291-WS2012R2'
    'VS-2017-RC1-Comm-Win10-N'
    'VS-2017-RC1-Comm-WS2012R2'
    'VS-2017-RC1-Ent-Win10-N'
    'VS-2017-RC1-Ent-WS2012R2'
  ]
  metadata: {
    description: 'Which version of Visual Studio you would like to deploy'
  }
  default: 'VS-2015-Comm-VSU3-AzureSDK-29-Win10-N'
}
param dnsLabelPrefix string {
  metadata: {
    description: 'DNS Label for the Public IP. Must be lowercase. It should match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.'
  }
}
param chocoPackages string {
  metadata: {
    description: 'List of Chocolatey packages to install separated by a semi-colon eg. linqpad;sysinternals'
  }
}
param setupChocolateyScriptFileName string {
  metadata: {
    description: 'PowerShell script name to execute'
  }
  default: 'SetupChocolatey.ps1'
}
param setupChocolatelyScriptLocation string {
  metadata: {
    description: 'Public uri location of PowerShell Chocolately setup script'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/visual-studio-dev-vm-chocolatey/scripts/'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var storageName = '${uniqueString(resourceGroup().id)}standardsa'
var vnet01Prefix = '10.0.0.0/16'
var vnet01Subnet1Name = 'Subnet-1'
var vnet01Subnet1Prefix = '10.0.0.0/24'
var vmImagePublisher = 'MicrosoftVisualStudio'
var vmImageOffer = 'VisualStudio'
var vmOSDiskName = 'VMOSDisk'
var vmSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', 'Vnet01', vnet01Subnet1Name)
var vmStorageAccountContainerName = 'vhds'
var vmNicName = '${vmName}NetworkInterface'
var vmIP01Name = 'VMIP01'

resource storageName_resource 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageName
  location: location
  tags: {
    displayName: 'Storage01'
  }
  properties: {
    accountType: storageType
  }
  dependsOn: []
}

resource VNet01 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: 'VNet01'
  location: location
  tags: {
    displayName: 'VNet01'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet01Prefix
      ]
    }
    subnets: [
      {
        name: vnet01Subnet1Name
        properties: {
          addressPrefix: vnet01Subnet1Prefix
        }
      }
    ]
  }
  dependsOn: []
}

resource vmNicName_resource 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: vmNicName
  location: location
  tags: {
    displayName: 'VMNic01'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vmSubnetRef
          }
          publicIPAddress: {
            id: vmIP01Name_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    VNet01
    vmIP01Name_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: location
  tags: {
    displayName: 'VM01'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmAdminUserName
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: vmImagePublisher
        offer: vmImageOffer
        sku: vmVisualStudioVersion
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
          id: vmNicName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    storageName_resource
    vmNicName_resource
  ]
}

resource vmName_SetupChocolatey 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName}/SetupChocolatey'
  location: location
  tags: {
    displayName: 'SetupChocolatey'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        concat(setupChocolatelyScriptLocation, setupChocolateyScriptFileName)
      ]
      commandToExecute: 'powershell -ExecutionPolicy bypass -File ${setupChocolateyScriptFileName} -chocoPackages ${chocoPackages}'
    }
  }
  dependsOn: [
    vmName_resource
  ]
}

resource vmIP01Name_resource 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: vmIP01Name
  location: location
  tags: {
    displayName: 'VMIP01'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
  dependsOn: []
}