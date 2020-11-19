param webAppName string {
  metadata: {
    description: 'That name is the name of our application. It has to be unique.Type a name followed by your resource group name. (<name>-<resourceGroupName>)'
  }
  default: 'Django-${uniqueString(resourceGroup().id)}'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var sku = 'Free'
var skuCode = 'F1'
var workerSize = '0'
var appInsights_var = '${webAppName}-insights'
var hostingPlanName_var = 'hpn-${resourceGroup().name}'

resource webAppName_res 'Microsoft.Web/sites@2020-06-01' = {
  name: webAppName
  location: location
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'default'
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
        }
      ]
      linuxFxVersion: 'DOCKER|appsvcorg/django-python:0.1'
    }
    name: webAppName
    clientAffinityEnabled: false
    serverFarmId: hostingPlanName.id
  }
  dependsOn: [
    appInsights
  ]
}

resource hostingPlanName 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: hostingPlanName_var
  location: location
  sku: {
    tier: sku
    name: skuCode
  }
  kind: 'linux'
  properties: {
    name: hostingPlanName_var
    workerSizeId: workerSize
    reserved: true
    numberOfWorkers: '1'
  }
}

resource appInsights 'microsoft.insights/components@2020-02-02-preview' = {
  name: appInsights_var
  location: location
  properties: {
    ApplicationId: webAppName
    Application_Type: 'web'
  }
}