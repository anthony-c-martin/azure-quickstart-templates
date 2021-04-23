@description('your existing data factory name')
param existingDataFactoryName string

@description('your existing data factory resource group')
param existingDataFactoryResourceGroup string

@allowed([
  'V1'
  'V2'
])
@description('your existing data factory version')
param existingDataFactoryVersion string

@description('IR name must be unique in subscription')
param IntegrationRuntimeName string

@minValue(1)
@maxValue(4)
@description('the node count is between 1 and 4.')
param NodeCount int
param vmSize string = 'Standard_A4_v2'

@description('User name for the virtual machine')
param adminUserName string

@description('Password for the virtual machine')
@secure()
param adminPassword string

@description('your existing vnet name')
param existingVirtualNetworkName string

@description('your virtual machine will be create in the same datacenter with VNET')
param existingVnetLocation string

@description('Name of the existing VNET resource group')
param existingVnetResourceGroupName string

@description('Name of the subnet in the virtual network you want to use')
param existingSubnetInYourVnet string

@description('The base URI where artifacts required by this template are located.')
param artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var delimiters = [
  '-'
  '_'
]
var prefix = split(IntegrationRuntimeName, delimiters)[0]
var storageAccountName_var = take(concat(toLower(prefix), uniqueString(resourceGroup().id, IntegrationRuntimeName)), 24)
var networkSecurityGroupName_var = '${IntegrationRuntimeName}nsg'
var vmTemplateLink = uri(artifactsLocation, 'nested/VMtemplate.json${artifactsLocationSasToken}')
var irInstallTemplateLink = uri(artifactsLocation, 'nested/IRInstall.json${artifactsLocationSasToken}')
var IRtemplateLink = uri(artifactsLocation, 'nested/IRtemplate.json${artifactsLocationSasToken}')
var subnetId = resourceId(existingVnetResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', existingVirtualNetworkName, existingSubnetInYourVnet)
var scriptURL = uri(artifactsLocation, 'gatewayInstall.ps1${artifactsLocationSasToken}')

module nestedTemplate '?' /*TODO: replace with correct path to [variables('IRtemplateLink')]*/ = {
  name: 'nestedTemplate'
  scope: resourceGroup(existingDataFactoryResourceGroup)
  params: {
    existingDataFactoryName: existingDataFactoryName
    existingDataFactoryVersion: existingDataFactoryVersion
    IntegrationRuntimeName: IntegrationRuntimeName
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: networkSecurityGroupName_var
  location: existingVnetLocation
  properties: {
    securityRules: [
      {
        name: 'default-allow-rdp'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '3389'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName_var
  location: existingVnetLocation
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
  dependsOn: [
    resourceId(existingDataFactoryResourceGroup, 'Microsoft.Resources/deployments', 'nestedTemplate')
  ]
}

module VMtemplate '?' /*TODO: replace with correct path to [variables('vmTemplateLink')]*/ = [for i in range(0, NodeCount): {
  name: 'VMtemplate-${i}'
  params: {
    virtualMachineName: take('vm${i}-${prefix}', 15)
    vmSize: vmSize
    adminUserName: adminUserName
    adminPassword: adminPassword
    existingVnetLocation: existingVnetLocation
    subnetId: subnetId
    nsgId: networkSecurityGroupName.id
    storageAccountName: storageAccountName_var
  }
  dependsOn: [
    resourceId(existingDataFactoryResourceGroup, 'Microsoft.Resources/deployments', 'nestedTemplate')
    networkSecurityGroupName
    storageAccountName
  ]
}]

@batchSize(1)
module IRInstalltemplate '?' /*TODO: replace with correct path to [variables('irInstallTemplateLink')]*/ = [for i in range(0, NodeCount): {
  name: 'IRInstalltemplate-${i}'
  params: {
    existingDataFactoryVersion: existingDataFactoryVersion
    datafactoryId: reference(resourceId(existingDataFactoryResourceGroup, 'Microsoft.Resources/deployments', 'nestedTemplate')).outputs.irId.value
    virtualMachineName: take('vm${i}-${prefix}', 15)
    existingVnetLocation: existingVnetLocation
    scriptUrl: scriptURL
  }
  dependsOn: [
    VMtemplate
  ]
}]