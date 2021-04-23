@description('Administrator user name used when provisioning virtual machines')
param adminUsername string

@description('DNS Label for the Public IP. Must be lowercase. It should match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.')
param dnsLabelPrefix string

@allowed([
  'Standard_A1'
  'Standard_A2'
  'Standard_A3'
  'Standard_D1_V2'
  'Standard_D3_V2'
  'Standard_D4_V2'
])
@description('The size of the virtual machines used when provisioning the Lap node')
param lapVmSize string = 'Standard_D1_V2'

@description('Number of Neo4J node (1 is the default)')
param neo4jNodes int = 1

@allowed([
  'Standard_A1'
  'Standard_A2'
  'Standard_A3'
  'Standard_D1_V2'
  'Standard_D3_V2'
  'Standard_D4_V2'
])
@description('The size of the virtual machines used when provisioning Neo4J node(s)')
param neo4jVmSize string = 'Standard_D1_V2'

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
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/lap-neo4j-ubuntu/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

var sharedTemplateUrl = uri(artifactsLocation, 'nested/shared-resources.json${artifactsLocationSasToken}')
var lanpLapTemplateUrl = uri(artifactsLocation, 'nested/lanplap-resources.json${artifactsLocationSasToken}')
var lanpneo4jTemplateUrl = uri(artifactsLocation, 'nested/lanpneo4j-resources.json${artifactsLocationSasToken}')
var namespace = 'lanp-'
var virtualNetworkName = 'myVNET'
var networkSettings = {
  virtualNetworkName: 'myVNET'
  addressPrefix: '10.0.0.0/16'
  subnet: {
    dse: {
      name: 'dse'
      prefix: '10.0.0.0/24'
      vnet: 'myVNET'
    }
  }
  statics: {
    clusterRange: {
      base: '10.0.0.'
      start: 5
    }
    lapip: '10.0.0.240'
    neo4jip: '10.0.0.10'
  }
}
var lapOsSettings = {
  imageReference: {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '16.04.0-LTS'
    version: 'latest'
  }
  scripts: [
    uri(artifactsLocation, 'scripts/install-lap.sh${artifactsLocationSasToken}')
  ]
}
var neo4jOsSettings = {
  imageReference: {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '16.04.0-LTS'
    version: 'latest'
  }
  scripts: [
    uri(artifactsLocation, 'scripts/install-neo4j.sh${artifactsLocationSasToken}')
  ]
}

module shared '?' /*TODO: replace with correct path to [variables('sharedTemplateUrl')]*/ = {
  name: 'shared'
  params: {
    networkSettings: networkSettings
  }
}

module lanpLapNode '?' /*TODO: replace with correct path to [variables('lanpLapTemplateUrl')]*/ = {
  name: 'lanpLapNode'
  params: {
    adminUsername: adminUsername
    namespace: namespace
    vmbasename: 'Lap'
    subnet: networkSettings.subnet.dse
    dnsname: dnsLabelPrefix
    staticIp: networkSettings.statics.lapip
    vmSize: lapVmSize
    neo4jNodes: neo4jNodes
    osSettings: lapOsSettings
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
  }
  dependsOn: [
    shared
  ]
}

module lanpNeo4jNode '?' /*TODO: replace with correct path to [variables('lanpneo4jTemplateUrl')]*/ = [for i in range(0, neo4jNodes): {
  name: 'lanpNeo4jNode${i}'
  params: {
    adminUsername: adminUsername
    namespace: namespace
    vmbasename: 'neo4j${i}'
    lapNode: networkSettings.statics.lapip
    neo4jstaticIp: networkSettings.statics.neo4jip
    subnet: networkSettings.subnet.dse
    vmSize: neo4jVmSize
    osSettings: neo4jOsSettings
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
  }
  dependsOn: [
    shared
    lanpLapNode
  ]
}]