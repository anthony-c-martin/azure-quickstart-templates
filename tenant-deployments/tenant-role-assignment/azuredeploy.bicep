targetScope = 'tenant'
param principalId string {
  metadata: {
    description: 'principalId if the user that will be given contributor access to the resourceGroup'
  }
}
param roleDefinitionId string {
  metadata: {
    description: 'roleDefinition for the assignment - default is owner'
  }
  default: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
}

var roleAssignmentName = guid('/', principalId, roleDefinitionId)

resource roleAssignmentName_resource 'Microsoft.Authorization/roleAssignments@2020-03-01-preview' = {
  name: roleAssignmentName
  properties: {
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    scope: '/'
  }
}