@description('Azure SQL server name to create')
param sqlServerName string = 'sql-server'

@description('Azure SQL server administrator name')
param sqlServerAdministrator string

@description('Azure SQL server administrator password')
@secure()
param sqlServerAdministratorPwd string

@description('Key vault name where the key to use is stored')
param keyVaultName string

@description('Key vault resource group name where it is stored')
param keyVaultResourceGroupName string

@description('Key name in the key vault to use as encryption protector')
param keyName string

@description('Version of the key in the key vault to use as encryption protector')
param keyVersion string

@description('Location for all resources.')
param location string = resourceGroup().location

var sqlServerKeyName = '${keyVaultName}_${keyName}_${keyVersion}'

resource sqlServerName_resource 'Microsoft.Sql/servers@2020-02-02-preview' = {
  name: sqlServerName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: sqlServerAdministrator
    administratorLoginPassword: sqlServerAdministratorPwd
    version: '12.0'
  }
}

module addAccessPolicy './nested_addAccessPolicy.bicep' = {
  name: 'addAccessPolicy'
  scope: resourceGroup(keyVaultResourceGroupName)
  params: {
    resourceId_Microsoft_Sql_servers_parameters_sqlServerName: reference(sqlServerName_resource.id, '2019-06-01-preview', 'Full')
    keyVaultName: keyVaultName
  }
}

resource sqlServerName_sqlServerKeyName 'Microsoft.Sql/servers/keys@2020-02-02-preview' = {
  parent: sqlServerName_resource
  name: '${sqlServerKeyName}'
  properties: {
    serverKeyType: 'AzureKeyVault'
    uri: '${reference(resourceId(keyVaultResourceGroupName, 'Microsoft.KeyVault/vaults/', keyVaultName), '2018-02-14-preview', 'Full').properties.vaultUri}keys/${keyName}/${keyVersion}'
  }
  dependsOn: [
    addAccessPolicy
  ]
}

resource sqlServerName_current 'Microsoft.Sql/servers/encryptionProtector@2020-02-02-preview' = {
  parent: sqlServerName_resource
  name: 'current'
  kind: 'azurekeyvault'
  properties: {
    serverKeyName: sqlServerKeyName
    serverKeyType: 'AzureKeyVault'
  }
  dependsOn: [
    sqlServerName_sqlServerKeyName
  ]
}