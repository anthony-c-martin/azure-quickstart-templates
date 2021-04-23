@description('Suffix for the storage account')
param storageAccountSuffix string

@description('Storage account')
param storageAccountType string = 'Standard_LRS'

@description('Location for all resources.')
param location string = resourceGroup().location

var storageName_var = concat(uniqueString(resourceGroup().id), storageAccountSuffix)

resource storageName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageName_var
  location: location
  properties: {
    accountType: storageAccountType
  }
}

output storageAccountName string = storageName_var