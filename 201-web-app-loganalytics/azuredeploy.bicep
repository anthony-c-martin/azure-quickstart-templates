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

var appServicePlanName_var = toLower('asp-${appName}')
var webSiteName_var = toLower('wapp-${appName}')
var appInsightName_var = toLower('appi-${appName}')
var logAnalyticsName_var = toLower('la-${appName}')

resource appServicePlanName 'Microsoft.Web/serverfarms@2019-08-01' = {
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

resource webSiteName 'Microsoft.Web/sites@2019-08-01' = {
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
}

resource webSiteName_appsettings 'Microsoft.Web/sites/config@2019-08-01' = {
  name: '${webSiteName_var}/appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsightName.properties.InstrumentationKey
  }
  dependsOn: [
    appInsightName
  ]
}

resource webSiteName_Microsoft_ApplicationInsights_AzureWebSites 'Microsoft.Web/sites/siteextensions@2019-08-01' = {
  name: '${webSiteName_var}/Microsoft.ApplicationInsights.AzureWebSites'
}

resource webSiteName_logs 'Microsoft.Web/sites/config@2019-08-01' = {
  name: '${webSiteName_var}/logs'
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
}

resource logAnalyticsName 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: logAnalyticsName_var
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