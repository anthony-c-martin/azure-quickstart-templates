param variables_vnetSubnetId ? /* TODO: fill in correct type */

@description('Name of the Role Assignment created for the Service Principal in the existing Subnet')
param existingSubnetRoleAssignmentName string

@description('Oject ID against which the Network Contributor roles will be assigned on the subnet')
@secure()
param existingServicePrincipalObjectId string

resource existingSubnetRoleAssignmentName_resource 'Microsoft.Network/virtualNetworks/subnets/providers/roleAssignments@2017-05-01' = {
  name: existingSubnetRoleAssignmentName
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'
    principalId: existingServicePrincipalObjectId
    scope: variables_vnetSubnetId
  }
}