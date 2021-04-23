@description('Existing App Service Plan resource id that contains the App Service being updated')
param existingServerFarmId string

@description('User friendly certificate resource name')
param certificateName string

@description('Existing Key Vault resource Id with an access policy to allow Microsoft.Web RP to read Key Vault secrets (Checkout README.md for more information)')
param existingKeyVaultId string

@description('Key Vault Secret that contains a PFX certificate')
param existingKeyVaultSecretName string

@description('Existing App name to use for creating SSL binding. This App should have the hostname assigned as a custom domain')
param existingWebAppName string

@description('Custom hostname for creating SSL binding. This hostname should already be assigned to the Web App')
param hostname string

@description('Location for all resources.')
param location string = resourceGroup().location

resource certificateName_resource 'Microsoft.Web/certificates@2019-08-01' = {
  name: certificateName
  location: location
  properties: {
    keyVaultId: existingKeyVaultId
    keyVaultSecretName: existingKeyVaultSecretName
    serverFarmId: existingServerFarmId
  }
}

resource existingWebAppName_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: existingWebAppName
  location: location
  properties: {
    name: existingWebAppName
    hostNameSslStates: [
      {
        name: hostname
        sslState: 'SniEnabled'
        thumbprint: certificateName_resource.properties.thumbprint
        toUpdate: true
      }
    ]
  }
}