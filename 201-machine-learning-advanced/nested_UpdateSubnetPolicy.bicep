param reference_variables_subnet_2020_06_01 object
param variables_subnetPolicyForPE ? /* TODO: fill in correct type */

@description('Name of the VNet')
param vnetName string

@description('Name of the subnet')
param subnetName string

@allowed([
  'new'
  'existing'
  'none'
])
@description('Determines whether or not a new subnet should be provisioned.')
param subnetOption string

@allowed([
  'AutoApproval'
  'ManualApproval'
  'none'
])
param privateEndpointType string

resource vnetName_subnetName 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' = {
  name: '${vnetName}/${subnetName}'
  properties: (((subnetOption == 'existing') && (!(privateEndpointType == 'none'))) ? union(reference_variables_subnet_2020_06_01, variables_subnetPolicyForPE) : json('null'))
}