@description('Username for the Virtual Machine.')
param adminUsername string

@allowed([
  'password'
  'sshPublicKey'
])
@description('Authentication type')
param authenticationType string = 'sshPublicKey'

@description('OS Admin password or SSH Key depending on value of authentication type')
@secure()
param adminPasswordOrKey string

@description('The Location For the resources')
param location string = resourceGroup().location

@description('The size of the VM to create')
param vmSize string = 'Standard_DS1_V2'

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-msi/'

@description('The sasToken required to access _artifactsLocation.')
@secure()
param artifactsLocationSasToken string = ''

@allowed([
  'UbuntuServer_18.04-LTS'
  'UbuntuServer_16.04-LTS'
  'WindowsServer_2016-DataCenter'
])
@description('Operating system to use for the virtual machine.')
param operatingSystem string = 'UbuntuServer_18.04-LTS'

var azureCLI2DockerImage = 'azuresdk/azure-cli-python:latest'
var vmPrefix = 'vm'
var storageAccountName_var = concat(vmPrefix, uniqueString(resourceGroup().id))
var networkSecurityGroupName_var = 'nsg'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var vmName = concat(vmPrefix, uniqueString(resourceGroup().id))
var virtualNetworkName_var = 'vnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var containerName = 'msi'
var createVMUrl = uri(artifactsLocation, 'nestedtemplates/createVM.json${artifactsLocationSasToken}')
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
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
    adminPasswordOrKey: adminPasswordOrKey
    adminUsername: adminUsername
    authenticationType: authenticationType
    azureCLI2DockerImage: azureCLI2DockerImage
    containerName: containerName
    operatingSystem: operatingSystem
    location: location
    nsgId: networkSecurityGroupName.id
    provisionExtensions: false
    storageAccountId: storageAccountName.id
    storageAccountName: storageAccountName_var
    subnetRef: subnetRef
    vmSize: vmSize
    vmName: vmName
  }
  dependsOn: [
    virtualNetworkName
  ]
}

module creatingRBAC '?' /*TODO: replace with correct path to [variables('createRBACUrl')]*/ = {
  name: 'creatingRBAC'
  params: {
    principalId: reference(creatingVM.id, '2019-09-01').outputs.principalId.value
    storageAccountName: storageAccountName_var
  }
}

module updatingVM '?' /*TODO: replace with correct path to [variables('createVMUrl')]*/ = {
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
    nsgId: networkSecurityGroupName.id
    provisionExtensions: true
    storageAccountId: storageAccountName.id
    storageAccountName: storageAccountName_var
    subnetRef: subnetRef
    vmSize: vmSize
    vmName: vmName
  }
  dependsOn: [
    creatingRBAC
  ]
}