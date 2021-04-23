@description('your existing data factory name')
param existingDataFactoryName string

@description('your existing data factory resource group')
param existingDataFactoryResourceGroup string

@description('Gateway name must be unique in subscription')
param GatewayName string

@minValue(1)
@maxValue(4)
@description('the node count is between 1 and 4.')
param GatewayNodeCount int = 2

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
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-mutiple-vms-with-data-management-gateway/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var delimiters = [
  '-'
  '_'
]
var prefix = split(GatewayName, delimiters)[0]
var gatewayId = resourceId(existingDataFactoryResourceGroup, 'Microsoft.DataFactory/dataFactories/gateways', existingDataFactoryName, GatewayName)
var storageAccountName_var = take(concat(toLower(prefix), uniqueString(resourceGroup().id, GatewayName)), 24)
var networkSecurityGroupName_var = '${GatewayName}nsg'
var vmTemplateLink = '${artifactsLocation}nested/VMtemplate.json${artifactsLocationSasToken}'
var subnetId = resourceId(existingVnetResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', existingVirtualNetworkName, existingSubnetInYourVnet)
var scriptURL = '${artifactsLocation}scripts/gatewayInstall.ps1${artifactsLocationSasToken}'

module nestedTemplate './nested_nestedTemplate.bicep' = {
  name: 'nestedTemplate'
  scope: resourceGroup(existingDataFactoryResourceGroup)
  params: {
    existingDataFactoryName: existingDataFactoryName
    GatewayName: GatewayName
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2016-09-01' = {
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

resource storageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
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

module VMtemplate '?' /*TODO: replace with correct path to [variables('vmTemplateLink')]*/ = [for i in range(0, GatewayNodeCount): {
  name: 'VMtemplate-${i}'
  params: {
    gatewayId: gatewayId
    virtualMachineName: take('vm${i}-${prefix}', 15)
    adminUserName: adminUserName
    adminPassword: adminPassword
    existingVnetLocation: existingVnetLocation
    subnetId: subnetId
    nsgId: networkSecurityGroupName.id
    storageAccountName: storageAccountName_var
    scriptUrl: scriptURL
  }
  dependsOn: [
    resourceId(existingDataFactoryResourceGroup, 'Microsoft.Resources/deployments', 'nestedTemplate')
    networkSecurityGroupName
    storageAccountName
  ]
}]