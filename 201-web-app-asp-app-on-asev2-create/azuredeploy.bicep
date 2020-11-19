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
param location string {
  metadata: {
    description: 'Set this to the same location as the app service environment'
  }
  default: resourceGroup().location
}
param pricingTier string {
  allowed: [
    '1'
    '2'
    '3'
  ]
  metadata: {
    description: 'Defines pricing tier for workers: 1 = Isolated 1, 2 = Isolated 2, 3 = Isolated 3.'
  }
  default: '1'
}
param capacity int {
  metadata: {
    description: 'Defines the number of instances that will be allocated to the app service plan.'
  }
  default: 1
}

resource appServicePlanName_res 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  properties: {
    name: appServicePlanName
    hostingEnvironmentProfile: {
      id: resourceId('Microsoft.Web/hostingEnvironments', appServiceEnvironmentName)
    }
  }
  sku: {
    name: 'I${pricingTier}'
    tier: 'Isolated'
    size: 'I${pricingTier}'
    family: 'I'
    capacity: capacity
  }
}

resource siteName_res 'Microsoft.Web/sites@2020-06-01' = {
  name: siteName
  location: location
  properties: {
    name: siteName
    serverFarmId: appServicePlanName_res.id
    hostingEnvironmentProfile: {
      id: resourceId('Microsoft.Web/hostingEnvironments', appServiceEnvironmentName)
    }
  }
}