@description('The name of the web app that you wish to create.')
param siteName string

@description('The name of the App Service plan to use for hosting the web app.')
param appServicePlanName string

@description('The name of the App Service Environment where the app service plan will be created.')
param appServiceEnvironmentName string

@description('Set this to the same location as the app service environment')
param location string = resourceGroup().location

@allowed([
  '1'
  '2'
  '3'
])
@description('Defines pricing tier for workers: 1 = Isolated 1, 2 = Isolated 2, 3 = Isolated 3.')
param pricingTier string = '1'

@description('Defines the number of instances that will be allocated to the app service plan.')
param capacity int = 1

resource appServicePlanName_resource 'Microsoft.Web/serverfarms@2020-06-01' = {
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

resource siteName_resource 'Microsoft.Web/sites@2020-06-01' = {
  name: siteName
  location: location
  properties: {
    name: siteName
    serverFarmId: appServicePlanName_resource.id
    hostingEnvironmentProfile: {
      id: resourceId('Microsoft.Web/hostingEnvironments', appServiceEnvironmentName)
    }
  }
}