@description('Administrator user name used when provisioning virtual machines')
param adminUsername string

@description('MongoDB Administrator user name used when provisioning MongoDB sharding cluster')
param mongoAdminUsername string

@description('MongoDB Administrator password used when provisioning MongoDB sharding cluster')
@secure()
param mongoAdminPassword string

@description('DNS Name for the publicly accessible router nodes. Must be lowercase. It should match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.')
param dnsNamePrefix string

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

@allowed([
  1
  2
  3
  4
  5
  6
  7
  8
  9
  10
  11
  12
  13
  14
  15
  16
  32
])
@description('The number of data disks on each shard node. We will use Raid0 for the data disks to improve performance. On each shard.')
param numDataDisks int = 1

@minValue(1)
@maxValue(1023)
@description('The size of each data disk, the value is between 1 and 1023.')
param sizeOfDataDiskInGB int = 256

@description('The size of the virtual machines used when provisioning the router nodes')
param routerNodeVmSize string = 'Standard_DS3_v2'

@description('The size of the virtual machines used when provisioning config nodes')
param configNodeVmSize string = 'Standard_DS3_v2'

@description('The size of the virtual machines used when provisioning replica set nodes')
param replicaNodeVmSize string = 'Standard_DS3_v2'

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-mongodb-sharded-on-centos/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The password of the pem file that is used as ssl cert by the cluster')
@secure()
param mongoSSLCertPassword string

var configPrimaryNodeScript = uri(artifactsLocation, 'scripts/config_primary.sh${artifactsLocationSasToken}')
var configSecondaryNodeScript = uri(artifactsLocation, 'scripts/config_secondary.sh${artifactsLocationSasToken}')
var routerNodeScript = uri(artifactsLocation, 'scripts/router.sh${artifactsLocationSasToken}')
var replicaPrimaryNodeScript = uri(artifactsLocation, 'scripts/replica_primary.sh${artifactsLocationSasToken}')
var replicaSecondaryNodeScript = uri(artifactsLocation, 'scripts/replica_secondary.sh${artifactsLocationSasToken}')
var certificateLocation = uri(artifactsLocation, 'scripts/MongoAuthCert.pem${artifactsLocationSasToken}')
var templateBaseUrl = artifactsLocation
var sharedTemplateUrl = uri(templateBaseUrl, 'nested/shared-resources.json${artifactsLocationSasToken}')
var configTemplateUrl = uri(templateBaseUrl, 'nested/config-resources.json${artifactsLocationSasToken}')
var routerTemplateUrl = uri(templateBaseUrl, 'nested/router-resources.json${artifactsLocationSasToken}')
var replicaTemplateUrl = uri(templateBaseUrl, 'nested/replica-resources.json${artifactsLocationSasToken}')
var namespace = 'mongodb-'
var virtualNetworkName = 'myVNET'
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
    configPrimaryIp: '10.0.0.240'
    configSecondaryIp1: '10.0.0.241'
    configSecondaryIp2: '10.0.0.242'
    routerIp: '10.0.0.230'
    replicaPrimaryIp: '10.0.0.100'
  }
}
var configPrimaryOsSettings = {
  imageReference: {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: centOsVersion
    version: 'latest'
  }
  scripts: [
    configPrimaryNodeScript
  ]
  certificates: certificateLocation
}
var configSecondaryOsSettings = {
  imageReference: {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: centOsVersion
    version: 'latest'
  }
  scripts: [
    configSecondaryNodeScript
  ]
  certificates: certificateLocation
}
var routerOsSettings = {
  imageReference: {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: centOsVersion
    version: 'latest'
  }
  scripts: [
    routerNodeScript
  ]
  certificates: certificateLocation
}
var replicaPrimaryOsSettings = {
  imageReference: {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: centOsVersion
    version: 'latest'
  }
  scripts: [
    replicaPrimaryNodeScript
  ]
  certificates: certificateLocation
}
var replicaSecondaryOsSettings = {
  imageReference: {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: centOsVersion
    version: 'latest'
  }
  scripts: [
    replicaSecondaryNodeScript
  ]
  certificates: certificateLocation
}

module shared '?' /*TODO: replace with correct path to [variables('sharedTemplateUrl')]*/ = {
  name: 'shared'
  params: {
    networkSettings: networkSettings
    namespace: namespace
    location: location
  }
}

