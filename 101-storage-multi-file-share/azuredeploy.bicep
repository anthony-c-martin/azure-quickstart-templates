@description('Specifies the name of the Azure Storage account.')
param storageAccountName string = 'storage${uniqueString(resourceGroup().id)}'

@description('Specifies the prefix of the file share names.')
param sharePrefix string = 'logs'

@description('Specifies the location in which the Azure Storage resources should be deployed.')
param location string = resourceGroup().location

@minValue(1)
@maxValue(100)
@description('Specifies the number of file shares to be created.')
param shareCopy int = 1

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  properties: {
    accessTier: 'Hot'
  }
}

resource storageAccountName_default_sharePrefix 'Microsoft.Storage/storageAccounts/fileServices/shares@2019-06-01' = [for i in range(0, shareCopy): {
  name: '${storageAccountName}/default/${sharePrefix}${i}'
  dependsOn: [
    storageAccountName_resource
  ]
}]