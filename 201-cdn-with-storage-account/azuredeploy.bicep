param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var storageAccountName = 'storage${uniqueString(resourceGroup().id)}'
var endpointName = 'endpoint-${uniqueString(resourceGroup().id)}'
var profileName = 'CdnProfile1'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: storageAccountName
  location: location
  tags: {
    displayName: storageAccountName
  }
  kind: 'Storage'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {}
}

resource profileName_resource 'Microsoft.Cdn/profiles@2016-04-02' = {
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

resource profileName_endpointName 'Microsoft.Cdn/profiles/endpoints@2016-04-02' = {
  name: '${profileName}/${endpointName}'
  location: location
  tags: {
    displayName: endpointName
  }
  properties: {
    originHostHeader: replace(replace(reference(storageAccountName).primaryEndpoints.blob, 'https://', ''), '/', '')
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
          hostName: replace(replace(reference(storageAccountName).primaryEndpoints.blob, 'https://', ''), '/', '')
        }
      }
    ]
  }
  dependsOn: [
    profileName_resource
    storageAccountName_resource
  ]
}

output hostName string = reference(endpointName).hostName
output originHostHeader string = reference(endpointName).originHostHeader