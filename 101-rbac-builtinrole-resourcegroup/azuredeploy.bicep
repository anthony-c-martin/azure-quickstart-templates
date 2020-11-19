param roleDefinitionID string {
  metadata: {
    description: 'Specifies the role definition ID used in the role assignment.'
  }
}
param principalId string {
  metadata: {
    description: 'Specifies the principal ID assigned to the role.'
  }
}

var roleAssignmentName_var = guid(principalId, roleDefinitionID, resourceGroup().id)

resource roleAssignmentName 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: roleAssignmentName_var
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionID)
    principalId: principalId
    scope: resourceGroup().id
  }
}