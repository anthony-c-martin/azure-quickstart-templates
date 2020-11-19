param webAppName string {
  minLength: 2
  metadata: {
    description: 'Base name of the resource such as web app name and app service plan '
  }
  default: 'AzureLinuxApp'
}
param sku string {
  metadata: {
    description: 'The SKU of App Service Plan '
  }
  default: 'S1'
}
param linuxFxVersion string {
  metadata: {
    description: 'The Runtime stack of current web app'
  }
  default: 'php|7.0'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var webAppPortalName = '${webAppName}-webapp'
var appServicePlanName = 'AppServicePlan-${webAppName}'

resource appServicePlanName_resource 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: sku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webAppPortalName_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: webAppPortalName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlanName_resource.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
    }
  }
  dependsOn: [
    appServicePlanName_resource
  ]
}