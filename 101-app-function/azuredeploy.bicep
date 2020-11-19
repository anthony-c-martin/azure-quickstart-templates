param siteName string {
  metadata: {
    description: 'The name of you Web Site.'
  }
  default: 'FuncApp-${uniqueString(resourceGroup().id)}'
}
param storageAccountName string = 'store${uniqueString(resourceGroup().id)}'
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var hostingPlanName = 'hpn-${resourceGroup().name}'
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
    serverFarmId: hostingPlanName_resource.id
    clientAffinityEnabled: false
  }
  dependsOn: [
    hostingPlanName_resource
    storageAccountName_resource
  ]
}

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: hostingPlanName
  location: location
  kind: 'linux'
  properties: {
    reserved: true
  }
  sku: {
    Tier: 'Dynamic'
    Name: 'Y1'
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