param virtualNetworkName string {
  metadata: {
    description: 'Name of the virtual network provisioned for the cluster'
  }
  default: 'myVNET'
}
param adminUsername string {
  metadata: {
    description: 'Administrator user name used when provisioning virtual machines'
  }
}
param mysqlPassword string {
  metadata: {
    description: 'Mysql root password used when installing MySQL Server 5.5'
  }
  secure: true
}
param dnsNamePrefix string {
  metadata: {
    description: 'DNS Name for the publicly accessible Lap node. Must be lowercase. It should match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.'
  }
}
param haproxyVmSize string {
  metadata: {
    description: 'The size of the virtual machines used when provisioning the Lap node'
  }
  default: 'Standard_D3_v2'
}
param mysqlVmSize string {
  metadata: {
    description: 'The size of the virtual machines used when provisioning Mysql node(s)'
  }
  default: 'Standard_D3_v2'
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/mysql-mha-haproxy-ubuntu/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param authenticationType string {
  allowed: [
    'sshPublicKey'
    'password'
  ]
  metadata: {
    description: 'Type of authentication to use on the Virtual Machine. SSH key is recommended.'
  }
  default: 'sshPublicKey'
}
param adminPasswordOrKey string {
  metadata: {
    description: 'SSH Key or password for the Virtual Machine. SSH key is recommended.'
  }
  secure: true
}

var sharedTemplateUrl = uri(artifactsLocation, 'nested/shared-resources.json${artifactsLocationSasToken}')
var haproxyTemplateUrl = uri(artifactsLocation, 'nested/haproxy-resources.json${artifactsLocationSasToken}')
var masterTemplateUrl = uri(artifactsLocation, 'nested/master-resources.json${artifactsLocationSasToken}')
var slaveTemplateUrl01 = uri(artifactsLocation, 'nested/slave01-resources.json${artifactsLocationSasToken}')
var slaveTemplateUrl02 = uri(artifactsLocation, 'nested/slave02-resources.json${artifactsLocationSasToken}')
var namespace = 'mha-'
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
    haproxyIp: '10.0.0.9'
    masterIp: '10.0.0.10'
    slaveIp01: '10.0.0.11'
    slaveIp02: '10.0.0.12'
  }
}
var haproxyOsSettings = {
  imageReference: {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '14.04.4-LTS'
    version: 'latest'
  }
  scripts: [
    uri(artifactsLocation, 'scripts/haproxy.sh${artifactsLocationSasToken}')
  ]
}
var masterOsSettings = {
  imageReference: {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '14.04.4-LTS'
    version: 'latest'
  }
  scripts: [
    uri(artifactsLocation, 'scripts/master.sh${artifactsLocationSasToken}')
  ]
}
var slaveOsSettings01 = {
  imageReference: {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '14.04.4-LTS'
    version: 'latest'
  }
  scripts: [
    uri(artifactsLocation, 'scripts/slave01.sh${artifactsLocationSasToken}')
  ]
}
var slaveOsSettings02 = {
  imageReference: {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '14.04.4-LTS'
    version: 'latest'
  }
  scripts: [
    uri(artifactsLocation, 'scripts/slave02.sh${artifactsLocationSasToken}')
  ]
}

module shared '?' /*TODO: replace with correct path to [variables('sharedTemplateUrl')]*/ = {
  name: 'shared'
  params: {
    networkSettings: networkSettings
  }
}

module haproxyNode '?' /*TODO: replace with correct path to [variables('haproxyTemplateUrl')]*/ = {
  name: 'haproxyNode'
  params: {
    adminUsername: adminUsername
    mysqlPassword: mysqlPassword
    namespace: namespace
    vmbasename: 'Haproxy'
    subnet: networkSettings.subnet.dse
    dnsname: dnsNamePrefix
    staticIp: networkSettings.statics.haproxyIp
    vmSize: haproxyVmSize
    osSettings: haproxyOsSettings
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
  }
  dependsOn: [
    shared
  ]
}

module masterNode '?' /*TODO: replace with correct path to [variables('masterTemplateUrl')]*/ = {
  name: 'masterNode'
  params: {
    adminUsername: adminUsername
    mysqlPassword: mysqlPassword
    namespace: namespace
    vmbasename: 'Master'
    masterNodeIp: networkSettings.statics.masterIp
    subnet: networkSettings.subnet.dse
    vmSize: mysqlVmSize
    osSettings: masterOsSettings
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
  }
  dependsOn: [
    shared
    haproxyNode
  ]
}

module slaveNode01 '?' /*TODO: replace with correct path to [variables('slaveTemplateUrl01')]*/ = {
  name: 'slaveNode01'
  params: {
    adminUsername: adminUsername
    mysqlPassword: mysqlPassword
    namespace: namespace
    vmbasename: 'Slave01'
    masterNodeIp: networkSettings.statics.masterIp
    slaveStaticIp: networkSettings.statics.slaveIp01
    subnet: networkSettings.subnet.dse
    vmSize: mysqlVmSize
    osSettings: slaveOsSettings01
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
  }
  dependsOn: [
    shared
    haproxyNode
    masterNode
  ]
}

module slaveNode02 '?' /*TODO: replace with correct path to [variables('slaveTemplateUrl02')]*/ = {
  name: 'slaveNode02'
  params: {
    adminUsername: adminUsername
    mysqlPassword: mysqlPassword
    namespace: namespace
    vmbasename: 'Slave02'
    masterNodeIp: networkSettings.statics.masterIp
    slaveStaticIp: networkSettings.statics.slaveIp02
    subnet: networkSettings.subnet.dse
    vmSize: mysqlVmSize
    osSettings: slaveOsSettings02
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
  }
  dependsOn: [
    shared
    haproxyNode
    masterNode
  ]
}