@description('Storage Account Name')
param storageAccountName string = ''

@allowed([
  '2015-05-01-preview'
  '2015-06-15'
])
@description('API Version for the Storage Account')
param storageApiVersion string = '2015-06-15'

@description('Storage Account Deployment Location')
param location string = 'westus'

@description('Tag Values')
param tag object = {
  key1: 'key'
  value1: 'value'
}

@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Premium_LRS'
])
@description('Stoarge Account Type')
param storageAccountType string = 'Standard_LRS'
param informaticaTags object
param quickstartTags object

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageAccountName
  location: location
  tags: {
    '${tag.key1}': tag.value1
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
  properties: {
    accountType: storageAccountType
  }
}

output primaryKey string = listKeys(storageAccountName_resource.id, '2015-06-15').key1