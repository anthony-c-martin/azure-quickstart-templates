param policyName string {
  metadata: {
    description: 'Name of the CDN WAF Policy'
  }
}
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
param policyMode string {
  allowed: [
    'Detection'
    'Prevention'
  ]
  metadata: {
    description: 'The enforcement mode of the CDN WAF Policy'
  }
  default: 'Detection'
}
param enabledState string {
  allowed: [
    'Enabled'
    'Disabled'
  ]
  metadata: {
    description: 'Whether the CDN WAF Policy is enabled'
  }
  default: 'Enabled'
}
param redirectUrl string {
  metadata: {
    description: 'The redirect URL of the CDN WAF Policy'
  }
  default: 'https://contoso.com/login'
}
param CDNSku string {
  allowed: [
    'Standard_Microsoft'
  ]
  metadata: {
    description: 'CDN SKU names'
  }
  default: 'Standard_Microsoft'
}
param location string {
  metadata: {
    description: 'Location the CDN profile and endpoint.'
  }
  default: resourceGroup().location
}

resource policyName_res 'Microsoft.Cdn/CdnWebApplicationFirewallPolicies@2019-06-15-preview' = {
  name: policyName
  location: 'Global'
  sku: {
    name: CDNSku
  }
  properties: {
    policySettings: {
      enabledState: enabledState
      mode: policyMode
      defaultRedirectUrl: redirectUrl
    }
    customRules: {
      rules: [
        {
          name: 'BlockOutsideNorthAmerica'
          priority: 10
          enabledState: 'Enabled'
          matchConditions: [
            {
              matchVariable: 'RemoteAddr'
              operator: 'GeoMatch'
              negateCondition: true
              matchValue: [
                'US'
                'MX'
                'CA'
              ]
            }
          ]
          action: 'Block'
        }
        {
          name: 'RedirectIPMatch'
          priority: 20
          enabledState: 'Enabled'
          matchConditions: [
            {
              matchVariable: 'RemoteAddr'
              operator: 'IPMatch'
              negateCondition: false
              matchValue: [
                '1.0.0.0/8'
                '2.1.1.1'
                'ffff::/16'
              ]
            }
          ]
          action: 'Redirect'
        }
        {
          name: 'AllowUnauthenticatedLogin'
          priority: 30
          enabledState: 'Enabled'
          matchConditions: [
            {
              matchVariable: 'RequestUri'
              operator: 'Contains'
              negateCondition: false
              matchValue: [
                '/login'
              ]
            }
          ]
          action: 'Allow'
        }
        {
          name: 'RedirectUnauthenticated'
          priority: 40
          enabledState: 'Enabled'
          matchConditions: [
            {
              matchVariable: 'Cookies'
              selector: 'SESSIONID'
              transforms: [
                'Trim'
              ]
              operator: 'LessThanOrEqual'
              negateCondition: false
              matchValue: [
                '0'
              ]
            }
          ]
          action: 'Redirect'
        }
      ]
    }
  }
}

resource profileName_res 'Microsoft.Cdn/profiles@2019-06-15-preview' = {
  name: profileName
  location: location
  sku: {
    name: CDNSku
  }
}

resource profileName_endpointName 'Microsoft.Cdn/profiles/endpoints@2019-06-15-preview' = {
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
    webApplicationFirewallPolicyLink: {
      id: policyName_res.id
    }
  }
  dependsOn: [
    profileName_res
  ]
}