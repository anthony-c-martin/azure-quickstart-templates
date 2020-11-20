param sku string {
  allowed: [
    'F1'
    'B1'
    'S1'
  ]
  metadata: {
    description: 'wordpress site name'
  }
  default: 'F1'
}
param repoUrl string {
  metadata: {
    description: 'GitHub repo to deploy to App Service'
  }
  default: 'https://github.com/azureappserviceoss/wordpress-azure'
}
param branch string {
  metadata: {
    description: 'GitHub repo branch to deploy to App Service'
  }
  default: 'master'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var hostingPlanName_var = '${uniqueString(resourceGroup().id)}hostingplan'
var siteName_var = '${uniqueString(resourceGroup().id)}website'

resource hostingPlanName 'Microsoft.Web/serverfarms@2020-06-01' = {
  sku: {
    name: sku
    capacity: 1
  }
  name: hostingPlanName_var
  location: location
  properties: {}
}

resource siteName 'Microsoft.Web/sites@2020-06-01' = {
  name: siteName_var
  location: location
  properties: {
    name: siteName_var
    serverFarmId: hostingPlanName_var
    siteConfig: {
      localMySqlEnabled: true
      appSettings: [
        {
          name: 'WEBSITE_MYSQL_ENABLED'
          value: '1'
        }
        {
          name: 'WEBSITE_MYSQL_GENERAL_LOG'
          value: '0'
        }
        {
          name: 'WEBSITE_MYSQL_SLOW_QUERY_LOG'
          value: '0'
        }
        {
          name: 'WEBSITE_MYSQL_ARGUMENTS'
          value: '--max_allowed_packet=16M'
        }
      ]
    }
  }
  dependsOn: [
    hostingPlanName
  ]
}

resource siteName_web 'Microsoft.Web/sites/sourcecontrols@2020-06-01' = {
  name: '${siteName_var}/web'
  properties: {
    repoUrl: repoUrl
    branch: branch
    isManualIntegration: true
  }
  dependsOn: [
    siteName
  ]
}

resource Microsoft_Web_sites_config_siteName_web 'Microsoft.Web/sites/config@2020-06-01' = {
  name: '${siteName_var}/web'
  properties: {
    phpVersion: '7.0'
  }
  dependsOn: [
    siteName
  ]
}