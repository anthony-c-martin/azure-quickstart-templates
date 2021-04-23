@description('Server Name for Azure database for MySQL')
param serverName string

@minLength(1)
@description('Database administrator login name')
param administratorLogin string

@minLength(8)
@description('Database administrator password')
@secure()
param administratorLoginPassword string

@description('Azure database for MySQL compute capacity in vCores (2,4,8,16,32)')
param skuCapacity int = 2

@description('Azure database for MySQL sku name ')
param skuName string = 'GP_Gen5_2'

@description('Azure database for MySQL Sku Size ')
param SkuSizeMB int = 5120

@description('Azure database for MySQL pricing tier')
param SkuTier string = 'GeneralPurpose'

@description('Azure database for MySQL sku family')
param skuFamily string = 'Gen5'

@allowed([
  '5.6'
  '5.7'
])
@description('MySQL version')
param mysqlVersion string = '5.7'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('MySQL Server backup retention days')
param backupRetentionDays int = 7

@description('Geo-Redundant Backup setting')
param geoRedundantBackup string = 'Disabled'

@description('Virtual Network Name')
param virtualNetworkName string = 'azure_mysql_vnet'

@description('Subnet Name')
param subnetName string = 'azure_mysql_subnet'

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

resource serverName_resource 'Microsoft.DBforMySQL/servers@2017-12-01' = {
  name: serverName
  location: location
  sku: {
    name: skuName
    tier: SkuTier
    capacity: skuCapacity
    size: SkuSizeMB
    family: skuFamily
  }
  properties: {
    createMode: 'Default'
    version: mysqlVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storageProfile: {
      storageMB: SkuSizeMB
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
  }
}

resource serverName_virtualNetworkRuleName 'Microsoft.DBforMySQL/servers/virtualNetworkRules@2017-12-01' = {
  parent: serverName_resource
  name: '${virtualNetworkRuleName}'
  properties: {
    virtualNetworkSubnetId: virtualNetworkName_subnetName.id
    ignoreMissingVnetServiceEndpoint: true
  }
}

@batchSize(1)
resource serverName_firewallrules_batch_rules_Name 'Microsoft.DBforMySQL/servers/firewallRules@2017-12-01' = [for i in range(0, length(firewallrules.batch.rules)): {
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