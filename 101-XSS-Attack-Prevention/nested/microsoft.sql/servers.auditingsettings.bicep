param sqlServerName string
param storageAccountName string

resource sqlServerName_default 'Microsoft.Sql/servers/auditingSettings@2017-03-01-preview' = {
  name: '${sqlServerName}/default'
  properties: {
    state: 'Enabled'
    storageEndpoint: reference(resourceId('Microsoft.Storage/storageAccounts', storageAccountName), '2018-03-01-preview').PrimaryEndpoints.Blob
    storageAccountAccessKey: listKeys(resourceId('Microsoft.Storage/storageAccounts', storageAccountName), '2018-03-01-preview').keys[0].value
    retentionDays: 0
    auditActionsAndGroups: null
    storageAccountSubscriptionId: subscription().subscriptionId
    isStorageSecondaryKeyInUse: false
  }
}