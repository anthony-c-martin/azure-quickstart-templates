param storageAccountName string {
  metadata: {
    description: 'Storage Account Name'
  }
  default: ''
}
param storageApiVersion string {
  allowed: [
    '2015-05-01-preview'
    '2015-06-15'
  ]
  metadata: {
    description: 'API Version for the Storage Account'
  }
  default: '2015-06-15'
}
param location string {
  metadata: {
    description: 'Storage Account Deployment Location'
  }
  default: 'westus'
}
param tag object {
  metadata: {
    description: 'Tag Values'
  }
  default: {
    key1: 'key'
    value1: 'value'
  }
}
param storageAccountType string {
  allowed: [
    'Standard_LRS'
    'Standard_ZRS'
    'Standard_GRS'
    'Standard_RAGRS'
    'Premium_LRS'
  ]
  metadata: {
    description: 'Stoarge Account Type'
  }
  default: 'Standard_LRS'
}
param informaticaTags object
param quickstartTags object

resource storageAccountName_res 'Microsoft.Storage/storageAccounts@2015-06-15' = {
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

output primaryKey string = listKeys(storageAccountName_res.id, '2015-06-15').key1