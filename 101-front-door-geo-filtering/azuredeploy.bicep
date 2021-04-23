@description('The name of the WAF policy')
param wafPolicyName string

@allowed([
  'Allow'
  'Block'
  'Log'
])
@description('Type of Action based on the match filter. Must be Allow, Block or Log.')
param GeofilteringAction string

@description('The geographical region to be matched based on ISO 3166-1 alpha-2')
param GeoMatch string

@allowed([
  'Detection'
  'Prevention'
])
@description('Describes if it is in detection mode or prevention mode at policy level.')
param wafMode string = 'Detection'

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
          ruleType: 'MatchRule'
          matchConditions: [
            {
              matchVariable: 'RemoteAddr'
              operator: 'GeoMatch'
              matchValue: [
                GeoMatch
              ]
            }
          ]
          action: GeofilteringAction
        }
      ]
    }
  }
}