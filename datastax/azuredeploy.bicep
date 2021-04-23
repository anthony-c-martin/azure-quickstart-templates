@minValue(1)
@maxValue(40)
@description('Number of virtual machines to provision for the cluster')
param nodeCount int = 6

@allowed([
  'Standard_D1_v2'
  'Standard_D2_v2'
  'Standard_D3_v2'
  'Standard_D4_v2'
  'Standard_D5_v2'
  'Standard_D11_v2'
  'Standard_D12_v2'
  'Standard_D13_v2'
  'Standard_D14_v2'
  'Standard_D15_v2'
  'Standard_G1'
  'Standard_G2'
  'Standard_G3'
  'Standard_G4'
  'Standard_G5'
  'Standard_D1'
  'Standard_D2'
  'Standard_D3'
  'Standard_D4'
  'Standard_D11'
  'Standard_D12'
  'Standard_D13'
  'Standard_D14'
])
@description('Size of virtual machine to provision for the cluster')
param vmSize string = 'Standard_D2_v2'

@description('Admin user name for the virtual machines')
param adminUsername string

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/datastax/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

var nodesTemplateUrl = uri(artifactsLocation, 'nested/nodes.json${artifactsLocationSasToken}')
var opsCenterTemplateUrl = uri(artifactsLocation, 'nested/opscenter.json${artifactsLocationSasToken}')
var location_var = location
var uniqueString = uniqueString(resourceGroup().id, deployment().name)
var vnetName_var = 'vnet'
var subnetName = 'subnet'
var osSettings = {
  imageReference: {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '14.04.4-LTS'
    version: 'latest'
  }
  scripts: [
    uri(artifactsLocation, 'scripts/node.sh${artifactsLocationSasToken}')
    uri(artifactsLocation, 'scripts/opscenter.sh${artifactsLocationSasToken}')
  ]
}

resource vnetName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: vnetName_var
  location: location_var
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

module nodes '?' /*TODO: replace with correct path to [variables('nodesTemplateUrl')]*/ = {
  name: 'nodes'
  params: {
    location: location_var
    uniqueString: uniqueString
    adminUsername: adminUsername
    nodeCount: nodeCount
    vmSize: vmSize
    osSettings: osSettings
    vnetName: vnetName_var
    subnetName: subnetName
    namespace: 'dc0'
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
  }
  dependsOn: [
    vnetName
  ]
}

module opsCenter '?' /*TODO: replace with correct path to [variables('opsCenterTemplateUrl')]*/ = {
  name: 'opsCenter'
  params: {
    location: location_var
    uniqueString: uniqueString
    adminUsername: adminUsername
    osSettings: osSettings
    vnetName: vnetName_var
    subnetName: subnetName
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
  }
  dependsOn: [
    vnetName
  ]
}

output opsCenterURL string = 'http://opscenter${uniqueString}.${location_var}.cloudapp.azure.com:8888'