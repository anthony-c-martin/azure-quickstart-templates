@allowed([
  'australiaeast'
  'eastus'
  'westeurope'
])
@description('Location for the resources.')
param location string

@description('Determines whether to deploy the function app and create the custom RP.')
param deployFunction bool = true

@description('Name of the function app to be created.')
param funcName string = uniqueString(resourceGroup().id)

@description('Name of the storage account for storing custom resources in the function app.')
param storageAccountName string = uniqueString(resourceGroup().id)

@description('Name of the custom resource that is being created.')
param azureCustomResourceName string

@description('The custom property value for the custom property on the custom resource.')
param myCustomPropertyValue string

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-custom-rp-with-function/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2018-02-01' = if (deployFunction) {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource funcName_resource 'Microsoft.Web/sites@2018-02-01' = if (deployFunction) {
  name: funcName
  location: location
  kind: 'functionapp'
  properties: {
    name: funcName
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsDashboard'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountName_resource.id, '2018-02-01').keys[0].value}'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountName_resource.id, '2018-02-01').keys[0].value}'
        }
        {
          name: 'AzureWebJobsSecretStorageType'
          value: 'Files'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountName_resource.id, '2018-02-01').keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: '${toLower(funcName)}b86e'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '6.5.0'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: uri(artifactsLocation, 'artifacts/functionzip/functionpackage.zip${artifactsLocationSasToken}')
        }
      ]
    }
    clientAffinityEnabled: false
    reserved: false
  }
}

resource Microsoft_CustomProviders_resourceProviders_funcName 'Microsoft.CustomProviders/resourceProviders@2018-09-01-preview' = if (deployFunction) {
  name: funcName
  location: location
  properties: {
    actions: [
      {
        name: 'ping'
        routingType: 'Proxy'
        endpoint: listSecrets(resourceId('Microsoft.Web/sites/functions', funcName, 'HttpTrigger1'), '2018-02-01').trigger_url
      }
    ]
    resourceTypes: [
      {
        name: 'customResources'
        routingType: 'Proxy'
        endpoint: listSecrets(resourceId('Microsoft.Web/sites/functions', funcName, 'HttpTrigger1'), '2018-02-01').trigger_url
      }
    ]
  }
  dependsOn: [
    funcName_resource
  ]
}

resource funcName_azureCustomResourceName 'Microsoft.CustomProviders/resourceProviders/customResources@2018-09-01-preview' = {
  parent: Microsoft_CustomProviders_resourceProviders_funcName
  name: '${azureCustomResourceName}'
  location: location
  properties: {
    hello: 'world'
    myCustomProperty: myCustomPropertyValue
  }
}