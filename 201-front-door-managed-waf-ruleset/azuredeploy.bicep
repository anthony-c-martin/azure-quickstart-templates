param wafPolicyName string {
  metadata: {
    description: 'The name of the WAF policy'
  }
}
param wafMode string {
  allowed: [
    'Detection'
    'Prevention'
  ]
  metadata: {
    description: 'Describes if it is in detection mode or prevention mode at policy level.'
  }
  default: 'Detection'
}

var wafLocation = 'global'

resource wafPolicyName_resource 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2019-03-01' = {
  name: wafPolicyName
  location: wafLocation
  properties: {
    policySettings: {
      mode: wafMode
      enabledState: 'Enabled'
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