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

var vnetName_var = 'vnet'
var vnetAddressPrefix = '10.0.0.0/16'
var subnetName = 'myappservice'
var subnetAddressPrefix = '10.0.0.0/24'
var appServicePlanSku = 'S1'

resource vnetName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnetName_var
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

resource appServicePlanName_res 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSku
  }
  kind: 'app'
}

resource appName_res 'Microsoft.Web/sites@2019-08-01' = {
  name: appName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlanName_res.id
  }
}

resource appName_virtualNetwork 'Microsoft.Web/sites/config@2019-08-01' = {
  name: '${appName}/virtualNetwork'
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetName)
    swiftSupported: true
  }
}