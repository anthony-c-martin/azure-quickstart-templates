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
param rateLimitDurationInMinutes int {
  metadata: {
    description: 'Defines rate limit duration. Default - 1 minute.'
  }
  default: 1
}
param rateLimitThreshold int {
  metadata: {
    description: 'Defines rate limit thresold.'
  }
}
param rateLimitAction string {
  allowed: [
    'Allow'
    'Block'
    'Log'
  ]
  metadata: {
    description: 'Type of Action based on the match filter. Must be Allow, Block or Log.'
  }
  default: 'Log'
}
param ipMatch string {
  metadata: {
    description: 'The operator to be matched.'
  }
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
    customRules: {
      rules: [
        {
          name: 'Rule1'
          enabledState: 'Enabled'
          priority: 1
          ruleType: 'RateLimitRule'
          rateLimitThreshold: rateLimitThreshold
          rateLimitDurationInMinutes: rateLimitDurationInMinutes
          matchConditions: [
            {
              matchVariable: 'RemoteAddr'
              operator: 'IPMatch'
              matchValue: [
                ipMatch
              ]
            }
          ]
          action: rateLimitAction
        }
      ]
    }
  }
}