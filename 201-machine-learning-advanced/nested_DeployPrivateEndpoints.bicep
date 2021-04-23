param resourceId_parameters_vnetResourceGroupName_Microsoft_Network_privateEndpoints_variables_privateEndpointName string
param resourceid_parameters_vnetResourceGroupName_Microsoft_Network_privateDnsZones_privatelink_api_azureml_ms string
param resourceid_parameters_vnetResourceGroupName_Microsoft_Network_privateDnsZones_privatelink_notebooks_azure_net string
param variables_enablePE ? /* TODO: fill in correct type */
param variables_defaultPEConnections ? /* TODO: fill in correct type */
param variables_subnet ? /* TODO: fill in correct type */
param variables_vnet ? /* TODO: fill in correct type */
param variables_privateEndpointName ? /* TODO: fill in correct type */

@description('Specifies the name of the Azure Machine Learning workspace.')
param workspaceName string

@description('Required if existing VNET location differs from workspace location')
param vnetLocation string

@description('Tags for workspace, will also be populated if provisioning new dependent resources.')
param tagValues object

@allowed([
  'AutoApproval'
  'ManualApproval'
  'none'
])
param privateEndpointType string

resource workspaceName_PrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = if (variables_enablePE) {
  name: '${workspaceName}-PrivateEndpoint'
  location: vnetLocation
  tags: tagValues
  properties: {
    privateLinkServiceConnections: ((privateEndpointType == 'AutoApproval') ? variables_defaultPEConnections : json('null'))
    manualPrivateLinkServiceConnections: ((privateEndpointType == 'ManualApproval') ? variables_defaultPEConnections : json('null'))
    subnet: {
      id: variables_subnet
    }
  }
}

resource privatelink_api_azureml_ms 'Microsoft.Network/privateDnsZones@2020-01-01' = if (privateEndpointType == 'AutoApproval') {
  name: 'privatelink.api.azureml.ms'
  location: 'global'
  tags: tagValues
  properties: {}
  dependsOn: [
    resourceId_parameters_vnetResourceGroupName_Microsoft_Network_privateEndpoints_variables_privateEndpointName
  ]
}

resource privatelink_notebooks_azure_net 'Microsoft.Network/privateDnsZones@2020-01-01' = if (privateEndpointType == 'AutoApproval') {
  name: 'privatelink.notebooks.azure.net'
  location: 'global'
  tags: tagValues
  properties: {}
  dependsOn: [
    resourceId_parameters_vnetResourceGroupName_Microsoft_Network_privateEndpoints_variables_privateEndpointName
  ]
}

resource privatelink_api_azureml_ms_variables_vnet 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-01-01' = if (privateEndpointType == 'AutoApproval') {
  parent: privatelink_api_azureml_ms
  name: uniqueString(variables_vnet)
  location: 'global'
  tags: tagValues
  properties: {
    virtualNetwork: {
      id: variables_vnet
    }
    registrationEnabled: false
  }
  dependsOn: [
    resourceId_parameters_vnetResourceGroupName_Microsoft_Network_privateEndpoints_variables_privateEndpointName
  ]
}

resource privatelink_notebooks_azure_net_variables_vnet 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-01-01' = if (privateEndpointType == 'AutoApproval') {
  parent: privatelink_notebooks_azure_net
  name: uniqueString(variables_vnet)
  location: 'global'
  tags: tagValues
  properties: {
    virtualNetwork: {
      id: variables_vnet
    }
    registrationEnabled: false
  }
  dependsOn: [
    resourceId_parameters_vnetResourceGroupName_Microsoft_Network_privateEndpoints_variables_privateEndpointName
  ]
}

resource variables_privateEndpointName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = if (privateEndpointType == 'AutoApproval') {
  name: '${variables_privateEndpointName}/default'
  location: vnetLocation
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-api-azureml-ms'
        properties: {
          privateDnsZoneId: resourceid_parameters_vnetResourceGroupName_Microsoft_Network_privateDnsZones_privatelink_api_azureml_ms
        }
      }
      {
        name: 'privatelink-notebooks-azure-net'
        properties: {
          privateDnsZoneId: resourceid_parameters_vnetResourceGroupName_Microsoft_Network_privateDnsZones_privatelink_notebooks_azure_net
        }
      }
    ]
  }
  dependsOn: [
    resourceId_parameters_vnetResourceGroupName_Microsoft_Network_privateEndpoints_variables_privateEndpointName
    privatelink_notebooks_azure_net
    privatelink_api_azureml_ms
  ]
}