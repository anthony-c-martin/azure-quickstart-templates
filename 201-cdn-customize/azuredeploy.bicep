param profileName string {
  metadata: {
    description: 'Name of the CDN Profile.'
  }
}
param sku string {
  allowed: [
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'Pricing tier of the CDN Profile.'
  }
  default: 'Standard'
}
param endpointName string {
  metadata: {
    description: 'Name of the CDN Endpoint.'
  }
}
param originHostHeader string {
  metadata: {
    description: 'Host header that CDN edge node going to send to origin.'
  }
}
param isHttpAllowed bool {
  metadata: {
    description: 'Whether the HTTP traffic is allowed.'
  }
  default: true
}
param isHttpsAllowed bool {
  metadata: {
    description: 'Whether the HTTPS traffic is allowed.'
  }
  default: true
}
param queryStringCachingBehavior string {
  allowed: [
    'IgnoreQueryString'
    'BypassCaching'
    'UseQueryString'
  ]
  metadata: {
    description: 'Query string caching behavior.'
  }
  default: 'IgnoreQueryString'
}
param contentTypesToCompress array {
  metadata: {
    description: 'Content type that is compressed.'
  }
  default: [
    'text/plain'
    'text/html'
    'text/css'
    'application/x-javascript'
    'text/javascript'
  ]
}
param isCompressionEnabled bool {
  metadata: {
    description: 'Whether the compression is enabled'
  }
  default: true
}
param originUrl string {
  metadata: {
    description: 'Url of the origin'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var cdnApiVersion = '2015-06-01'

resource profileName_resource 'Microsoft.Cdn/profiles@2015-06-01' = {
  name: profileName
  location: location
  properties: {
    sku: {
      name: sku
    }
  }
}

resource profileName_endpointName 'Microsoft.Cdn/profiles/endpoints@2015-06-01' = {
  location: location
  name: '${profileName}/${endpointName}'
  properties: {
    originHostHeader: originUrl
    isHttpAllowed: isHttpAllowed
    isHttpsAllowed: isHttpsAllowed
    queryStringCachingBehavior: queryStringCachingBehavior
    contentTypesToCompress: contentTypesToCompress
    isCompressionEnabled: isCompressionEnabled
    origins: [
      {
        name: 'origin1'
        properties: {
          hostName: originUrl
        }
      }
    ]
  }
  dependsOn: [
    profileName_resource
  ]
}