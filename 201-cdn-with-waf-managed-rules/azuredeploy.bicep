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
      enabledState: 'Enabled'
      mode: policyMode
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'DefaultRuleSet'
          ruleSetVersion: '1.0'
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
}