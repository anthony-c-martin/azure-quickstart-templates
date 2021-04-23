@description('That name is the name of our application. It has to be unique.Type a name followed by your resource group name. (<name>-<resourceGroupName>)')
param webAppName string = 'Node-${uniqueString(resourceGroup().name, utcNow('F'))}'

@description('Location for all resources.')
param location string = resourceGroup().location

var alwaysOn = false
var sku = 'Free'
var skuCode = 'F1'
var workerSize = '0'
var workerSizeId = '0'
var numberOfWorkers = '1'
var linuxFxVersion = 'NODE|lts'
var hostingPlanName_var = 'hpn-${resourceGroup().name}'

resource webAppName_resource 'Microsoft.Web/sites@2020-06-01' = {
  name: webAppName
  location: location
  properties: {
    name: webAppName
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      alwaysOn: alwaysOn
    }
    serverFarmId: hostingPlanName.id
    clientAffinityEnabled: false
  }
}

resource hostingPlanName 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: hostingPlanName_var
  location: location
  kind: 'linux'
  sku: {
    tier: sku
    name: skuCode
  }
  properties: {
    name: hostingPlanName_var
    workerSize: workerSize
    workerSizeId: workerSizeId
    numberOfWorkers: numberOfWorkers
    reserved: true
  }
}