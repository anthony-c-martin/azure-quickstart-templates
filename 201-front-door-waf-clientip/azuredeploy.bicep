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
param IPfilteringAction string {
  allowed: [
    'Allow'
    'Block'
    'Log'
  ]
  metadata: {
    description: 'Type of Action based on the match filter. Must be Allow, Block or Log.'
  }
}
param IPMatch string {
  metadata: {
    description: 'The operator to be matched.'
  }
}

var wafLocation = 'global'

resource wafPolicyName_res 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2019-03-01' = {
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
          priority: 1
          enabledState: 'Enabled'
          ruleType: 'MatchRule'
          matchConditions: [
            {
              matchVariable: 'RemoteAddr'
              operator: 'IPMatch'
              matchValue: [
                IPMatch
              ]
            }
          ]
          action: IPfilteringAction
        }
      ]
    }
  }
}