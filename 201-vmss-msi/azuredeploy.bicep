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
param adminPasswordorSSHKey string

@description('The Location For the resources')
param location string = resourceGroup().location

@description('The size of the VM to create')
param vmSize string = 'Standard_D2S_V3'

@minValue(1)
@maxValue(100)
@description('Number of VM instances (100 or less).')
param instanceCount int = 2

@description('Over Provision VMSS Instances')
param overProvision bool = false

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vmss-msi/'

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

    networkSecurityGroupName
  ]
}

module creatingRBAC '?' /*TODO: replace with correct path to [variables('createRBACUrl')]*/ = {
  name: 'creatingRBAC'
  params: {
    principalId: reference(creatingVMSS.id, '2019-09-01').outputs.principalId.value
    storageAccountName: storageAccountName_var
  }
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