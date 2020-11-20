param policyAssignmentName string {
  metadata: {
    description: 'Specifies the name of the policy assignment, can be used defined or an idempotent name as the defaultValue provides.'
  }
  default: guid(policyDefinitionID, resourceGroup().name)
}
param policyDefinitionID string {
  metadata: {
    description: 'Specifies the ID of the policy definition or policy set definition being assigned.'
  }
}

resource policyAssignmentName_res 'Microsoft.Authorization/policyAssignments@2019-09-01' = {
  name: policyAssignmentName
  properties: {
    scope: subscriptionResourceId('Microsoft.Resources/resourceGroups', resourceGroup().name)
    policyDefinitionId: policyDefinitionID
  }
}