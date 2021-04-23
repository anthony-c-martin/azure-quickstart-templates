targetScope = 'subscription'

@description('Name of the resourceGroup to create')
param rgName string

@description('Location for the resourceGroup')
param rgLocation string

@description('principalId of the user that will be given contributor access to the resourceGroup')
param principalId string

@description('roleDefinition to apply to the resourceGroup - default is contributor')
param roleDefinitionId string = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

@description('Unique name for the roleAssignment in the format of a guid')
param roleAssignmentName string = guid(principalId, roleDefinitionId, rgName)

resource rgName_resource 'Microsoft.Resources/resourceGroups@2019-10-01' = {
  name: rgName
  location: rgLocation
  tags: {
    Note: 'subscription level deployment'
  }
  properties: {}
}

module applyLock './nested_applyLock.bicep' = {
  name: 'applyLock'
  scope: resourceGroup(rgName)
  params: {
    roleAssignmentName: roleAssignmentName
    roleDefinitionId: roleDefinitionId
    principalId: principalId
    rgName: rgName
  }
  dependsOn: [
    rgName_resource
  ]
}