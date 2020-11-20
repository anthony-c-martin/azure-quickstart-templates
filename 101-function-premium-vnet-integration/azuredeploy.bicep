param location string {
  metadata: {
    description: 'Location for all resources except Application Insights.'
  }
  default: resourceGroup().location
}
param appInsightsLocation string {
  metadata: {
    description: 'Location for Application Insights.'
  }
}
param runtime string {
  allowed: [
    'node'
    'dotnet'
    'java'
  ]
  metadata: {
    description: 'The language worker runtime to load in the function app.'
  }
  default: 'node'
}
param appName string {
  metadata: {
    description: 'The name of the function app that you wish to create.'
  }
  default: 'fnapp${uniqueString(resourceGroup().id)}'
}
param storageAccountType string {
  allowed: [
    'Standard_LRS'
    'Standard_GRS'
    'Standard_RAGRS'
  ]
  metadata: {
    description: 'Storage Account type'
  }
  default: 'Standard_LRS'
}
param vnetName string {
  metadata: {
    description: 'The name of the virtual network to be created.'
  }
}
param subnetName string {
  metadata: {
    description: 'The name of the subnet to be created within the virtual network.'
  }
}

var vnetAddressPrefix = '10.0.0.0/16'
var subnetAddressPrefix = '10.0.0.0/24'
var functionAppName_var = appName
var hostingPlanName_var = appName
var applicationInsightsName_var = appName
var storageAccountName_var = '${uniqueString(resourceGroup().id)}azfunctions'
var functionWorkerRuntime = runtime
var appInsightsResourceId = applicationInsightsName.id

resource vnetName_res 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  location: location
  name: vnetName
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
                actions: [
                  'Microsoft.Network/virtualNetworks/subnets/action'
                ]
              }
            }
          ]
        }
      }
    ]
  }
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  location: location
  name: storageAccountName_var
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
}

resource applicationInsightsName 'Microsoft.Insights/components@2018-05-01-preview' = {
  location: appInsightsLocation
  name: applicationInsightsName_var
  kind: 'web'
  properties: {
    Application_Type: 'web'
    ApplicationId: applicationInsightsName_var
  }
}

resource hostingPlanName 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: hostingPlanName_var
  location: location
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
  }
  kind: 'elastic'
  properties: {
    maximumElasticWorkerCount: 20
  }
}

resource functionAppName 'Microsoft.Web/sites@2019-08-01' = {
  name: functionAppName_var
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: hostingPlanName.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(appInsightsResourceId, '2018-05-01-preview').instrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${reference(appInsightsResourceId, '2018-05-01-preview').instrumentationKey}'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listkeys(storageAccountName.id, '2019-06-01').keys[0].value};'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionWorkerRuntime
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~12'
        }
      ]
    }
  }
  dependsOn: [
    vnetName_res
  ]
}

resource functionAppName_virtualNetwork 'Microsoft.Web/sites/networkConfig@2019-08-01' = {
  name: '${functionAppName_var}/virtualNetwork'
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
    isSwift: true
  }
  dependsOn: [
    functionAppName
  ]
}