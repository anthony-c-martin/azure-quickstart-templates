@description('Location for all resources.')
param location string = resourceGroup().location

@description('The name of the web app that you wish to create.')
param webAppName string

@description('The custom hostname that you wish to add.')
param customHostname string

@description('Existing Key Vault resource Id for the SSL certificate, leave this blank if not enabling SSL')
param existingKeyVaultId string = ''

@description('Key Vault Secret that contains a PFX certificate, leave this blank if not enabling SSL')
param existingKeyVaultSecretName string = ''

var appServicePlanName_var = '${webAppName}-asp-${uniqueString(resourceGroup().id)}'
var certificateName_var = '${webAppName}-cert'
var enableSSL = (!empty(existingKeyVaultId))

resource appServicePlanName 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: appServicePlanName_var
  location: location
  properties: {
    name: appServicePlanName_var
  }
  sku: {
    name: 'P1'
    tier: 'Premium'
    size: '1'
    family: 'P'
    capacity: '1'
  }
}

resource webAppName_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: webAppName
  location: location
  properties: {
    name: webAppName
    serverFarmId: appServicePlanName.id
  }
}

resource certificateName 'Microsoft.Web/certificates@2019-08-01' = if (enableSSL) {
  name: certificateName_var
  location: location
  properties: {
    keyVaultId: existingKeyVaultId
    keyVaultSecretName: existingKeyVaultSecretName
    serverFarmId: appServicePlanName.id
  }
  dependsOn: [
    webAppName_resource
  ]
}

resource webAppName_customHostname 'Microsoft.Web/sites/hostnameBindings@2019-08-01' = {
  parent: webAppName_resource
  name: '${customHostname}'
  location: location
  properties: {
    sslState: (enableSSL ? 'SniEnabled' : json('null'))
    thumbprint: (enableSSL ? certificateName.properties.thumbprint : json('null'))
  }
}