@description('The name of you Web Site.')
param siteName string = 'FuncApp-${uniqueString(resourceGroup().id)}'
param storageAccountName string = 'store${uniqueString(resourceGroup().id)}'

@description('Location for all resources.')
param location string = resourceGroup().location

var hostingPlanName_var = 'hpn-${resourceGroup().name}'
var storageAccountid = storageAccountName_resource.id

resource siteName_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: siteName
  kind: 'functionapp,linux'
  location: location
  properties: {
    name: siteName
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountid, '2019-06-01').keys[0].value}'
        }
      ]
    }
    serverFarmId: hostingPlanName.id
    clientAffinityEnabled: false
  }
}

resource hostingPlanName 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: hostingPlanName_var
  location: location
  kind: 'linux'
  properties: {
    reserved: true
  }
  sku: {
    tier: 'Dynamic'
    name: 'Y1'
  }
}

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}