@minLength(2)
@description('Web app name.')
param webAppName string = 'webApp-${uniqueString(resourceGroup().id)}'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The SKU of App Service Plan.')
param sku string = 'F1'

@description('The Runtime stack of current web app')
param linuxFxVersion string = 'DOTNETCORE|3.0'

@description('Optional Git Repo URL')
param repoUrl string = ' '

var appServicePlanPortalName_var = 'AppServicePlan-${webAppName}'

resource appServicePlanPortalName 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanPortalName_var
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
    serverFarmId: appServicePlanPortalName.id
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
}