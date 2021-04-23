@allowed([
  'F1'
  'D1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P3'
  'P4'
])
@description('Describes plan\'s pricing tier and instance size. Check details at https://azure.microsoft.com/en-us/pricing/details/app-service/')
param skuName string = 'F1'

@minValue(1)
@description('Describes plan\'s instance count')
param skuCapacity int = 1

@allowed([
  'Basic'
  'Standard'
])
@description('The pricing tier of the new Azure Redis Cache.')
param cacheSKUName string = 'Basic'

@allowed([
  'C'
])
@description('The family for the sku.')
param cacheSKUFamily string = 'C'

@allowed([
  0
  1
  2
  3
  4
  5
  6
])
@description('The size of the new Azure Redis Cache instance. ')
param cacheSKUCapacity int = 0

@description('Location for all resources.')
param location string = resourceGroup().location

var hostingPlanName_var = 'hostingplan${uniqueString(resourceGroup().id)}'
var webSiteName_var = 'webSite${uniqueString(resourceGroup().id)}'
var cacheName_var = 'cache${uniqueString(resourceGroup().id)}'

resource hostingPlanName 'Microsoft.Web/serverfarms@2015-08-01' = {
  name: hostingPlanName_var
  location: location
  tags: {
    displayName: 'HostingPlan'
  }
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {
    name: hostingPlanName_var
  }
}

resource webSiteName 'Microsoft.Web/sites@2015-08-01' = {
  name: webSiteName_var
  location: location
  tags: {
    'hidden-related:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName_var}': 'empty'
    displayName: 'Website'
  }
  properties: {
    name: webSiteName_var
    serverFarmId: hostingPlanName.id
  }
  dependsOn: [
    cacheName
  ]
}

resource webSiteName_appsettings 'Microsoft.Web/sites/config@2015-08-01' = {
  parent: webSiteName
  name: 'appsettings'
  properties: {
    CacheConnection: '${cacheName_var}.redis.cache.windows.net,abortConnect=false,ssl=true,password=${listKeys(cacheName.id, '2015-08-01').primaryKey}'
  }
}

resource cacheName 'Microsoft.Cache/Redis@2015-08-01' = {
  name: cacheName_var
  location: location
  tags: {
    displayName: 'cache'
  }
  properties: {
    sku: {
      name: cacheSKUName
      family: cacheSKUFamily
      capacity: cacheSKUCapacity
    }
  }
  dependsOn: []
}