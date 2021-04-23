@description('Name of the CDN Profile.')
param profileName string

@allowed([
  'Standard'
  'Premium'
])
@description('Pricing tier of the CDN Profile.')
param sku string = 'Standard'

@description('Name of the CDN Endpoint.')
param endpointName string

@description('Host header that CDN edge node going to send to origin.')
param originHostHeader string

@description('Whether the HTTP traffic is allowed.')
param isHttpAllowed bool = true

@description('Whether the HTTPS traffic is allowed.')
param isHttpsAllowed bool = true

@allowed([
  'IgnoreQueryString'
  'BypassCaching'
  'UseQueryString'
])
@description('Query string caching behavior.')
param queryStringCachingBehavior string = 'IgnoreQueryString'

@description('Content type that is compressed.')
param contentTypesToCompress array = [
  'text/plain'
  'text/html'
  'text/css'
  'application/x-javascript'
  'text/javascript'
]

@description('Whether the compression is enabled')
param isCompressionEnabled bool = true

@description('Url of the origin')
param originUrl string

@description('Location for all resources.')
param location string = resourceGroup().location

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
  parent: profileName_resource
  location: location
  name: '${endpointName}'
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
}