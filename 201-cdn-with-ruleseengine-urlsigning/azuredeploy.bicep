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
param urlSigningKeysSubId string {
  metadata: {
    description: 'Subscription Id of UrlSigning Keys'
  }
}
param urlSigningKeysResourceGroup string {
  metadata: {
    description: 'Resourcegroup of UrlSigning Keys'
  }
}
param urlSigningKeysVaultName string {
  metadata: {
    description: 'Keyvault of UrlSigning Keys'
  }
}
param urlSigningKeysSecret1Name string {
  metadata: {
    description: 'UrlSigning keys secret1 Name'
  }
}
param urlSigningKeysSecret1Version string {
  metadata: {
    description: 'UrlSigning keys secret1 version'
  }
}
param urlSigningKeysSecret2Name string {
  metadata: {
    description: 'UrlSigning keys secret2 Name'
  }
}
param urlSigningKeysSecret2Version string {
  metadata: {
    description: 'UrlSigning keys secret2 version'
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

resource profileName_res 'Microsoft.Cdn/profiles@2020-03-31' = {
  name: profileName
  location: location
  sku: {
    name: CDNSku
  }
}

resource profileName_endpointName 'Microsoft.Cdn/profiles/endpoints@2020-03-31' = {
  location: location
  name: '${profileName}/${endpointName}'
  properties: {
    originHostHeader: originUrl
    isHttpAllowed: true
    isHttpsAllowed: true
    queryStringCachingBehavior: 'UseQueryString'
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
    urlSigningKeys: [
      {
        keyId: 'key1'
        keySourceParameters: {
          '@odata.type': '#Microsoft.Azure.Cdn.Models.KeyVaultSigningKeyParameters'
          subscriptionId: urlSigningKeysSubId
          resourceGroupName: urlSigningKeysResourceGroup
          vaultName: urlSigningKeysVaultName
          secretName: urlSigningKeysSecret1Name
          secretVersion: urlSigningKeysSecret1Version
        }
      }
      {
        keyId: 'key2'
        keySourceParameters: {
          '@odata.type': '#Microsoft.Azure.Cdn.Models.KeyVaultSigningKeyParameters'
          subscriptionId: urlSigningKeysSubId
          resourceGroupName: urlSigningKeysResourceGroup
          vaultName: urlSigningKeysVaultName
          secretName: urlSigningKeysSecret2Name
          secretVersion: urlSigningKeysSecret2Version
        }
      }
    ]
    deliveryPolicy: {
      description: 'UrlSigning'
      rules: [
        {
          name: 'rule1'
          order: 1
          conditions: [
            {
              name: 'UrlPath'
              parameters: {
                operator: 'Equal'
                matchValues: [
                  '/urlsigning/test'
                ]
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleUrlPathMatchConditionParameters'
              }
            }
          ]
          actions: [
            {
              name: 'UrlSigning'
              parameters: {
                keyId: 'key1'
                algorithm: 'SHA256'
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleUrlSigningActionParameters'
              }
            }
            {
              name: 'CacheKeyQueryString'
              parameters: {
                queryStringBehavior: 'Exclude'
                queryParameters: 'expires,keyid,signature'
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleCacheKeyQueryStringBehaviorActionParameters'
              }
            }
          ]
        }
        {
          name: 'rule2'
          order: 2
          conditions: [
            {
              name: 'UrlPath'
              parameters: {
                operator: 'Equal'
                matchValues: [
                  '/urlsigning/test2'
                ]
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleUrlPathMatchConditionParameters'
              }
            }
          ]
          actions: [
            {
              name: 'UrlSigning'
              parameters: {
                keyId: 'key2'
                algorithm: 'SHA256'
                parameterNameOverride: [
                  {
                    paramIndicator: 'Expires'
                    paramName: 'oexpires'
                  }
                  {
                    paramIndicator: 'KeyId'
                    paramName: 'okeyid'
                  }
                  {
                    paramIndicator: 'Signature'
                    paramName: 'osignature'
                  }
                ]
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleUrlSigningActionParameters'
              }
            }
            {
              name: 'CacheKeyQueryString'
              parameters: {
                queryStringBehavior: 'Exclude'
                queryParameters: 'oexpires,okeyid,osignature'
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleCacheKeyQueryStringBehaviorActionParameters'
              }
            }
          ]
        }
      ]
    }
  }
}