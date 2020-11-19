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

var hostingPlanName = '${uniqueString(resourceGroup().id)}hostingplan'
var siteName = '${uniqueString(resourceGroup().id)}website'

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2020-06-01' = {
  sku: {
    name: sku
    capacity: 1
  }
  name: hostingPlanName
  location: location
  properties: {}
}

resource siteName_resource 'Microsoft.Web/sites@2020-06-01' = {
  name: siteName
  location: location
  properties: {
    name: siteName
    serverFarmId: hostingPlanName
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
    hostingPlanName_resource
  ]
}

resource siteName_web 'Microsoft.Web/sites/sourcecontrols@2020-06-01' = {
  name: '${siteName}/web'
  properties: {
    RepoUrl: repoUrl
    branch: branch
    IsManualIntegration: true
  }
  dependsOn: [
    siteName_resource
  ]
}

resource Microsoft_Web_sites_config_siteName_web 'Microsoft.Web/sites/config@2020-06-01' = {
  name: '${siteName}/web'
  properties: {
    phpVersion: '7.0'
  }
  dependsOn: [
    siteName_resource
  ]
}