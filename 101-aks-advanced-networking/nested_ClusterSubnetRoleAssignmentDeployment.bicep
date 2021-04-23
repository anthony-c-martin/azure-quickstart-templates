param variables_builtInRole_parameters_builtInRoleType ? /* TODO: fill in correct type */
param variables_vnetSubnetId ? /* TODO: fill in correct type */

@description('Name of an existing VNET that will contain this AKS deployment.')
param existingVirtualNetworkName string

@description('Subnet name that will contain the App Service Environment')
param existingSubnetName string

@allowed([
  'Owner'
  'Contributor'
  'Reader'
])
@description('Built-in role to assign')
param builtInRoleType string

@description('Oject ID against which the Network Contributor roles will be assigned on the subnet')
param existingServicePrincipalObjectId string

resource existingVirtualNetworkName_existingSubnetName_Microsoft_Authorization_id_name 'Microsoft.Network/virtualNetworks/subnets/providers/roleAssignments@2020-04-01-preview' = {
  name: '${existingVirtualNetworkName}/${existingSubnetName}/Microsoft.Authorization/${guid(resourceGroup().id, deployment().name)}'
  properties: {
    roleDefinitionId: variables_builtInRole_parameters_builtInRoleType[builtInRoleType]
    principalId: existingServicePrincipalObjectId
    scope: variables_vnetSubnetId
  }
}