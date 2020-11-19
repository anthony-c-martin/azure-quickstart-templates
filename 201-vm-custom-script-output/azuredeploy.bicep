param adminUsername string {
  metadata: {
    description: 'Username for the Virtual Machine.'
  }
}
param authenticationType string {
  allowed: [
    'password'
    'sshPublicKey'
  ]
  metadata: {
    description: 'Authentication type'
  }
  default: 'sshPublicKey'
}
param adminPasswordOrKey string {
  metadata: {
    description: 'OS Admin password or SSH Key depending on value of authentication type'
  }
  secure: true
}
param location string {
  metadata: {
    description: 'The Location For the resources'
  }
  default: resourceGroup().location
}
param vmSize string {
  metadata: {
    description: 'The size of the VM to create'
  }
  default: 'Standard_DS1_V2'
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-custom-script-output/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.'
  }
  secure: true
  default: ''
}
param operatingSystem string {
  allowed: [
    'UbuntuServer_18.04-LTS'
    'UbuntuServer_16.04-LTS'
    'WindowsServer_2016-DataCenter'
  ]
  metadata: {
    description: 'Operating system to use for the virtual machine.'
  }
  default: 'UbuntuServer_18.04-LTS'
}

var isWindowsOs = contains(toLower(operatingSystem), 'windows')
var script1Command = (isWindowsOs ? 'powershell -ExecutionPolicy Unrestricted -File  .\\script-1.ps1 ' : './script-1.sh ')
var script2Command = (isWindowsOs ? 'powershell -ExecutionPolicy Unrestricted -File  .\\script-2.ps1 ' : './script-2.sh ')
var script1File = (isWindowsOs ? 'script-1.ps1' : 'script-1.sh')
var script2File = (isWindowsOs ? 'script-2.ps1' : 'script-2.sh')
var vmName = 'vm'
var storageAccountName_var = concat(vmName, uniqueString(resourceGroup().id))
var networkSecurityGroupName_var = 'nsg'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName_var = 'vnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var createVMUrl = uri(artifactsLocation, 'nestedtemplates/vm.json${artifactsLocationSasToken}')
var extensionUrl = uri(artifactsLocation, 'nestedtemplates/customScriptExtension.json${artifactsLocationSasToken}')

resource storageAccountName 'Microsoft.Storage/storageAccounts@2018-02-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2018-07-01' = {
  name: virtualNetworkName_var
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

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2018-07-01' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-remote-access'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: (contains(toLower(operatingSystem), 'windows') ? 3389 : 22)
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

module creatingVM '?' /*TODO: replace with correct path to [variables('createVMUrl')]*/ = {
  name: 'creatingVM'
  params: {
    adminPasswordOrKey: adminPasswordOrKey
    adminUsername: adminUsername
    authenticationType: authenticationType
    operatingSystem: operatingSystem
    location: location
    nsgId: networkSecurityGroupName.id
    storageAccountId: storageAccountName.id
    subnetRef: subnetRef
    vmSize: vmSize
    vmName: vmName
  }
  dependsOn: [
    virtualNetworkName
    storageAccountName
    networkSecurityGroupName
  ]
}

module firstExtensionRun '?' /*TODO: replace with correct path to [variables('extensionUrl')]*/ = {
  name: 'firstExtensionRun'
  params: {
    location: location
    extensionName: 'cse'
    vmName: vmName
    fileUris: [
      uri(artifactsLocation, concat(script1File, artifactsLocationSasToken))
    ]
    commandToExecute: script1Command
    isWindowsOS: isWindowsOs
  }
  dependsOn: [
    creatingVM
  ]
}

module secondExtensionRun '?' /*TODO: replace with correct path to [variables('extensionUrl')]*/ = {
  name: 'secondExtensionRun'
  params: {
    location: location
    extensionName: 'cse'
    vmName: vmName
    fileUris: [
      uri(artifactsLocation, concat(script2File, artifactsLocationSasToken))
    ]
    commandToExecute: '${script2Command}"${split(string((isWindowsOs ? reference('firstExtensionRun').outputs.instanceView.value.substatuses[0].message : reference('firstExtensionRun').outputs.instanceView.value.statuses[0].message)), '#DATA#')[1]}"'
    isWindowsOS: isWindowsOs
  }
  dependsOn: [
    firstExtensionRun
  ]
}

output sample object = reference('firstExtensionRun').outputs.instanceView.value