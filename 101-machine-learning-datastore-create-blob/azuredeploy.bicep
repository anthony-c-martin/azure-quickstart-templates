@description('Specifies the name of the Azure Machine Learning workspace which will hold this datastore target.')
param workspaceName string

@description('The name of the datastore, case insensitive, can only contain alphanumeric characters and underscore')
param datastoreName string

@description('The name of the storage account.')
param storageAccountName string

@description('The name of the azure blob container.')
param containerName string

@allowed([
  'SAS token'
  'Account Key'
])
@description('Authentication type')
param authenticationType string = 'SAS token'

@description('Storage account SAS token or Account Key')
@secure()
param sasTokenOrAccountKey string

@description('Optional : The subscription ID of the storage account. Defaults to selected subscription')
param storageAccountSubscriptionId string = subscription().subscriptionId

@description('Optional : The resource group of the storage account. Defaults to selected resource group')
param storageAccountResourceGroup string = resourceGroup().name

@description('Optional : If set to true, the call will skip datastore validation. Defaults to false')
param skipValidation bool = false

@description('The location of the Azure Machine Learning Workspace.')
param location string = resourceGroup().location

resource workspaceName_datastoreName 'Microsoft.MachineLearningServices/workspaces/datastores@2020-05-01-preview' = {
  name: '${workspaceName}/${datastoreName}'
  location: location
  properties: {
    dataStoreType: 'blob'
    SkipValidation: skipValidation
    AccountName: storageAccountName
    ContainerName: containerName
    AccountKey: ((authenticationType == 'Account Key') ? sasTokenOrAccountKey : json('null'))
    SasToken: ((authenticationType == 'SAS token') ? sasTokenOrAccountKey : json('null'))
    StorageAccountSubscriptionId: storageAccountSubscriptionId
    StorageAccountResourceGroup: storageAccountResourceGroup
  }
}