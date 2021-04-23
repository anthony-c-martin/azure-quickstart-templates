@description('Server Name for Azure database for MariaDB')
param serverName string

@minLength(1)
@description('Database administrator login name')
param administratorLogin string

@minLength(8)
@description('Database administrator password')
@secure()
param administratorLoginPassword string

@description('Azure database for MariaDB compute capacity in vCores (2,4,8,16,32)')
param skuCapacity int = 2

@description('Azure database for MariaDB sku name ')
param skuName string = 'GP_Gen5_2'

@description('Azure database for MariaDB Sku Size ')
param skuSizeMB int = 51200

@description('Azure database for MariaDB pricing tier')
param skuTier string = 'GeneralPurpose'

@description('Azure database for MariaDB sku family')
param skuFamily string = 'Gen5'

@allowed([
  '10.2'
  '10.3'
])
@description('MariaDB version')
param mariadbVersion string = '10.3'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('MariaDB Server backup retention days')
param backupRetentionDays int = 7

@description('Geo-Redundant Backup setting')
param geoRedundantBackup string = 'Disabled'

@description('Virtual Network Name')
param virtualNetworkName string = 'azure_mariadb_vnet'

@description('Subnet Name')
param subnetName string = 'azure_mariadb_subnet'

@description('Virtual Network RuleName')
param virtualNetworkRuleName string = 'AllowSubnet'

@description('Virtual Network Address Prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Subnet Address Prefix')
param subnetPrefix string = '10.0.0.0/16'

var firewallrules = {
  batch: {
    rules: [
      {
        Name: 'rule1'
        StartIpAddress: '0.0.0.0'
        EndIpAddress: '255.255.255.255'
      }
      {
        Name: 'rule2'
        StartIpAddress: '0.0.0.0'
        EndIpAddress: '255.255.255.255'
      }
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
}

resource virtualNetworkName_subnetName 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' = {
  parent: virtualNetworkName_resource
  name: '${subnetName}'
  location: location
  properties: {
    addressPrefix: subnetPrefix
  }
}

resource serverName_resource 'Microsoft.DBforMariaDB/servers@2018-06-01' = {
  name: serverName
  location: location
  sku: {
    name: skuName
    tier: skuTier
    capacity: skuCapacity
    size: skuSizeMB
    family: skuFamily
  }
  properties: {
    createMode: 'Default'
    version: mariadbVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storageProfile: {
      storageMB: skuSizeMB
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
  }
}

resource serverName_virtualNetworkRuleName 'Microsoft.DBforMariaDB/servers/virtualNetworkRules@2018-06-01' = {
  parent: serverName_resource
  name: '${virtualNetworkRuleName}'
  properties: {
    virtualNetworkSubnetId: virtualNetworkName_subnetName.id
    ignoreMissingVnetServiceEndpoint: true
  }
}

@batchSize(1)
resource serverName_firewallrules_batch_rules_Name 'Microsoft.DBforMariaDB/servers/firewallRules@2018-06-01' = [for i in range(0, length(firewallrules.batch.rules)): {
  name: '${serverName}/${firewallrules.batch.rules[i].Name}'
  location: location
  properties: {
    startIpAddress: firewallrules.batch.rules[i].StartIpAddress
    endIpAddress: firewallrules.batch.rules[i].EndIpAddress
  }
  dependsOn: [
    serverName_resource
  ]
}]