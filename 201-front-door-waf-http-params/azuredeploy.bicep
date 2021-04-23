@description('The name of the WAF policy')
param wafPolicyName string

@allowed([
  'Detection'
  'Prevention'
])
@description('Describes if it is in detection mode or prevention mode at policy level.')
param wafMode string = 'Detection'

@description('Defines contents of a web application rule 1')
param httpRule1 object

@description('Defines contents of a web application rule 2')
param httpRule2 object

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
          matchConditions: [for j in range(0, length(httpRule1.matchConditions)): {
            matchVariable: httpRule1.matchConditions[j].matchVariable
            operator: httpRule1.matchConditions[j].operator
            selector: httpRule1.matchConditions[j].selector
            matchValue: httpRule1.matchConditions[j].matchValue
          }]
          action: httpRule1.action
        }
        {
          name: httpRule2.name
          priority: httpRule2.priority
          enabledState: httpRule2.enabledState
          ruleType: httpRule2.ruleType
          matchConditions: [for j in range(0, length(httpRule2.matchConditions)): {
            matchVariable: httpRule2.matchConditions[j].matchVariable
            operator: httpRule2.matchConditions[j].operator
            selector: httpRule2.matchConditions[j].selector
            matchValue: httpRule2.matchConditions[j].matchValue
          }]
          action: httpRule2.action
        }
      ]
    }
  }
}