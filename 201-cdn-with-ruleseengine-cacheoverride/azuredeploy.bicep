param profileName string {
  metadata: {
    description: 'Name of the CDN Profile'
  }
}
param endpointName string {
  metadata: {
    description: 'Name of the CDN Endpoint'
  }
}
param originUrl string {
  metadata: {
    description: 'Url of the origin'
  }
}
param CDNSku string {
  allowed: [
    'Standard_Akamai'
    'Standard_Verizon'
    'Premium_Verizon'
    'Standard_Microsoft'
  ]
  metadata: {
    description: 'CDN SKU names'
  }
  default: 'Standard_Microsoft'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource profileName_res 'Microsoft.Cdn/profiles@2019-04-15' = {
  name: profileName
  location: location
  sku: {
    name: CDNSku
  }
}

resource profileName_endpointName 'Microsoft.Cdn/profiles/endpoints@2019-04-15' = {
  location: location
  name: '${profileName}/${endpointName}'
  properties: {
    originHostHeader: originUrl
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
          hostName: originUrl
        }
      }
    ]
    deliveryPolicy: {
      description: 'Path based Cache Override'
      rules: [
        {
          name: 'Pathmatchcondition'
          order: '1'
          conditions: [
            {
              name: 'UrlPath'
              parameters: {
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleUrlPathMatchConditionParameters'
                operator: 'BeginsWith'
                matchValues: [
                  '/images/'
                ]
              }
            }
          ]
          actions: [
            {
              name: 'CacheExpiration'
              parameters: {
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleCacheExpirationActionParameters'
                cacheBehavior: 'Override'
                cacheType: 'All'
                cacheDuration: '00:00:30'
              }
            }
          ]
        }
      ]
    }
  }
}