@description('The name of the WAF policy')
param wafPolicyName string

@allowed([
  'Detection'
  'Prevention'
])
@description('Describes if it is in detection mode or prevention mode at policy level.')
param wafMode string = 'Detection'

@description('Defines rate limit duration. Default - 1 minute.')
param rateLimitDurationInMinutes int = 1

@description('Defines rate limit thresold.')
param rateLimitThreshold int

@allowed([
  'Allow'
  'Block'
  'Log'
])
@description('Type of Action based on the match filter. Must be Allow, Block or Log.')
param rateLimitAction string = 'Log'

@description('The operator to be matched.')
param ipMatch string

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