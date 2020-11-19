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
var virtualNetworkName = 'apprendavnet'
var vnetID = virtualNetworkName_resource.id
var customScriptExtensionVersion = '2.0'
var platformPIPName = '${platformNode}pubIP'
var platformPIPType = 'Dynamic'
var domainPIPName = '${domainControllerNode}pubIP'
var domainPIPType = 'Dynamic'
var centosPIPName = '${centOSNode}pubIP'
var centosPIPType = 'Dynamic'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var subnet1Prefix = '10.0.0.0/24'
var nicName = '${vmName}Nic'
var dcNic = 'dcNic'
var coNic = 'coNic'
var platformNode = concat(vmName)
var domainControllerNode = '${vmName}dc'
var centOSNode = '${vmName}centos'
var scriptURL = 'http://apprendaconfigfiles.blob.core.windows.net/configurationfiles/apprenda60PlatformNode.ps1'
var scriptName = 'apprenda60PlatformNode.ps1'
var scriptArgs = '-platformAdminFirstName ${platformAdminFirstName} -platformAdminLastName ${platformAdminLastName} -platformAdminEmailAddress ${platformAdminEmailAddress} -platformAdminPassword ${platformAdminPassword} -domaincontrollerserver ${domainControllerNode} -domainUserName ${adminUsername} -domainPassword ${adminPassword}'
var dcScriptURL = 'http://apprendaconfigfiles.blob.core.windows.net/configurationfiles/domainControllerSetup.ps1'
var dcScriptName = 'domainControllerSetup.ps1'
var dcScriptArgs = '-dcpassword ${adminPassword}'
var centosScriptURL = 'http://apprendaconfigfiles.blob.core.windows.net/configurationfiles/linuxSetup.sh'
var centosScriptName = 'linuxSetup.sh'

resource platformPIPName_resource 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: platformPIPName
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: platformPIPType
    dnsSettings: {
      domainNameLabel: platformNode
    }
  }
}

resource domainPIPName_resource 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: domainPIPName
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: domainPIPType
    dnsSettings: {
      domainNameLabel: domainControllerNode
    }
  }
}

resource centosPIPName_resource 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: centosPIPName
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: centosPIPType
    dnsSettings: {
      domainNameLabel: centOSNode
    }
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
  name: virtualNetworkName
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

resource nicName_resource 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: nicName
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: platformPIPName_resource.id
          }
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
  dependsOn: [
    platformPIPName_resource
    virtualNetworkName_resource
  ]
}

resource dcNic_resource 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: dcNic
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
  dependsOn: [
    domainPIPName_resource
    virtualNetworkName_resource
  ]
}

resource coNic_resource 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: coNic
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
  dependsOn: [
    centosPIPName_resource
    virtualNetworkName_resource
  ]
}

resource platformNode_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: platformNode
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: platformNode
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
        name: '${platformNode}_OSDisk'
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
          id: nicName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    nicName_resource
  ]
}

resource domainControllerNode_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: domainControllerNode
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: domainControllerNode
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
        name: '${domainControllerNode}_OSDisk'
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
          id: dcNic_resource.id
        }
      ]
    }
  }
  dependsOn: [
    dcNic_resource
  ]
}

resource centOSNode_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: centOSNode
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: centOSNode
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
        name: '${centOSNode}_OSDisk'
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
          id: coNic_resource.id
        }
      ]
    }
  }
  dependsOn: [
    coNic_resource
  ]
}

resource platformNode_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  name: '${platformNode}/CustomScriptExtension'
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
  dependsOn: [
    platformNode_resource
  ]
}

resource domainControllerNode_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  name: '${domainControllerNode}/CustomScriptExtension'
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
  dependsOn: [
    domainControllerNode_resource
  ]
}

resource centOSNode_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  name: '${centOSNode}/CustomScriptExtension'
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
  dependsOn: [
    centOSNode_resource
  ]
}