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

resource profileName_resource 'Microsoft.Cdn/profiles@2019-04-15' = {
  name: profileName
  location: location
  sku: {
    name: CDNSku
  }
}

resource profileName_endpointName 'Microsoft.Cdn/profiles/endpoints@2019-04-15' = {
  name: '${profileName}/${endpointName}'
  location: location
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
      description: 'Add Response Headers'
      rules: [
        {
          name: 'GeoMatchCondition'
          order: '1'
          conditions: [
            {
              name: 'RemoteAddress'
              parameters: {
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleRemoteAddressConditionParameters'
                operator: 'GeoMatch'
                matchValues: [
                  'US'
                ]
              }
            }
          ]
          actions: [
            {
              name: 'ModifyResponseHeader'
              parameters: {
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleHeaderActionParameters'
                headerAction: 'Overwrite'
                headerName: 'X-CLIENT-COUNTRY'
                value: 'US'
              }
            }
          ]
        }
        {
          name: 'IPv4Match'
          order: '2'
          conditions: [
            {
              name: 'RemoteAddress'
              parameters: {
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleRemoteAddressConditionParameters'
                operator: 'IPMatch'
                matchValues: [
                  '0.0.0.0/0'
                ]
              }
            }
          ]
          actions: [
            {
              name: 'ModifyResponseHeader'
              parameters: {
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleHeaderActionParameters'
                headerAction: 'Overwrite'
                headerName: 'X-CLIENT-IP-VERSION'
                value: 'IPv4'
              }
            }
          ]
        }
        {
          name: 'IPv6Match'
          order: '3'
          conditions: [
            {
              name: 'RemoteAddress'
              parameters: {
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleRemoteAddressConditionParameters'
                operator: 'IPMatch'
                matchValues: [
                  '::0/0'
                ]
              }
            }
          ]
          actions: [
            {
              name: 'ModifyResponseHeader'
              parameters: {
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleHeaderActionParameters'
                headerAction: 'Overwrite'
                headerName: 'X-CLIENT-IP-VERSION'
                value: 'IPv6'
              }
            }
          ]
        }
      ]
    }
  }
  dependsOn: [
    profileName_resource
  ]
}