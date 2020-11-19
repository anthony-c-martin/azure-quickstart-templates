param existingServerFarmId string {
  metadata: {
    description: 'Existing App Service Plan resource id that contains the App Service being updated'
  }
}
param certificateName string {
  metadata: {
    description: 'User friendly certificate resource name'
  }
}
param existingKeyVaultId string {
  metadata: {
    description: 'Existing Key Vault resource Id with an access policy to allow Microsoft.Web RP to read Key Vault secrets (Checkout README.md for more information)'
  }
}
param existingKeyVaultSecretName string {
  metadata: {
    description: 'Key Vault Secret that contains a PFX certificate'
  }
}
param existingWebAppName string {
  metadata: {
    description: 'Existing App name to use for creating SSL binding. This App should have the hostname assigned as a custom domain'
  }
}
param hostname string {
  metadata: {
    description: 'Custom hostname for creating SSL binding. This hostname should already be assigned to the Web App'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource certificateName_res 'Microsoft.Web/certificates@2019-08-01' = {
  name: certificateName
  location: location
  properties: {
    keyVaultId: existingKeyVaultId
    keyVaultSecretName: existingKeyVaultSecretName
    serverFarmId: existingServerFarmId
  }
}

resource existingWebAppName_res 'Microsoft.Web/sites@2019-08-01' = {
  name: existingWebAppName
  location: location
  properties: {
    name: existingWebAppName
    hostNameSslStates: [
      {
        name: hostname
        sslState: 'SniEnabled'
        thumbprint: certificateName_res.properties.Thumbprint
        toUpdate: true
      }
    ]
  }
}