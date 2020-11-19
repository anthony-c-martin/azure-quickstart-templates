param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var endpointName = 'endpoint-${uniqueString(resourceGroup().id)}'
var serverFarmName = 'ServerFarm1'
var profileName = 'CdnProfile1'
var webAppName = 'web-${uniqueString(resourceGroup().id)}'

resource serverFarmName_resource 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: serverFarmName
  location: location
  tags: {
    displayName: serverFarmName
  }
  sku: {
    name: 'F1'
    capacity: 1
  }
  properties: {
    name: serverFarmName
  }
}

resource webAppName_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: webAppName
  location: location
  tags: {
    displayName: webAppName
  }
  properties: {
    name: webAppName
    serverFarmId: serverFarmName_resource.id
  }
  dependsOn: [
    serverFarmName_resource
  ]
}

resource profileName_resource 'Microsoft.Cdn/profiles@2020-04-15' = {
  name: profileName
  location: location
  tags: {
    displayName: profileName
  }
  sku: {
    name: 'Standard_Akamai'
  }
  properties: {}
}

resource profileName_endpointName 'Microsoft.Cdn/profiles/endpoints@2020-04-15' = {
  name: '${profileName}/${endpointName}'
  location: location
  tags: {
    displayName: endpointName
  }
  properties: {
    originHostHeader: reference(webAppName).hostNames[0]
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
          hostName: reference(webAppName).hostNames[0]
        }
      }
    ]
  }
  dependsOn: [
    profileName_resource
    webAppName_resource
  ]
}

output hostName string = reference(endpointName).hostName
output originHostHeader string = reference(endpointName).originHostHeader