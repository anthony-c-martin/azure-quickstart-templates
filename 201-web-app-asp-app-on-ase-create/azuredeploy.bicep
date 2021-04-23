@description('The name of the web app that you wish to create.')
param siteName string

@description('The name of the App Service plan to use for hosting the web app.')
param appServicePlanName string

@description('The name of the App Service Environment where the app service plan will be created.')
param appServiceEnvironmentName string

@description('Set this to the same location as the App Service Environment')
param existingAseLocation string

@allowed([
  '1'
  '2'
  '3'
])
@description('Defines which worker pool\'s (WP1, WP2 or WP3) resources will be used for the app service plan.')
param workerPool string = 0

@description('Defines the number of workers from the worker pool that will be used by the app service plan.')
param numberOfWorkersFromWorkerPool int = 1

resource appServicePlanName_resource 'Microsoft.Web/serverfarms@2015-08-01' = {
  name: appServicePlanName
  location: existingAseLocation
  properties: {
    name: appServicePlanName
    hostingEnvironmentProfile: {
      id: resourceId('Microsoft.Web/hostingEnvironments', appServiceEnvironmentName)
    }
  }
  sku: {
    name: 'P${workerPool}'
    tier: 'Premium'
    size: 'P${workerPool}'
    family: 'P'
    capacity: numberOfWorkersFromWorkerPool
  }
}

resource siteName_resource 'Microsoft.Web/sites@2015-08-01' = {
  name: siteName
  location: existingAseLocation
  properties: {
    name: siteName
    serverFarmId: appServicePlanName_resource.id
    hostingEnvironmentProfile: {
      id: resourceId('Microsoft.Web/hostingEnvironments', appServiceEnvironmentName)
    }
  }
}