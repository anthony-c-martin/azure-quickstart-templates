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
param httpRule1 object {
  metadata: {
    description: 'Defines contents of a web application rule 1'
  }
}
param httpRule2 object {
  metadata: {
    description: 'Defines contents of a web application rule 2'
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
          name: httpRule1.name
          priority: httpRule1.priority
          enabledState: httpRule1.enabledState
          ruleType: httpRule1.ruleType
          copy: [
            {
              name: 'matchConditions'
              count: length(httpRule1.matchConditions)
              input: {
                matchVariable: httpRule1.matchConditions[copyIndex('matchConditions')].matchVariable
                operator: httpRule1.matchConditions[copyIndex('matchConditions')].operator
                selector: httpRule1.matchConditions[copyIndex('matchConditions')].selector
                matchValue: httpRule1.matchConditions[copyIndex('matchConditions')].matchValue
              }
            }
          ]
          action: httpRule1.action
        }
        {
          name: httpRule2.name
          priority: httpRule2.priority
          enabledState: httpRule2.enabledState
          ruleType: httpRule2.ruleType
          copy: [
            {
              name: 'matchConditions'
              count: length(httpRule2.matchConditions)
              input: {
                matchVariable: httpRule2.matchConditions[copyIndex('matchConditions')].matchVariable
                operator: httpRule2.matchConditions[copyIndex('matchConditions')].operator
                selector: httpRule2.matchConditions[copyIndex('matchConditions')].selector
                matchValue: httpRule2.matchConditions[copyIndex('matchConditions')].matchValue
              }
            }
          ]
          action: httpRule2.action
        }
      ]
    }
  }
}