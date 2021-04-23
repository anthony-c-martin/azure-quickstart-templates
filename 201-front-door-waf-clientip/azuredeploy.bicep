@description('The name of the WAF policy')
param wafPolicyName string

@allowed([
  'Detection'
  'Prevention'
])
@description('Describes if it is in detection mode or prevention mode at policy level.')
param wafMode string = 'Detection'

@allowed([
  'Allow'
  'Block'
  'Log'
])
@description('Type of Action based on the match filter. Must be Allow, Block or Log.')
param IPfilteringAction string

@description('The operator to be matched.')
param IPMatch string

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