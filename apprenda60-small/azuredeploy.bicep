param platformAdminFirstName string {
  metadata: {
    description: 'This is the first name of the platform administrator.'
  }
}
param platformAdminLastName string {
  metadata: {
    description: 'This is the last name of the platform administrator'
  }
}
param platformAdminEmailAddress string {
  metadata: {
    description: 'This is the email address of the platform administrator. This will be used to log in.'
  }
}
param platformAdminPassword string {
  metadata: {
    description: 'This is the password of the platform administrator. This will be used to log in.'
  }
}
param adminUsername string {
  metadata: {
    description: 'This is the username of the administrative account.'
  }
}
param adminPassword string {
  metadata: {
    description: 'This is the password of the administrative account.'
  }
  secure: true
}
param storageAccountType string {
  allowed: [
    'Standard_LRS'
    'Standard_GRS'
    'Standard_ZRS'
  ]
  metadata: {
    description: 'Storage Account type'
  }
  default: 'Standard_LRS'
}
param vmSize string {
  metadata: {
    description: 'The size of the virtual machine.'
  }
}
param vmName string {
  metadata: {
    description: 'This is the name of the virtual machine.'
  }
}

var vmStorageAccountContainerName = 'vhds'
var platformOSDiskName = 'platformosdisk'
var domainControllerOSDiskName = 'domaincontrollerosdisk'
var centOSDiskName = 'centosdisk'
var virtualNetworkName_var = 'apprendavnet'
var vnetID = virtualNetworkName.id
var customScriptExtensionVersion = '2.0'
var platformPIPName_var = '${platformNode_var}pubIP'
var platformPIPType = 'Dynamic'
var domainPIPName_var = '${domainControllerNode_var}pubIP'
var domainPIPType = 'Dynamic'
var centosPIPName_var = '${centOSNode_var}pubIP'
var centosPIPType = 'Dynamic'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var subnet1Prefix = '10.0.0.0/24'
var nicName_var = '${vmName}Nic'
var dcNic_var = 'dcNic'
var coNic_var = 'coNic'
var platformNode_var = concat(vmName)
var domainControllerNode_var = '${vmName}dc'
var centOSNode_var = '${vmName}centos'
var scriptURL = 'http://apprendaconfigfiles.blob.core.windows.net/configurationfiles/apprenda60PlatformNode.ps1'
var scriptName = 'apprenda60PlatformNode.ps1'
var scriptArgs = '-platformAdminFirstName ${platformAdminFirstName} -platformAdminLastName ${platformAdminLastName} -platformAdminEmailAddress ${platformAdminEmailAddress} -platformAdminPassword ${platformAdminPassword} -domaincontrollerserver ${domainControllerNode_var} -domainUserName ${adminUsername} -domainPassword ${adminPassword}'
var dcScriptURL = 'http://apprendaconfigfiles.blob.core.windows.net/configurationfiles/domainControllerSetup.ps1'
var dcScriptName = 'domainControllerSetup.ps1'
var dcScriptArgs = '-dcpassword ${adminPassword}'
var centosScriptURL = 'http://apprendaconfigfiles.blob.core.windows.net/configurationfiles/linuxSetup.sh'
var centosScriptName = 'linuxSetup.sh'

resource platformPIPName 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: platformPIPName_var
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: platformPIPType
    dnsSettings: {
      domainNameLabel: platformNode_var
    }
  }
}

resource domainPIPName 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: domainPIPName_var
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: domainPIPType
    dnsSettings: {
      domainNameLabel: domainControllerNode_var
    }
  }
}

resource centosPIPName 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: centosPIPName_var
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: centosPIPType
    dnsSettings: {
      domainNameLabel: centOSNode_var
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
  name: virtualNetworkName_var
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: nicName_var
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: platformPIPName.id
          }
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
}

resource dcNic 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: dcNic_var
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
}

resource coNic 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: coNic_var
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
}

resource platformNode 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: platformNode_var
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: platformNode_var
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2012-R2-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: '${platformNode_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageAccountType
        }
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

resource domainControllerNode 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: domainControllerNode_var
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: domainControllerNode_var
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2012-R2-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: '${domainControllerNode_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageAccountType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: dcNic.id
        }
      ]
    }
  }
}

resource centOSNode 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: centOSNode_var
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: centOSNode_var
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'OpenLogic'
        offer: 'CentOS'
        sku: '7.0'
        version: 'latest'
      }
      osDisk: {
        name: '${centOSNode_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageAccountType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: coNic.id
        }
      ]
    }
  }
}

resource platformNode_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  name: '${platformNode_var}/CustomScriptExtension'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: customScriptExtensionVersion
    settings: {
      fileUris: [
        scriptURL
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -file ${scriptName} ${scriptArgs}'
    }
  }
}

resource domainControllerNode_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  name: '${domainControllerNode_var}/CustomScriptExtension'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    autoUpgradeMinorVersion: true
    typeHandlerVersion: customScriptExtensionVersion
    settings: {
      fileUris: [
        dcScriptURL
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -file ${dcScriptName} ${dcScriptArgs}'
    }
  }
}

resource centOSNode_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  name: '${centOSNode_var}/CustomScriptExtension'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    autoUpgradeMinorVersion: true
    typeHandlerVersion: customScriptExtensionVersion
    settings: {
      fileUris: [
        centosScriptURL
      ]
      commandToExecute: 'sh ${centosScriptName}'
    }
  }
}