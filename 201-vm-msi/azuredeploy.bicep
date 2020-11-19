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
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-msi/'
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

var azureCLI2DockerImage = 'azuresdk/azure-cli-python:latest'
var vmPrefix = 'vm'
var storageAccountName = concat(vmPrefix, uniqueString(resourceGroup().id))
var networkSecurityGroupName = 'nsg'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var vmName = concat(vmPrefix, uniqueString(resourceGroup().id))
var virtualNetworkName = 'vnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var containerName = 'msi'
var createVMUrl = uri(artifactsLocation, 'nestedtemplates/createVM.json${artifactsLocationSasToken}')
var createRBACUrl = uri(artifactsLocation, 'nestedtemplates/setUpRBAC.json${artifactsLocationSasToken}')

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-11-01' = {
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

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: networkSecurityGroupName
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

module creatingVM '<failed to parse [variables(\'createVMUrl\')]>' = {
  name: 'creatingVM'
  params: {
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
    adminPasswordOrKey: adminPasswordOrKey
    adminUsername: adminUsername
    authenticationType: authenticationType
    azureCLI2DockerImage: azureCLI2DockerImage
    containerName: containerName
    operatingSystem: operatingSystem
    location: location
    nsgId: networkSecurityGroupName_resource.id
    provisionExtensions: false
    storageAccountId: storageAccountName_resource.id
    storageAccountName: storageAccountName
    subnetRef: subnetRef
    vmSize: vmSize
    vmName: vmName
  }
  dependsOn: [
    virtualNetworkName_resource
    storageAccountName_resource
    networkSecurityGroupName_resource
  ]
}

module creatingRBAC '<failed to parse [variables(\'createRBACUrl\')]>' = {
  name: 'creatingRBAC'
  params: {
    principalId: reference(creatingVM.id, '2019-09-01').outputs.principalId.value
    storageAccountName: storageAccountName
  }
  dependsOn: [
    creatingVM
  ]
}

module updatingVM '<failed to parse [variables(\'createVMUrl\')]>' = {
  name: 'updatingVM'
  params: {
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
    adminPasswordOrKey: adminPasswordOrKey
    adminUsername: adminUsername
    authenticationType: authenticationType
    azureCLI2DockerImage: azureCLI2DockerImage
    containerName: containerName
    operatingSystem: operatingSystem
    location: location
    nsgId: networkSecurityGroupName_resource.id
    provisionExtensions: true
    storageAccountId: storageAccountName_resource.id
    storageAccountName: storageAccountName
    subnetRef: subnetRef
    vmSize: vmSize
    vmName: vmName
  }
  dependsOn: [
    creatingRBAC
  ]
}