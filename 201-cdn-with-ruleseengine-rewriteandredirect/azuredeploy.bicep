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
      description: 'Rewrite and Redirect'
      rules: [
        {
          name: 'PathRewriteBasedOnDeviceMatchCondition'
          order: '1'
          conditions: [
            {
              name: 'IsDevice'
              parameters: {
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleIsDeviceConditionParameters'
                operator: 'Equal'
                matchValues: [
                  'Mobile'
                ]
              }
            }
          ]
          actions: [
            {
              name: 'UrlRewrite'
              parameters: {
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleUrlRewriteActionParameters'
                sourcePattern: '/standard'
                destination: '/mobile'
              }
            }
          ]
        }
        {
          name: 'HttpVersionBasedRedirect'
          order: '2'
          conditions: [
            {
              name: 'RequestScheme'
              parameters: {
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleRequestSchemeConditionParameters'
                operator: 'Equal'
                matchValues: [
                  'HTTP'
                ]
              }
            }
          ]
          actions: [
            {
              name: 'UrlRedirect'
              parameters: {
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleUrlRedirectActionParameters'
                redirectType: 'Found'
                destinationProtocol: 'Https'
              }
            }
          ]
        }
      ]
    }
  }
}