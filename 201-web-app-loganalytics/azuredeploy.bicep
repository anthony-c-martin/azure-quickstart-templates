param skuName string {
  metadata: {
    description: 'Which Pricing tier our App Service Plan to'
  }
  default: 'S1'
}
param skuCapacity int {
  metadata: {
    description: 'How many instances of our app service will be scaled out to'
  }
  default: 1
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param appName string = uniqueString(resourceGroup().id)

var appServicePlanName = toLower('asp-${appName}')
var webSiteName = toLower('wapp-${appName}')
var appInsightName = toLower('appi-${appName}')
var logAnalyticsName = toLower('la-${appName}')

resource appServicePlanName_resource 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: appServicePlanName
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
    name: appServicePlanName
  }
}

resource webSiteName_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: webSiteName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    displayName: 'Website'
    ProjectName: appName
  }
  properties: {
    serverFarmId: appServicePlanName_resource.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
    }
  }
  dependsOn: [
    appServicePlanName_resource
    logAnalyticsName_resource
  ]
}

resource webSiteName_appsettings 'Microsoft.Web/sites/config@2019-08-01' = {
  name: '${webSiteName}/appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsightName_resource.properties.InstrumentationKey
  }
  dependsOn: [
    webSiteName_resource
    webSiteName_Microsoft_ApplicationInsights_AzureWebSites
    appInsightName_resource
  ]
}

resource webSiteName_Microsoft_ApplicationInsights_AzureWebSites 'Microsoft.Web/sites/siteextensions@2019-08-01' = {
  name: '${webSiteName}/Microsoft.ApplicationInsights.AzureWebSites'
  dependsOn: [
    webSiteName_resource
    appInsightName_resource
  ]
}

resource webSiteName_logs 'Microsoft.Web/sites/config@2019-08-01' = {
  name: '${webSiteName}/logs'
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
  dependsOn: [
    webSiteName_resource
  ]
}

resource appInsightName_resource 'microsoft.insights/components@2020-02-02-preview' = {
  name: appInsightName
  location: location
  kind: 'string'
  tags: {
    displayName: 'AppInsight'
    ProjectName: appName
  }
  properties: {
    Application_Type: 'web'
    applicationId: appInsightName
    WorkspaceResourceId: logAnalyticsName_resource.id
  }
  dependsOn: [
    webSiteName_resource
    logAnalyticsName_resource
  ]
}

resource logAnalyticsName_resource 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: logAnalyticsName
  location: location
  tags: {
    displayName: 'Log Analytics'
    ProjectName: appName
  }
  properties: {
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: 120
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}