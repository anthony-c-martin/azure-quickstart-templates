@description('Location for all resources.')
param location string = resourceGroup().location

var endpointName = 'endpoint-${uniqueString(resourceGroup().id)}'
var serverFarmName_var = 'ServerFarm1'
var profileName_var = 'CdnProfile1'
var webAppName_var = 'web-${uniqueString(resourceGroup().id)}'

resource serverFarmName 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: serverFarmName_var
  location: location
  tags: {
    displayName: serverFarmName_var
  }
  sku: {
    name: 'F1'
    capacity: 1
  }
  properties: {
    name: serverFarmName_var
  }
}

resource webAppName 'Microsoft.Web/sites@2019-08-01' = {
  name: webAppName_var
  location: location
  tags: {
    displayName: webAppName_var
  }
  properties: {
    name: webAppName_var
    serverFarmId: serverFarmName.id
  }
}

resource profileName 'Microsoft.Cdn/profiles@2020-04-15' = {
  name: profileName_var
  location: location
  tags: {
    displayName: profileName_var
  }
  sku: {
    name: 'Standard_Akamai'
  }
  properties: {}
}

resource profileName_endpointName 'Microsoft.Cdn/profiles/endpoints@2020-04-15' = {
  parent: profileName
  name: '${endpointName}'
  location: location
  tags: {
    displayName: endpointName
  }
  properties: {
    originHostHeader: reference(webAppName_var).hostNames[0]
    isHttpAllowed: true
    isHttpsAllowed: true
    queryStringCachingBehavior: 'IgnoreQueryString'
    contentTypesToCompress: [
      'text/plain'
      'text/html'
      'text/css'
      'application/x-javascript'
      'text/javascript'
    ]
    isCompressionEnabled: true
    origins: [
      {
        name: 'origin1'
        properties: {
          hostName: reference(webAppName_var).hostNames[0]
        }
      }
    ]
  }
  dependsOn: [
    webAppName
  ]
}

output hostName string = reference(endpointName).hostName
output originHostHeader string = reference(endpointName).originHostHeader