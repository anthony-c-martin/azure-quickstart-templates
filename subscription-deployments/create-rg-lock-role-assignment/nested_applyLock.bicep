@description('Unique name for the roleAssignment in the format of a guid')
param roleAssignmentName string

@description('roleDefinition to apply to the resourceGroup - default is contributor')
param roleDefinitionId string

@description('principalId of the user that will be given contributor access to the resourceGroup')
param principalId string

@description('Name of the resourceGroup to create')
param rgName string

resource DontDelete 'Microsoft.Authorization/locks@2017-04-01' = {
  name: 'DontDelete'
  properties: {
    level: 'CanNotDelete'
    notes: 'Prevent deletion of the resourceGroup'
  }
}

resource roleAssignmentName_resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(roleAssignmentName)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    scope: subscriptionResourceId('Microsoft.Resources/resourceGroups', rgName)
  }
}