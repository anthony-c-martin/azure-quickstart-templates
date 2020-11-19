param webAppName string {
  metadata: {
    description: 'That name is the name of our application. It has to be unique. Type a name followed by your resource group name. (<name>-<resourceGroupName>)'
  }
  default: 'ASPNET-${uniqueString(resourceGroup().id)}'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var alwaysOn = false
var sku = 'Free'
var skuCode = 'F1'
var workerSize = '0'
var workerSizeId = 0
var numberOfWorkers = '1'
var currentStack = 'dotnet'
var netFrameworkVersion = 'v4.0'
var hostingPlanName = 'hpn-${resourceGroup().name}'
var appInsight = 'insights-${webAppName}'

resource webAppName_resource 'Microsoft.Web/sites@2020-06-01' = {
  name: webAppName
  location: location
  properties: {
    name: webAppName
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(appInsight_resource.id, '2018-05-01-preview').InstrumentationKey
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'default'
        }
        {
          name: 'DiagnosticServices_EXTENSION_VERSION'
          value: 'disabled'
        }
        {
          name: 'APPINSIGHTS_PROFILERFEATURE_VERSION'
          value: 'disabled'
        }
        {
          name: 'APPINSIGHTS_SNAPSHOTFEATURE_VERSION'
          value: 'disabled'
        }
        {
          name: 'InstrumentationEngine_EXTENSION_VERSION'
          value: 'disabled'
        }
        {
          name: 'SnapshotDebugger_EXTENSION_VERSION'
          value: 'disabled'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_BaseExtensions'
          value: 'disabled'
        }
      ]
      metadata: [
        {
          name: 'CURRENT_STACK'
          value: currentStack
        }
      ]
      netFrameworkVersion: netFrameworkVersion
      alwaysOn: alwaysOn
    }
    serverFarmId: hostingPlanName_resource.id
    clientAffinityEnabled: true
  }
  dependsOn: [
    appInsight_resource
    hostingPlanName_resource
  ]
}

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: hostingPlanName
  location: location
  properties: {
    name: hostingPlanName
    workerSize: workerSize
    workerSizeId: workerSizeId
    numberOfWorkers: numberOfWorkers
  }
  sku: {
    Tier: sku
    Name: skuCode
  }
}

resource appInsight_resource 'microsoft.insights/components@2020-02-02-preview' = {
  name: appInsight
  location: location
  properties: {
    ApplicationId: webAppName
  }
}