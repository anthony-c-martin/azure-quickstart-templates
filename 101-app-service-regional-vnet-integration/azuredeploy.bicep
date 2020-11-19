param appName string {
  metadata: {
    description: 'The name of the app to create.'
  }
  default: uniqueString(resourceGroup().id)
}
param appServicePlanName string {
  metadata: {
    description: 'The name of the app service plan to create.'
  }
  default: uniqueString(subscription().subscriptionId)
}
param location string {
  metadata: {
    description: 'The location in which all resources should be deployed.'
  }
  default: resourceGroup().location
}

var vnetName = 'vnet'
var vnetAddressPrefix = '10.0.0.0/16'
var subnetName = 'myappservice'
var subnetAddressPrefix = '10.0.0.0/24'
var appServicePlanSku = 'S1'

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
}

resource appServicePlanName_resource 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSku
  }
  kind: 'app'
}

resource appName_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: appName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlanName_resource.id
  }
  dependsOn: [
    appServicePlanName_resource
    vnetName_resource
  ]
}

resource appName_virtualNetwork 'Microsoft.Web/sites/config@2019-08-01' = {
  name: '${appName}/virtualNetwork'
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
    swiftSupported: true
  }
  dependsOn: [
    appName_resource
  ]
}