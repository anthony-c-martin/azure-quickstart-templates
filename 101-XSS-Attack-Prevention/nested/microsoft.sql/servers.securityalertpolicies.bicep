param sqlServerName string
param storageAccountName string

@description('Specifies the semicolon-separated list of e-mail addresses to which the alert is sent.')
param sendAlertsTo string = 'dummy@contoso.com'

resource sqlServerName_default 'Microsoft.Sql/servers/securityAlertPolicies@2015-05-01-preview' = {
  name: '${sqlServerName}/default'
  properties: {
    state: 'Enabled'
    disabledAlerts: ''
    emailAddresses: sendAlertsTo
    storageEndpoint: reference(resourceId('Microsoft.Storage/storageAccounts', storageAccountName), '2018-03-01-preview').PrimaryEndpoints.Blob
    storageAccountAccessKey: listKeys(resourceId('Microsoft.Storage/storageAccounts', storageAccountName), '2018-03-01-preview').keys[0].value
    retentionDays: 0
  }
}