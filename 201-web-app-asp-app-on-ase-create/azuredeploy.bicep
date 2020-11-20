param siteName string {
  metadata: {
    description: 'The name of the web app that you wish to create.'
  }
}
param appServicePlanName string {
  metadata: {
    description: 'The name of the App Service plan to use for hosting the web app.'
  }
}
param appServiceEnvironmentName string {
  metadata: {
    description: 'The name of the App Service Environment where the app service plan will be created.'
  }
}
param existingAseLocation string {
  metadata: {
    description: 'Set this to the same location as the App Service Environment'
  }
}
param workerPool string {
  allowed: [
    '1'
    '2'
    '3'
  ]
  metadata: {
    description: 'Defines which worker pool\'s (WP1, WP2 or WP3) resources will be used for the app service plan.'
  }
  default: 0
}
param numberOfWorkersFromWorkerPool int {
  metadata: {
    description: 'Defines the number of workers from the worker pool that will be used by the app service plan.'
  }
  default: 1
}

resource appServicePlanName_res 'Microsoft.Web/serverfarms@2015-08-01' = {
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

resource siteName_res 'Microsoft.Web/sites@2015-08-01' = {
  name: siteName
  location: existingAseLocation
  properties: {
    name: siteName
    serverFarmId: appServicePlanName_res.id
    hostingEnvironmentProfile: {
      id: resourceId('Microsoft.Web/hostingEnvironments', appServiceEnvironmentName)
    }
  }
}