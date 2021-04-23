@description('Which Pricing tier our App Service Plan to')
param skuName string = 'S1'

@description('How many instances of our app service will be scaled out to')
param skuCapacity int = 1

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name that will be used to build associated artifacts')
param appName string = uniqueString(resourceGroup().id)

var appServicePlanName_var = toLower('asp-${appName}')
var webSiteName_var = toLower('wapp-${appName}')
var appInsightName_var = toLower('appi-${appName}')
var logAnalyticsName_var = toLower('la-${appName}')

resource appServicePlanName 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName_var
  location: location
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  tags: {
    displayName: 'HostingPlan'
    ProjectName: appName
  }
  properties: {
    name: appServicePlanName_var
  }
}

resource webSiteName 'Microsoft.Web/sites@2020-06-01' = {
  name: webSiteName_var
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    displayName: 'Website'
    ProjectName: appName
  }
  properties: {
    serverFarmId: appServicePlanName.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
    }
  }
  dependsOn: [
    logAnalyticsName
  ]
}

resource webSiteName_appsettings 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: webSiteName
  name: 'appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsightName.properties.InstrumentationKey
  }
  dependsOn: [
    webSiteName_Microsoft_ApplicationInsights_AzureWebSites
  ]
}

resource webSiteName_Microsoft_ApplicationInsights_AzureWebSites 'Microsoft.Web/sites/siteextensions@2020-06-01' = {
  parent: webSiteName
  name: 'Microsoft.ApplicationInsights.AzureWebSites'
  dependsOn: [
    appInsightName
  ]
}

resource webSiteName_logs 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: webSiteName
  name: 'logs'
  properties: {
    applicationLogs: {
      fileSystem: {
        level: 'Warning'
      }
    }
    httpLogs: {
      fileSystem: {
        retentionInMb: 40
        enabled: true
      }
    }
    failedRequestsTracing: {
      enabled: true
    }
    detailedErrorMessages: {
      enabled: true
    }
  }
}

resource appInsightName 'microsoft.insights/components@2020-02-02-preview' = {
  name: appInsightName_var
  location: location
  kind: 'string'
  tags: {
    displayName: 'AppInsight'
    ProjectName: appName
  }
  properties: {
    Application_Type: 'web'
    ApplicationId: appInsightName_var
    WorkspaceResourceId: logAnalyticsName.id
  }
  dependsOn: [
    webSiteName
  ]
}

resource logAnalyticsName 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsName_var
  location: location
  tags: {
    displayName: 'Log Analytics'
    ProjectName: appName
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 120
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}