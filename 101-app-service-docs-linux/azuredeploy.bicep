param webAppName string {
  minLength: 2
  metadata: {
    description: 'Web app name.'
  }
  default: 'webApp-${uniqueString(resourceGroup().id)}'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param sku string {
  metadata: {
    description: 'The SKU of App Service Plan.'
  }
  default: 'F1'
}
param linuxFxVersion string {
  metadata: {
    description: 'The Runtime stack of current web app'
  }
  default: 'DOTNETCORE|3.0'
}
param repoUrl string {
  metadata: {
    description: 'Optional Git Repo URL'
  }
  default: ' '
}

var appServicePlanPortalName = 'AppServicePlan-${webAppName}'

resource appServicePlanPortalName_resource 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanPortalName
  location: location
  sku: {
    name: sku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webAppName_resource 'Microsoft.Web/sites@2020-06-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlanPortalName_resource.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
    }
    resources: [
      {
        condition: contains(repoUrl, 'http')
        type: 'sourcecontrols'
        apiVersion: '2020-06-01'
        name: 'web'
        location: location
        dependsOn: [
          webAppName_resource.id
        ]
        properties: {
          repoUrl: repoUrl
          branch: 'master'
          isManualIntegration: true
        }
      }
    ]
  }
  dependsOn: [
    appServicePlanPortalName_resource
  ]
}