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
var functionAppName = appName
var hostingPlanName = appName
var applicationInsightsName = appName
var storageAccountName = '${uniqueString(resourceGroup().id)}azfunctions'
var functionWorkerRuntime = runtime
var appInsightsResourceId = applicationInsightsName_resource.id

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2019-11-01' = {
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

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  location: location
  name: storageAccountName
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
}

resource applicationInsightsName_resource 'Microsoft.Insights/components@2018-05-01-preview' = {
  location: appInsightsLocation
  name: applicationInsightsName
  kind: 'web'
  properties: {
    Application_Type: 'web'
    ApplicationId: applicationInsightsName
  }
}

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: hostingPlanName
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

resource functionAppName_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: hostingPlanName_resource.id
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
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listkeys(storageAccountName_resource.id, '2019-06-01').keys[0].value};'
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
    hostingPlanName_resource
    storageAccountName_resource
    vnetName_resource
  ]
}

resource functionAppName_virtualNetwork 'Microsoft.Web/sites/networkConfig@2019-08-01' = {
  name: '${functionAppName}/virtualNetwork'
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
    isSwift: true
  }
  dependsOn: [
    functionAppName_resource
  ]
}