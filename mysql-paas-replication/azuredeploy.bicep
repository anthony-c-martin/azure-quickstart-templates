@description('Server name for the MySQL PaaS instance and it\'s replicas (replicas will get a \'-\' attached to the end with the replica number).')
param serverName string = uniqueString(resourceGroup().id)

@description('Location for the MySQL PaaS components to be deployed.')
param location string = resourceGroup().location

@description('Administrator name for MySQL servers.')
param administratorLogin string

@description('Password for the MySQL server administrator.')
@secure()
param administratorLoginPassword string

@description('Number of vCPUs for the MySQL Server instances to be deployed.')
param vCPU int = 2

@allowed([
  'Gen4'
  'Gen5'
])
@description('Hardware generation for the MySQL Server instances to be deployed.')
param skuFamily string = 'Gen5'

@minValue(5120)
@description('Storage capacity for the MySQL Server instances to be deployed.')
param skuSizeMB int = 5120

@allowed([
  'Basic'
  'GeneralPurpose'
  'MemoryOptimized'
])
@description('Performance tier for the MySQL Server instances to be deployed.')
param skuTier string = 'GeneralPurpose'

@allowed([
  0
  1
  2
  3
  4
  5
])
@description('Number of replica instances to be deployed.')
param numberOfReplicas int = 1

@allowed([
  '5.6'
  '5.7'
])
@description('MySQL version for the MySQL Server instances to be deployed.')
param version string = '5.7'

@description('Enable Azure hosted resources to access the master instance.')
param enableAzureResources bool = true

@description('Backup retention period.')
param backupRetentionDays int = 7

@allowed([
  'Enabled'
  'Disabled'
])
@description('Enable or disable geo redundant backups.')
param geoRedundantBackup string = 'Disabled'

@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/mysql-paas-replication/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

var nestedtemplateMySQL = uri(artifactsLocation, 'nested/mysql.json${artifactsLocationSasToken}')
var nestedtemplateMySQLReplica = uri(artifactsLocation, 'nested/mysqlReplica.json${artifactsLocationSasToken}')
var sourceServerId = resourceId('Microsoft.DBforMySQL/servers', serverName)
var skuName = '${((skuTier == 'GeneralPurpose') ? 'GP' : ((skuTier == 'Basic') ? 'B' : ((skuTier == 'MemoryOptimized') ? 'MO' : '')))}_${skuFamily}_${vCPU}'
var sku = {
  name: skuName
  tier: skuTier
  capacity: vCPU
  size: skuSizeMB
  family: skuFamily
}

module MySQLServer '?' /*TODO: replace with correct path to [variables('nestedtemplateMySQL')]*/ = {
  name: 'MySQLServer'
  params: {
    sku: sku
    serverName: serverName
    location: location
    version: version
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    backupRetentionDays: backupRetentionDays
    geoRedundantBackup: geoRedundantBackup
    enableAzureResources: enableAzureResources
    ServerId: sourceServerId
  }
}

module MySQLServerReplicas '?' /*TODO: replace with correct path to [variables('nestedtemplateMySQLReplica')]*/ = if (numberOfReplicas > 0) {
  name: 'MySQLServerReplicas'
  params: {
    sku: sku
    serverName: serverName
    location: location
    numberOfReplicas: numberOfReplicas
    backupRetentionDays: backupRetentionDays
    geoRedundantBackup: geoRedundantBackup
    sourceServerId: sourceServerId
  }
  dependsOn: [
    MySQLServer
  ]
}