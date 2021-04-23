@description('Principal ID associated with the subscription ID')
param principalId string

@description('Name of the virtual machine')
param virtualMachineName string

@allowed([
  'Owner'
  'Contributor'
  'Reader'
  'Virtual Machine Contributor'
])
@description('Built In Role Type for the Virtual Machine')
param builtInRoleType string

var role = {
  Owner: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  Contributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  Reader: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  'Virtual Machine Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'd73bb868-a0df-4d4d-bd69-98a00b01fccb')
}
var roleAssignmentName_var = guid(resourceId('Microsoft.Compute/virtualMachines', virtualMachineName), role[builtInRoleType], principalId)

resource roleAssignmentName 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: roleAssignmentName_var
  properties: {
    roleDefinitionId: role[builtInRoleType]
    principalId: principalId
  }
  scope: 'Microsoft.Compute/virtualMachines/${virtualMachineName}'
}