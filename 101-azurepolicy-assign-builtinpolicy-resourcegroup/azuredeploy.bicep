@description('Specifies the name of the policy assignment, can be used defined or an idempotent name as the defaultValue provides.')
param policyAssignmentName string = guid(policyDefinitionID, resourceGroup().name)

@description('Specifies the ID of the policy definition or policy set definition being assigned.')
param policyDefinitionID string

resource policyAssignmentName_resource 'Microsoft.Authorization/policyAssignments@2019-09-01' = {
  name: policyAssignmentName
  properties: {
    scope: subscriptionResourceId('Microsoft.Resources/resourceGroups', resourceGroup().name)
    policyDefinitionId: policyDefinitionID
  }
}