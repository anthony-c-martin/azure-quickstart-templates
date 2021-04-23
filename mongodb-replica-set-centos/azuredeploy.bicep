@description('Administrator user name used when provisioning virtual machines')
param adminUsername string

@description('MongoDB Administrator user name used when provisioning MongoDB replica set')
param mongoAdminUsername string

@description('MongoDB Administrator password used when provisioning MongoDB replica set')
@secure()
param mongoAdminPassword string

@description('DNS Name for the publicly accessible primary node. Must be lowercase. It should match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.')
param dnsNamePrefix string

@minValue(1)
@maxValue(1023)
@description('The size of each data disk, the value is between 1 and 1023. We use 4 data disks on each VM for raid0 to improve performance.')
param sizeOfDataDiskInGB int = 20

@allowed([
  '6.5'
  '6.6'
  '6.7'
  '7.0'
  '7.1'
  '7.2'
  '7.3'
  '7.4'
  '7.5'
  '7.6'
  '7.7'
])
@description('The CentOS version for the VM. This will pick a fully patched image of this given CentOS version.')
param centOsVersion string = '7.7'

@description('Number of MongoDB secondary node (2 is the default), the value should be even numbers, like 2, 4, or 6. And 6 is the maximum number of secondary nodes.')
param secondaryNodeCount int = 2

@description('The size of the virtual machines used when provisioning the primary node')
param primaryNodeVmSize string = 'Standard_A4_v2'

@description('The size of the virtual machines used when provisioning secondary node(s)')
param secondaryNodeVmSize string = 'Standard_A4_v2'

@description('The zabbix server IP which will monitor the mongodb nodes\' mongodb status. Null means no zabbix server.')
param zabbixServerIPAddress string = ''

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

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var primaryNodeScript = uri(artifactsLocation, 'scripts/primary.sh${artifactsLocationSasToken}')
var secondaryNodeScript = uri(artifactsLocation, 'scripts/secondary.sh${artifactsLocationSasToken}')
var sharedTemplateUrl = uri(artifactsLocation, 'nested/shared-resources.json${artifactsLocationSasToken}')
var primaryTemplateUrl = uri(artifactsLocation, 'nested/primary-resources.json${artifactsLocationSasToken}')
var secondaryTemplateUrl = uri(artifactsLocation, 'nested/secondary-resources.json${artifactsLocationSasToken}')
var namespace = 'mongodb-'
var virtualNetworkName = 'myVNET1'
var networkSettings = {
  virtualNetworkName: virtualNetworkName
  addressPrefix: '10.0.0.0/16'
  subnet: {
    dse: {
      name: 'dse'
      prefix: '10.0.1.0/24'
      vnet: virtualNetworkName
    }
  }
  statics: {
    clusterRange: {
      base: '10.0.1.'
      start: 5
    }
    primaryIp: '10.0.1.240'
  }
}
var primaryOsSettings = {
  imageReference: {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: centOsVersion
    version: 'latest'
  }
  scripts: [
    primaryNodeScript
  ]
}
var secondaryOsSettings = {
  imageReference: {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: centOsVersion
    version: 'latest'
  }
  scripts: [
    secondaryNodeScript
  ]
}

module shared '?' /*TODO: replace with correct path to [variables('sharedTemplateUrl')]*/ = {
  name: 'shared'
  params: {
    networkSettings: networkSettings
    namespace: namespace
    location: location
  }
}

module secondaryNode '?' /*TODO: replace with correct path to [variables('secondaryTemplateUrl')]*/ = [for i in range(0, secondaryNodeCount): {
  name: 'secondaryNode${i}'
  params: {
    adminUsername: adminUsername
    namespace: namespace
    vmbasename: 'secondary${i}'
    subnet: networkSettings.subnet.dse
    sizeOfDataDiskInGB: sizeOfDataDiskInGB
    dnsname: dnsNamePrefix
    vmSize: secondaryNodeVmSize
    zabbixServerIPAddress: zabbixServerIPAddress
    osSettings: secondaryOsSettings
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
    location: location
  }
  dependsOn: [
    shared
  ]
}]

module primaryNode '?' /*TODO: replace with correct path to [variables('primaryTemplateUrl')]*/ = {
  name: 'primaryNode'
  params: {
    adminUsername: adminUsername
    mongoAdminUsername: mongoAdminUsername
    mongoAdminPassword: mongoAdminPassword
    namespace: namespace
    vmbasename: 'primary'
    subnet: networkSettings.subnet.dse
    dnsname: dnsNamePrefix
    staticIp: networkSettings.statics.primaryIp
    secondaryNodeCount: secondaryNodeCount
    sizeOfDataDiskInGB: sizeOfDataDiskInGB
    vmSize: primaryNodeVmSize
    zabbixServerIPAddress: zabbixServerIPAddress
    osSettings: primaryOsSettings
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
    location: location
  }
  dependsOn: [
    shared
    secondaryNode
  ]
}