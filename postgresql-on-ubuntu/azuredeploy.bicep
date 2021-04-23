@description('Domain name of the public jumpbox')
param domainName string = 'postgres-${uniqueString(resourceGroup().id)}'

@description('Virtual machine administrator username')
param adminUsername string

@description('Virtual machine administrator password')
@secure()
param adminPassword string

@allowed([
  'Small'
  'Medium'
  'Large'
  'XLarge'
])
@description('T-shirt size of the PostgreSQL deployment')
param tshirtSize string = 'Small'

@description('The replication password used for PostgreSQL streaming replication')
@secure()
param replicatorPassword string

@allowed([
  'Enabled'
  'Disabled'
])
@description('The flag allowing to enable or disable provisioning of the jumpbox VM that can be used to access the PostgreSQL environment')
param jumpbox string = 'Enabled'

@description('Size of the jumpbox VM, ignored if jumbox is disabled.')
param jumpBoxSize string = 'Standard_A1_V2'

@description('Virtual network name')
param virtualNetworkName string = 'vnet'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var sharedTemplateUrl = uri(artifactsLocation, 'shared-resources.json${artifactsLocationSasToken}')
var deploymentSize = {
  Small: {
    vmSize: 'Standard_A1_v2'
    diskSize: 1023
    diskCount: 2
    vmCount: 2
    slaveCount: 1
    storage: {
      count: 1
      pool: 'db'
      map: [
        0
        0
      ]
      jumpbox: 0
    }
  }
  Medium: {
    vmSize: 'Standard_A2_v2'
    diskSize: 1023
    diskCount: 8
    vmCount: 2
    slaveCount: 1
    storage: {
      count: 2
      pool: 'db'
      map: [
        0
        1
      ]
      jumpbox: 0
    }
  }
  Large: {
    vmSize: 'Standard_A4_v2'
    diskSize: 1023
    diskCount: 16
    vmCount: 3
    slaveCount: 2
    storage: {
      count: 2
      pool: 'db'
      map: [
        0
        1
        1
      ]
      jumpbox: 0
    }
  }
  XLarge: {
    vmSize: 'Standard_A8_v2'
    diskSize: 1023
    diskCount: 16
    vmCount: 4
    slaveCount: 3
    storage: {
      count: 2
      pool: 'db'
      map: [
        0
        0
        1
        1
      ]
      jumpbox: 0
    }
  }
}
var jumpboxTemplateUrl = uri(artifactsLocation, 'jumpbox-resources.json${artifactsLocationSasToken}')
var databaseTemplateUrl = uri(artifactsLocation, 'database-resources.json${artifactsLocationSasToken}')
var osSettings = {
  scripts: [
    uri(artifactsLocation, 'install_postgresql.sh${artifactsLocationSasToken}')
    'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/shared_scripts/ubuntu/vm-disk-utils-0.1.sh'
  ]
  imageReference: {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '18.04-LTS'
    version: 'latest'
  }
}
var networkSettings = {
  vnetName: virtualNetworkName
  addressPrefix: '10.0.0.0/16'
  subnets: {
    dmz: {
      name: 'dmz'
      prefix: '10.0.0.0/24'
      vnet: virtualNetworkName
    }
    data: {
      name: 'data'
      prefix: '10.0.1.0/24'
      vnet: virtualNetworkName
    }
  }
}
var availabilitySetSettings = {
  name: 'pgsqlAvailabilitySet'
  fdCount: 2
  udCount: 5
}

module shared '?' /*TODO: replace with correct path to [variables('sharedTemplateUrl')]*/ = {
  name: 'shared'
  params: {
    networkSettings: networkSettings
    availabilitySetSettings: availabilitySetSettings
    location: location
  }
}

module master_node '?' /*TODO: replace with correct path to [variables('databaseTemplateUrl')]*/ = {
  name: 'master-node'
  params: {
    location: location
    adminPassword: adminPassword
    replicatorPassword: replicatorPassword
    osSettings: osSettings
    subnet: networkSettings.subnets.data
    commonSettings: {
      adminUsername: adminUsername
      namespace: 'ms'
    }
    machineSettings: {
      vmSize: deploymentSize[tshirtSize].vmSize
      diskCount: deploymentSize[tshirtSize].diskCount
      diskSize: deploymentSize[tshirtSize].diskSize
      vmCount: 1
      availabilitySet: availabilitySetSettings.name
    }
    masterIpAddress: '0'
    dbType: 'MASTER'
  }
  dependsOn: [
    shared
  ]
}

module slave_node '?' /*TODO: replace with correct path to [variables('databaseTemplateUrl')]*/ = {
  name: 'slave-node'
  params: {
    location: location
    adminPassword: adminPassword
    replicatorPassword: replicatorPassword
    osSettings: osSettings
    subnet: networkSettings.subnets.data
    commonSettings: {
      adminUsername: adminUsername
      namespace: 'sl'
    }
    machineSettings: {
      vmSize: deploymentSize[tshirtSize].vmSize
      diskCount: deploymentSize[tshirtSize].diskCount
      diskSize: deploymentSize[tshirtSize].diskSize
      vmCount: deploymentSize[tshirtSize].slaveCount
      availabilitySet: availabilitySetSettings.name
    }
    masterIpAddress: reference('master-node').outputs.masterip.value
    dbType: 'SLAVE'
  }
  dependsOn: [
    master_node
  ]
}

module jumpbox_resource '?' /*TODO: replace with correct path to [variables('jumpboxTemplateUrl')]*/ = if ('Enabled' == jumpbox) {
  name: 'jumpbox'
  params: {
    location: location
    dnsName: domainName
    commonSettings: {
      adminUsername: adminUsername
      namespace: 'jumpbox'
    }
    adminPassword: adminPassword
    subnet: networkSettings.subnets.dmz
    osSettings: osSettings
    vmSize: jumpBoxSize
  }
  dependsOn: [
    shared
  ]
}