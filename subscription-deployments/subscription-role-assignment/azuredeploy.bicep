targetScope = 'subscription'
param principalId string {
  metadata: {
    description: 'principalId if the user that will be given contributor access to the resourceGroup'
  }
}
param roleDefinitionId string {
  metadata: {
    description: 'roleDefinition for the assignment - default is contributor'
  }
  default: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

var roleAssignmentName_var = guid(subscription().id, principalId, roleDefinitionId)

resource roleAssignmentName 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: roleAssignmentName_var
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    scope: subscription().id
  }
}