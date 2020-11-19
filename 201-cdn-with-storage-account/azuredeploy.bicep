param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var storageAccountName_var = 'storage${uniqueString(resourceGroup().id)}'
var endpointName = 'endpoint-${uniqueString(resourceGroup().id)}'
var profileName_var = 'CdnProfile1'

resource storageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: storageAccountName_var
  location: location
  tags: {
    displayName: storageAccountName_var
  }
  kind: 'Storage'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {}
}

resource profileName 'Microsoft.Cdn/profiles@2016-04-02' = {
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

resource profileName_endpointName 'Microsoft.Cdn/profiles/endpoints@2016-04-02' = {
  name: '${profileName_var}/${endpointName}'
  location: location
  tags: {
    displayName: endpointName
  }
  properties: {
    originHostHeader: replace(replace(reference(storageAccountName_var).primaryEndpoints.blob, 'https://', ''), '/', '')
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
          hostName: replace(replace(reference(storageAccountName_var).primaryEndpoints.blob, 'https://', ''), '/', '')
        }
      }
    ]
  }
  dependsOn: [
    profileName
    storageAccountName
  ]
}

output hostName string = reference(endpointName).hostName
output originHostHeader string = reference(endpointName).originHostHeader