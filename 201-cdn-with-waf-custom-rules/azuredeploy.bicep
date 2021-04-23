@description('Name of the CDN WAF Policy')
param policyName string

@description('Name of the CDN Profile')
param profileName string

@description('Name of the CDN Endpoint')
param endpointName string

@description('Url of the origin')
param originUrl string

@allowed([
  'Detection'
  'Prevention'
])
@description('The enforcement mode of the CDN WAF Policy')
param policyMode string = 'Detection'

@allowed([
  'Enabled'
  'Disabled'
])
@description('Whether the CDN WAF Policy is enabled')
param enabledState string = 'Enabled'

@description('The redirect URL of the CDN WAF Policy')
param redirectUrl string = 'https://contoso.com/login'

@allowed([
  'Standard_Microsoft'
])
@description('CDN SKU names')
param CDNSku string = 'Standard_Microsoft'

@description('Location the CDN profile and endpoint.')
param location string = resourceGroup().location

resource policyName_resource 'Microsoft.Cdn/CdnWebApplicationFirewallPolicies@2019-06-15-preview' = {
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

resource profileName_resource 'Microsoft.Cdn/profiles@2019-06-15-preview' = {
  name: profileName
  location: location
  sku: {
    name: CDNSku
  }
}

resource profileName_endpointName 'Microsoft.Cdn/profiles/endpoints@2019-06-15-preview' = {
  parent: profileName_resource
  location: location
  name: '${endpointName}'
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
      id: policyName_resource.id
    }
  }
}