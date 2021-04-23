@description('Name of the virtual network provisioned for the cluster')
param virtualNetworkName string = 'myVNET'

@description('Administrator user name used when provisioning virtual machines')
param adminUsername string

@description('Domain name for the publicly accessible Jenkins master node')
param dnsName string

@allowed([
  'Standard_D3'
  'Standard_D4'
])
@description('The size of the virtual machines used when provisioning the Jenkins master node')
param masterVmSize string = 'Standard_D3'

@description('Number of Jenkins slave node (1 is the default)')
param slaveNodes int = 1

@allowed([
  'Standard_D3'
  'Standard_D4'
])
@description('The size of the virtual machines used when provisioning Jenkins slave node(s)')
param slaveVmSize string = 'Standard_D3'

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
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/jenkins-on-ubuntu/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

var sharedTemplateUrl = uri(artifactsLocation, 'shared-resources.json${artifactsLocationSasToken}')
var jenkMasterTemplateUrl = uri(artifactsLocation, 'jenkmaster-resources.json${artifactsLocationSasToken}')
var jenkSlaveTemplateUrl = uri(artifactsLocation, 'jenkslave-resources.json${artifactsLocationSasToken}')
var namespace = 'jenk'
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
    jenkMaster: '10.0.0.240'
  }
}
var masterOsSettings = {
  imageReference: {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '14.04.4-LTS'
    version: 'latest'
  }
  scripts: [
    uri(artifactsLocation, 'jenkMstrInstall.sh${artifactsLocationSasToken}')
    uri(artifactsLocation, 'jenkAddNode.groovy${artifactsLocationSasToken}')
  ]
}
var slaveOsSettings = {
  imageReference: {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '14.04.4-LTS'
    version: 'latest'
  }
  scripts: [
    uri(artifactsLocation, 'jenkSlaveInstall.sh${artifactsLocationSasToken}')
  ]
}

module shared '?' /*TODO: replace with correct path to [variables('sharedTemplateUrl')]*/ = {
  name: 'shared'
  params: {
    networkSettings: networkSettings
  }
}

module jenkMasterNode '?' /*TODO: replace with correct path to [variables('jenkMasterTemplateUrl')]*/ = {
  name: 'jenkMasterNode'
  params: {
    adminUsername: adminUsername
    namespace: namespace
    vmbasename: 'Master'
    subnet: networkSettings.subnet.dse
    dnsname: dnsName
    staticIp: networkSettings.statics.jenkMaster
    vmSize: masterVmSize
    slaveNodes: slaveNodes
    osSettings: masterOsSettings
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
  }
  dependsOn: [
    shared
  ]
}

module jenkSlaveNode '?' /*TODO: replace with correct path to [variables('jenkSlaveTemplateUrl')]*/ = [for i in range(0, slaveNodes): {
  name: 'jenkSlaveNode${i}'
  params: {
    adminUsername: adminUsername
    namespace: namespace
    vmbasename: 'Slave${i}'
    masterNode: networkSettings.statics.jenkMaster
    subnet: networkSettings.subnet.dse
    vmSize: slaveVmSize
    osSettings: slaveOsSettings
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
  }
  dependsOn: [
    shared
    jenkMasterNode
  ]
}]