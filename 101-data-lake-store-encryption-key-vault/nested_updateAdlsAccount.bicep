param resourceId_parameters_keyVaultResourceGroupName_Microsoft_KeyVault_vaults_parameters_keyVaultName string

@description('The name of the Data Lake Store account to create.')
param dataLakeStoreName string

@description('The location in which to create the Data Lake Store account.')
param location string

@description('The Azure Key Vault encryption key name.')
param keyName string

@description('The Azure Key Vault encryption key version.')
param keyVersion string

resource dataLakeStoreName_resource 'Microsoft.DataLakeStore/accounts@2016-11-01' = {
  name: dataLakeStoreName
  location: location
  properties: {
    encryptionConfig: {
      keyVaultMetaInfo: {
        keyVaultResourceId: resourceId_parameters_keyVaultResourceGroupName_Microsoft_KeyVault_vaults_parameters_keyVaultName
        encryptionKeyName: keyName
        encryptionKeyVersion: keyVersion
      }
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}