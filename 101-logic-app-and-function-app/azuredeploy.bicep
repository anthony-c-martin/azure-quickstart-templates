@minLength(1)
@maxLength(80)
@description('Name of the Logic App.')
param LogicAppName string = 'logic-app-${uniqueString(resourceGroup().id)}'

@description('The name of the function app to create. Must be globally unique.')
param functionAppName string = 'fn-app-${uniqueString(resourceGroup().id)}'

@description('Location for all resources.')
param location string = resourceGroup().location

var repoUrl = 'https://github.com/AzureBytes/functionshttpecho.git'
var branch = 'master'
var functionName = 'Echo'
var hostingPlanName_var = functionAppName
var storageAccountName_var = 'azfunctions${uniqueString(resourceGroup().id)}'
var LogicAppLocation = location
var storageAccountType = 'Standard_LRS'

resource LogicAppName_resource 'Microsoft.Logic/workflows@2019-05-01' = {
  name: LogicAppName
  location: LogicAppLocation
  tags: {
    displayName: 'LogicApp'
  }
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      actions: {
        Azure_Function: {
          type: 'Function'
          inputs: {
            body: '@triggerBody()'
            function: {
              id: resourceId('Microsoft.Web/sites/functions', functionAppName, functionName)
            }
          }
          runAfter: {}
        }
        Response: {
          type: 'Response'
          inputs: {
            statusCode: 200
            body: '@body(\'Azure_Function\')'
          }
          runAfter: {
            Azure_Function: [
              'Succeeded'
            ]
          }
        }
      }
      parameters: {}
      triggers: {
        Request: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {}
          }
        }
      }
      contentVersion: '1.0.0.0'
      outputs: {}
    }
    parameters: {}
  }
  dependsOn: [
    functionAppName_web
  ]
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName_var
  location: location
  kind: 'StorageV2'
  sku: {
    name: storageAccountType
  }
}

resource hostingPlanName 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: hostingPlanName_var
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    name: hostingPlanName_var
    computeMode: 'Dynamic'
  }
}

resource functionAppName_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: hostingPlanName.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsDashboard'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountName.id, '2019-06-01').keys[0].value}'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountName.id, '2019-06-01').keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountName.id, '2019-06-01').keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~1'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '6.5.0'
        }
      ]
    }
  }
}

resource functionAppName_web 'Microsoft.Web/sites/sourcecontrols@2019-08-01' = {
  parent: functionAppName_resource
  name: 'web'
  properties: {
    repoUrl: repoUrl
    branch: branch
    isManualIntegration: true
  }
}