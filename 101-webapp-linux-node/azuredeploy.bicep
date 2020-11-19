param webAppName string {
  metadata: {
    description: 'That name is the name of our application. It has to be unique.Type a name followed by your resource group name. (<name>-<resourceGroupName>)'
  }
  default: 'Node-${uniqueString(resourceGroup().name, utcNow('F'))}'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var alwaysOn = false
var sku = 'Free'
var skuCode = 'F1'
var workerSize = '0'
var workerSizeId = '0'
var numberOfWorkers = '1'
var linuxFxVersion = 'NODE|lts'
var hostingPlanName = 'hpn-${resourceGroup().name}'

resource webAppName_resource 'Microsoft.Web/sites@2020-06-01' = {
  name: webAppName
  location: location
  properties: {
    name: webAppName
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      alwaysOn: alwaysOn
    }
    serverFarmId: hostingPlanName_resource.id
    clientAffinityEnabled: false
  }
  dependsOn: [
    hostingPlanName_resource
  ]
}

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: hostingPlanName
  location: location
  kind: 'linux'
  sku: {
    Tier: sku
    Name: skuCode
  }
  properties: {
    name: hostingPlanName
    workerSize: workerSize
    workerSizeId: workerSizeId
    numberOfWorkers: numberOfWorkers
    reserved: true
  }
}