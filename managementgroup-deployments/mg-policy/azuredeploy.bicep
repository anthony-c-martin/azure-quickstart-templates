targetScope = 'managementGroup'
param targetMG string {
  metadata: {
    description: 'Target Management Group'
  }
}
param allowedLocations array {
  metadata: {
    description: 'An array of the allowed locations, all other locations will be denied by the created policy.'
  }
  default: [
    'australiaeast'
    'australiasoutheast'
    'australiacentral'
  ]
}

var mgScope = tenantResourceId('Microsoft.Management/managementGroups', targetMG)
var policyDefinition_var = 'LocationRestriction'

resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2019-09-01' = {
  name: policyDefinition_var
  properties: {
    policyType: 'Custom'
    mode: 'All'
    parameters: {}
    policyRule: {
      if: {
        not: {
          field: 'location'
          in: allowedLocations
        }
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

resource location_lock 'Microsoft.Authorization/policyAssignments@2019-09-01' = {
  name: 'location-lock'
  properties: {
    scope: mgScope
    policyDefinitionId: extensionResourceId(mgScope, 'Microsoft.Authorization/policyDefinitions', policyDefinition_var)
  }
}