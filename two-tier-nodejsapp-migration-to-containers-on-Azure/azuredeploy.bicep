param virtualMachineName string {
  metadata: {
    description: 'Name for the Virtual Machine.'
  }
}
param adminUsername string {
  metadata: {
    description: 'Username for the Virtual Machine.'
  }
}
param appGitLocation string {
  metadata: {
    description: 'The Git Url of the app'
  }
  default: 'https://github.com/evillgenius75/gbb-todo'
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/two-tier-nodejsapp-migration-to-containers-on-Azure/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param authenticationType string {
  allowed: [
    'sshPublicKey'
    'password'
  ]
  metadata: {
    description: 'Type of authentication to use on the Virtual Machine. SSH key is recommended.'
  }
  default: 'sshPublicKey'
}
param adminPasswordOrKey string {
  metadata: {
    description: 'SSH Key or password for the Virtual Machine. SSH key is recommended.'
  }
  secure: true
}

var OSDiskName = 'osdiskfordockersimple'
var nicName_var = 'nicCard'
var publicIPAddressName_var = 'publicIP'
var publicIPAddressType = 'Dynamic'
var nsgName_var = 'nsg'
var vmStorageAccountContainerName = 'vhds'
var virtualNetworkName_var = 'vnet'
var newStorageAccountName_var = 'storage${uniqueString(resourceGroup().id)}'
var dnsNameForPublicIP = 'pip${uniqueString(resourceGroup().id)}'
var customExtensionScriptFileName = 'mongo_nodejs.sh'
var todoAppTags = {
  provider: 'NA'
}
var quickstartTags = {
  name: 'todoApp'
}
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource newStorageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: newStorageAccountName_var
  location: location
  tags: {
    displayName: 'Storage Account'
    quickstartName: quickstartTags.name
    provider: todoAppTags.provider
  }
  kind: 'Storage'
  sku: {
    name: 'Standard_LRS'
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2017-04-01' = {
  name: publicIPAddressName_var
  location: location
  tags: {
    displayName: 'Public IP'
    quickstartName: quickstartTags.name
    provider: todoAppTags.provider
  }
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
  }
}

resource nsgName 'Microsoft.Network/networkSecurityGroups@2016-03-30' = {
  name: nsgName_var
  location: location
  tags: {
    displayName: 'Network Security Group'
    quickstartName: quickstartTags.name
    provider: todoAppTags.provider
  }
  properties: {
    securityRules: [
      {
        name: 'SSH-allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '10.0.0.0/16'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'Nodejs-allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          destinationAddressPrefix: '10.0.0.0/16'
          sourceAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2017-04-01' = {
  name: virtualNetworkName_var
  location: location
  tags: {
    displayName: 'Virtual Network'
    quickstartName: quickstartTags.name
    provider: todoAppTags.provider
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsgName.id
          }
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2017-04-01' = {
  name: nicName_var
  location: location
  tags: {
    displayName: 'Network Interface Card'
    quickstartName: quickstartTags.name
    provider: todoAppTags.provider
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName_var, 'subnet')
          }
        }
      }
    ]
  }
}

resource virtualMachineName_res 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: virtualMachineName
  location: location
  tags: {
    displayName: 'Virtual Machine'
    quickstartName: quickstartTags.name
    provider: todoAppTags.provider
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_F1'
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '16.04.0-LTS'
        version: 'latest'
      }
      osDisk: {
        name: '${virtualMachineName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName.id
        }
      ]
    }
  }
}

resource virtualMachineName_customExtension 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = {
  name: '${virtualMachineName}/customExtension'
  location: location
  tags: {
    displayName: 'customExtension'
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation}scripts/${customExtensionScriptFileName}${artifactsLocationSasToken}'
      ]
      commandToExecute: 'sh ${customExtensionScriptFileName} ${appGitLocation}'
    }
  }
}

output adminUsername_out string = adminUsername
output publicIP string = publicIPAddressName.properties.dnsSettings.fqdn