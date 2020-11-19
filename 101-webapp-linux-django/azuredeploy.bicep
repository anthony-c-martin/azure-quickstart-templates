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
var appInsights = '${webAppName}-insights'
var hostingPlanName = 'hpn-${resourceGroup().name}'

resource webAppName_resource 'Microsoft.Web/sites@2020-06-01' = {
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
          value: appInsights_resource.properties.InstrumentationKey
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
    serverFarmId: hostingPlanName_resource.id
  }
  dependsOn: [
    hostingPlanName_resource
    appInsights_resource
  ]
}

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: hostingPlanName
  location: location
  sku: {
    Tier: sku
    Name: skuCode
  }
  kind: 'linux'
  properties: {
    name: hostingPlanName
    workerSizeId: workerSize
    reserved: true
    numberOfWorkers: '1'
  }
}

resource appInsights_resource 'microsoft.insights/components@2020-02-02-preview' = {
  name: appInsights
  location: location
  properties: {
    ApplicationId: webAppName
    Application_Type: 'web'
  }
}