@batchSize(1)
module configSecondaryNode_1 '?' /*TODO: replace with correct path to [variables('configTemplateUrl')]*/ = [for i in range(0, 2): {
  name: 'configSecondaryNode${(i + 1)}'
  params: {
    adminUsername: adminUsername
    mongoAdminUsername: mongoAdminUsername
    mongoAdminPassword: mongoAdminPassword
    namespace: namespace
    vmbasename: 'configSecondary${(i + 1)}'
    subnet: networkSettings.subnet.dse
    vmSize: configNodeVmSize
    sizeOfDataDiskInGB: sizeOfDataDiskInGB
    numDataDisks: numDataDisks
    staticIp: networkSettings.statics['configSecondaryIp${(i + 1)}']
    osSettings: configSecondaryOsSettings
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
    location: location
    routerDnsNamePrefix: dnsNamePrefix
    roleType: 'Secondary'
    mongoSSLCertPassword: mongoSSLCertPassword
  }
  dependsOn: [
    shared
  ]
}]

module configPrimaryNode '?' /*TODO: replace with correct path to [variables('configTemplateUrl')]*/ = {
  name: 'configPrimaryNode'
  params: {
    adminUsername: adminUsername
    mongoAdminUsername: mongoAdminUsername
    mongoAdminPassword: mongoAdminPassword
    namespace: namespace
    vmbasename: 'configPrimary'
    sizeOfDataDiskInGB: sizeOfDataDiskInGB
    numDataDisks: numDataDisks
    subnet: networkSettings.subnet.dse
    staticIp: networkSettings.statics.configPrimaryIp
    vmSize: configNodeVmSize
    osSettings: configPrimaryOsSettings
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
    location: location
    routerDnsNamePrefix: dnsNamePrefix
    roleType: 'Primary'
    mongoSSLCertPassword: mongoSSLCertPassword
  }
  dependsOn: [
    shared
    configSecondaryNode_1
  ]
}

@batchSize(1)
module ReplicaSecondaryNode_1 '?' /*TODO: replace with correct path to [variables('replicaTemplateUrl')]*/ = [for i in range(0, 3): {
  name: 'ReplicaSecondaryNode${(i + 1)}'
  params: {
    adminUsername: adminUsername
    mongoAdminUsername: mongoAdminUsername
    mongoAdminPassword: mongoAdminPassword
    replSetName: 'repset1'
    namespace: namespace
    vmbasename: 'ReplicaSecondary${(i + 1)}'
    sizeOfDataDiskInGB: sizeOfDataDiskInGB
    numDataDisks: numDataDisks
    staticIp: networkSettings.statics.replicaPrimaryIp
    subnet: networkSettings.subnet.dse
    vmSize: replicaNodeVmSize
    osSettings: replicaSecondaryOsSettings
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
    location: location
    routerDnsNamePrefix: dnsNamePrefix
    roleType: 'Secondary'
    mongoSSLCertPassword: mongoSSLCertPassword
  }
  dependsOn: [
    shared
  ]
}]

module ReplicaPrimaryNode '?' /*TODO: replace with correct path to [variables('replicaTemplateUrl')]*/ = {
  name: 'ReplicaPrimaryNode'
  params: {
    adminUsername: adminUsername
    mongoAdminUsername: mongoAdminUsername
    mongoAdminPassword: mongoAdminPassword
    replSetName: 'repset1'
    namespace: namespace
    vmbasename: 'ReplicaPrimary'
    subnet: networkSettings.subnet.dse
    vmSize: replicaNodeVmSize
    sizeOfDataDiskInGB: sizeOfDataDiskInGB
    numDataDisks: numDataDisks
    staticIp: networkSettings.statics.replicaPrimaryIp
    osSettings: replicaPrimaryOsSettings
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
    location: location
    routerDnsNamePrefix: dnsNamePrefix
    roleType: 'Primary'
    mongoSSLCertPassword: mongoSSLCertPassword
  }
  dependsOn: [
    shared
    ReplicaSecondaryNode_1
  ]
}

module routerNode '?' /*TODO: replace with correct path to [variables('routerTemplateUrl')]*/ = {
  name: 'routerNode'
  params: {
    adminUsername: adminUsername
    mongoAdminUsername: mongoAdminUsername
    mongoAdminPassword: mongoAdminPassword
    namespace: namespace
    vmbasename: 'router'
    subnet: networkSettings.subnet.dse
    vmSize: routerNodeVmSize
    dnsname: dnsNamePrefix
    staticIp: networkSettings.statics.routerIp
    osSettings: routerOsSettings
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
    location: location
    mongoSSLCertPassword: mongoSSLCertPassword
  }
  dependsOn: [
    shared
    configPrimaryNode
    ReplicaPrimaryNode
  ]
}