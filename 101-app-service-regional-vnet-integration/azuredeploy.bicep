@description('The name of the app to create.')
param appName string = uniqueString(resourceGroup().id)

@description('The name of the app service plan to create.')
param appServicePlanName string = uniqueString(subscription().subscriptionId)

@description('The location in which all resources should be deployed.')
param location string = resourceGroup().location

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
    vnetName
  ]
}

resource appName_virtualNetwork 'Microsoft.Web/sites/config@2019-08-01' = {
  parent: appName_resource
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetName)
    swiftSupported: true
  }
}