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
param adminPasswordorSSHKey string {
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
  default: 'Standard_D2S_V3'
}
param instanceCount int {
  minValue: 1
  maxValue: 100
  metadata: {
    description: 'Number of VM instances (100 or less).'
  }
  default: 2
}
param overProvision bool {
  metadata: {
    description: 'Over Provision VMSS Instances'
  }
  default: false
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vmss-msi/'
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
var vmssPrefix = 'vmss'
var storageAccountName_var = concat(vmssPrefix, uniqueString(resourceGroup().id))
var nicName = 'nic'
var networkSecurityGroupName_var = 'nsg'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var vmssName = concat(vmssPrefix, uniqueString(resourceGroup().id))
var virtualNetworkName_var = 'vnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var containerName = 'msi'
var createVMSSUrl = uri(artifactsLocation, 'nestedtemplates/createVMSS.json${artifactsLocationSasToken}')
var createRBACUrl = uri(artifactsLocation, 'nestedtemplates/setUpRBAC.json${artifactsLocationSasToken}')

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2019-11-01' = {
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

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-ssh'
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

module creatingVMSS '?' /*TODO: replace with correct path to [variables('createVMSSUrl')]*/ = {
  name: 'creatingVMSS'
  params: {
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
    adminPasswordorSSHKey: adminPasswordorSSHKey
    adminUsername: adminUsername
    authenticationType: authenticationType
    azureCLI2DockerImage: azureCLI2DockerImage
    containerName: containerName
    operatingSystem: operatingSystem
    instanceCount: 0
    location: location
    networkSecurityGroupName: networkSecurityGroupName_var
    nicName: nicName
    overProvision: overProvision
    provisionExtensions: false
    storageAccountId: storageAccountName.id
    storageAccountName: storageAccountName_var
    subnetRef: subnetRef
    vmSize: vmSize
    vmssName: vmssName
    vmssPrefix: vmssPrefix
  }
  dependsOn: [
    virtualNetworkName
    storageAccountName
    networkSecurityGroupName
  ]
}

module creatingRBAC '?' /*TODO: replace with correct path to [variables('createRBACUrl')]*/ = {
  name: 'creatingRBAC'
  params: {
    principalId: reference(creatingVMSS.id, '2019-09-01').outputs.principalId.value
    storageAccountName: storageAccountName_var
  }
  dependsOn: [
    creatingVMSS
  ]
}

module updatingVMSS '?' /*TODO: replace with correct path to [variables('createVMSSUrl')]*/ = {
  name: 'updatingVMSS'
  params: {
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
    adminPasswordorSSHKey: adminPasswordorSSHKey
    adminUsername: adminUsername
    authenticationType: authenticationType
    azureCLI2DockerImage: azureCLI2DockerImage
    containerName: containerName
    operatingSystem: operatingSystem
    instanceCount: instanceCount
    location: location
    networkSecurityGroupName: networkSecurityGroupName_var
    nicName: nicName
    overProvision: overProvision
    provisionExtensions: true
    storageAccountId: storageAccountName.id
    storageAccountName: storageAccountName_var
    subnetRef: subnetRef
    vmSize: vmSize
    vmssName: vmssName
    vmssPrefix: vmssPrefix
  }
  dependsOn: [
    creatingRBAC
  ]
}