@description('Administrator user name used when provisioning virtual machines')
param adminUsername string

@description('DNS Name for the publicly accessible Lap node. Must be lowercase. It should match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.')
param dnsNamePrefix string = 'lap-mysql-${uniqueString(resourceGroup().id)}'

@description('The size of the virtual machines used when provisioning the Lap node')
param lapVmSize string = 'Standard_D3'

@description('Number of Mysql node (1 is the default)')
param mysqlNodes int = 1

@description('The size of the virtual machines used when provisioning Mysql node(s)')
param mysqlVmSize string = 'Standard_D3'

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/lap-mysql-ubuntu/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

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

var sharedTemplateUrl = uri(artifactsLocation, 'shared-resources.json${artifactsLocationSasToken}')
var lampLapTemplateUrl = uri(artifactsLocation, 'lamplap-resources.json${artifactsLocationSasToken}')
var lampMysqlTemplateUrl = uri(artifactsLocation, 'lampmysql-resources.json${artifactsLocationSasToken}')
var virtualNetworkName = 'virtualNetwork'
var namespace = 'lamp-'
var networkSettings = {
  virtualNetworkName: virtualNetworkName
  addressPrefix: '10.0.0.0/16'
  subnet: {
    dse: {
      name: 'dse'
      prefix: '10.0.0.0/24'
      vnet: virtualNetworkName
    }
  }
  statics: {
    clusterRange: {
      base: '10.0.0.'
      start: 5
    }
    lapip: '10.0.0.240'
    mysqlip: '10.0.0.10'
  }
}
var lapOsSettings = {
  imageReference: {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '14.04.5-LTS'
    version: 'latest'
  }
  scripts: [
    uri(artifactsLocation, 'install-lap.sh${artifactsLocationSasToken}')
  ]
}
var mysqlOsSettings = {
  imageReference: {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '14.04.5-LTS'
    version: 'latest'
  }
  scripts: [
    uri(artifactsLocation, 'install-mysql.sh${artifactsLocationSasToken}')
  ]
}

module shared '?' /*TODO: replace with correct path to [variables('sharedTemplateUrl')]*/ = {
  name: 'shared'
  params: {
    networkSettings: networkSettings
    location: location
  }
}

module lampLapNode '?' /*TODO: replace with correct path to [variables('lampLapTemplateUrl')]*/ = {
  name: 'lampLapNode'
  params: {
    adminUsername: adminUsername
    namespace: namespace
    vmbasename: 'lap'
    subnet: networkSettings.subnet.dse
    dnsname: dnsNamePrefix
    staticIp: networkSettings.statics.lapip
    vmSize: lapVmSize
    mysqlNodes: mysqlNodes
    osSettings: lapOsSettings
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
    location: location
  }
  dependsOn: [
    shared
  ]
}

module lampMysqlNode '?' /*TODO: replace with correct path to [variables('lampMysqlTemplateUrl')]*/ = [for i in range(0, mysqlNodes): {
  name: 'lampMysqlNode${i}'
  params: {
    adminUsername: adminUsername
    namespace: namespace
    vmbasename: 'mysql${i}'
    lapNode: networkSettings.statics.lapip
    mysqlstaticIp: networkSettings.statics.mysqlip
    subnet: networkSettings.subnet.dse
    vmSize: mysqlVmSize
    osSettings: mysqlOsSettings
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
    location: location
  }
  dependsOn: [
    shared
    lampLapNode
  ]
}]