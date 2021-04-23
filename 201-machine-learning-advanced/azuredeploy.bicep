@description('Specifies the name of the Azure Machine Learning workspace.')
param workspaceName string

@description('Specifies the location for workspace.')
param location string

@allowed([
  'basic'
  'enterprise'
])
@description('Specifies the sku, also referred as \'edition\' of the Azure Machine Learning workspace.')
param sku string = 'basic'

@allowed([
  'systemAssigned'
  'userAssigned'
])
@description('Specifies the identity type of the Azure Machine Learning workspace.')
param identityType string = 'systemAssigned'

@description('Specifies the resource group of user assigned identity that represents the Azure Machine Learing workspace.')
param primaryUserAssignedIdentityResourceGroup string = resourceGroup().name

@description('Specifies the name of user assigned identity that represents the Azure Machine Learing workspace.')
param primaryUserAssignedIdentityName string = ''

@description('Tags for workspace, will also be populated if provisioning new dependent resources.')
param tagValues object = {}

@allowed([
  'new'
  'existing'
])
@description('Determines whether or not a new storage should be provisioned.')
param storageAccountOption string = 'new'

@description('Name of the storage account.')
param storageAccountName string = 'sa${uniqueString(resourceGroup().id, workspaceName)}'

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param storageAccountType string = 'Standard_LRS'

@allowed([
  'true'
  'false'
])
@description('Determines whether or not to put the storage account behind VNet')
param storageAccountBehindVNet string = 'false'

@description('Resource group name of the storage account if using existing one')
param storageAccountResourceGroupName string = resourceGroup().name

@allowed([
  'new'
  'existing'
])
@description('Determines whether or not a new key vault should be provisioned.')
param keyVaultOption string = 'new'

@description('Name of the key vault.')
param keyVaultName string = 'kv${uniqueString(resourceGroup().id, workspaceName)}'

@allowed([
  'true'
  'false'
])
@description('Determines whether or not to put the storage account behind VNet')
param keyVaultBehindVNet string = 'false'

@description('Resource group name of the key vault if using existing one')
param keyVaultResourceGroupName string = resourceGroup().name

@allowed([
  'new'
  'existing'
])
@description('Determines whether or not new ApplicationInsights should be provisioned.')
param applicationInsightsOption string = 'new'

@description('Name of ApplicationInsights.')
param applicationInsightsName string = 'ai${uniqueString(resourceGroup().id, workspaceName)}'

@description('Resource group name of the application insights if using existing one.')
param applicationInsightsResourceGroupName string = resourceGroup().name

@allowed([
  'new'
  'existing'
  'none'
])
@description('Determines whether or not a new container registry should be provisioned.')
param containerRegistryOption string = 'none'

@description('The container registry bind to the workspace.')
param containerRegistryName string = 'cr${uniqueString(resourceGroup().id, workspaceName)}'

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param containerRegistrySku string = 'Standard'

@description('Resource group name of the container registry if using existing one.')
param containerRegistryResourceGroupName string = resourceGroup().name

@allowed([
  'true'
  'false'
])
@description('Determines whether or not to put container registry behind VNet.')
param containerRegistryBehindVNet string = 'false'

@allowed([
  'new'
  'existing'
  'none'
])
@description('Determines whether or not a new VNet should be provisioned.')
param vnetOption string = ((privateEndpointType == 'none') ? 'none' : 'new')

@description('Name of the VNet')
param vnetName string = 'vn${uniqueString(resourceGroup().id, workspaceName)}'

@description('Resource group name of the VNET if using existing one.')
param vnetResourceGroupName string = resourceGroup().name

@description('Required if existing VNET location differs from workspace location')
param vnetLocation string = location

@description('Address prefix of the virtual network')
param addressPrefixes array = [
  '10.0.0.0/16'
]

@allowed([
  'new'
  'existing'
  'none'
])
@description('Determines whether or not a new subnet should be provisioned.')
param subnetOption string = (((!(privateEndpointType == 'none')) || (vnetOption == 'new')) ? 'new' : 'none')

@description('Name of the subnet')
param subnetName string = 'sn${uniqueString(resourceGroup().id, workspaceName)}'

@description('Subnet prefix of the virtual network')
param subnetPrefix string = '10.0.0.0/24'

@description('Azure Databrick workspace to be linked to the workspace')
param adbWorkspace string = ''

@allowed([
  'false'
  'true'
])
@description('Specifies that the Azure Machine Learning workspace holds highly confidential data.')
param confidential_data string = 'false'

@allowed([
  'Enabled'
  'Disabled'
])
@description('Specifies if the Azure Machine Learning workspace should be encrypted with customer managed key.')
param encryption_status string = 'Disabled'

@description('Specifies the customer managed keyVault arm id. Required when encryption is enabled')
param cmk_keyvault string = ''

@description('Specifies if the customer managed keyvault key uri. Required when encryption is enabled')
param resource_cmk_uri string = ''

@allowed([
  'AutoApproval'
  'ManualApproval'
  'none'
])
param privateEndpointType string = 'none'

var tenantId = subscription().tenantId
var storageAccount = resourceId(storageAccountResourceGroupName, 'Microsoft.Storage/storageAccounts', storageAccountName)
var keyVault = resourceId(keyVaultResourceGroupName, 'Microsoft.KeyVault/vaults', keyVaultName)
var containerRegistry = resourceId(containerRegistryResourceGroupName, 'Microsoft.ContainerRegistry/registries', containerRegistryName)
var applicationInsights = resourceId(applicationInsightsResourceGroupName, 'Microsoft.Insights/components', applicationInsightsName)
var vnet = resourceId(vnetResourceGroupName, 'Microsoft.Network/virtualNetworks', vnetName)
var subnet = resourceId(vnetResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
var privateEndpointName = '${workspaceName}-PrivateEndpoint'
var enablePE = (!(privateEndpointType == 'none'))
var networkRuleSetBehindVNet = {
  defaultAction: 'deny'
  virtualNetworkRules: [
    {
      action: 'Allow'
      id: subnet
    }
  ]
}
var subnetPolicyForPE = {
  privateEndpointNetworkPolicies: 'Disabled'
  privateLinkServiceNetworkPolicies: 'Enabled'
}
var privateEndpointSettings = {
  name: '${workspaceName}-PrivateEndpoint'
  properties: {
    privateLinkServiceId: workspaceName_resource.id
    groupIds: [
      'amlworkspace'
    ]
  }
}
var defaultPEConnections = array(privateEndpointSettings)
var userAssignedIdentities = {
  '${primaryUserAssignedIdentity}': {}
}
var primaryUserAssignedIdentity = resourceId(primaryUserAssignedIdentityResourceGroup, 'Microsoft.ManagedIdentity/userAssignedIdentities', primaryUserAssignedIdentityName)
var azAppInsightsLocationMap = {
  eastasia: 'eastasia'
  southeastasia: 'southeastasia'
  centralus: 'westcentralus'
  eastus: 'eastus'
  eastus2: 'eastus2'
  westus: 'westus'
  northcentralus: 'northcentralus'
  southcentralus: 'southcentralus'
  northeurope: 'northeurope'
  westeurope: 'westeurope'
  japanwest: 'japanwest'
  japaneast: 'japaneast'
  brazilsouth: 'brazilsouth'
  australiaeast: 'australiaeast'
  australiasoutheast: 'australiasoutheast'
  southindia: 'southindia'
  centralindia: 'centralindia'
  westindia: 'westindia'
  canadacentral: 'canadacentral'
  canadaeast: 'canadaeast'
  uksouth: 'uksouth'
  ukwest: 'ukwest'
  westcentralus: 'southcentralus'
  westus2: 'westus2'
  koreacentral: 'koreacentral'
  koreasouth: 'koreasouth'
  eastus2euap: 'southcentralus'
  centraluseuap: 'southcentralus'
}
var appInsightsLocation = azAppInsightsLocationMap[location]

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2020-06-01' = if (vnetOption == 'new') {
  name: vnetName
  location: location
  tags: tagValues
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    enableDdosProtection: false
    enableVmProtection: false
  }
}

resource vnetName_subnetName 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' = if (subnetOption == 'new') {
  parent: vnetName_resource
  name: '${subnetName}'
  properties: {
    addressPrefix: subnetPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
      {
        service: 'Microsoft.KeyVault'
      }
      {
        service: 'Microsoft.ContainerRegistry'
      }
    ]
  }
}

module UpdateSubnetPolicy './nested_UpdateSubnetPolicy.bicep' = if ((subnetOption == 'existing') && (!(privateEndpointType == 'none'))) {
  name: 'UpdateSubnetPolicy'
  scope: resourceGroup(vnetResourceGroupName)
  params: {
    reference_variables_subnet_2020_06_01: reference(subnet, '2020-06-01')
    variables_subnetPolicyForPE: subnetPolicyForPE
    vnetName: vnetName
    subnetName: subnetName
    subnetOption: subnetOption
    privateEndpointType: privateEndpointType
  }
}

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = if (storageAccountOption == 'new') {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  tags: tagValues
  properties: {
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    supportsHttpsTrafficOnly: true
    networkAcls: ((storageAccountBehindVNet == 'true') ? networkRuleSetBehindVNet : json('null'))
  }
  dependsOn: [
    vnetName_subnetName
  ]
}

resource keyVaultName_resource 'Microsoft.KeyVault/vaults@2019-09-01' = if (keyVaultOption == 'new') {
  name: keyVaultName
  location: location
  tags: tagValues
  properties: {
    tenantId: tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: []
    networkAcls: ((keyVaultBehindVNet == 'true') ? networkRuleSetBehindVNet : json('null'))
  }
  dependsOn: [
    vnetName_subnetName
  ]
}

resource containerRegistryName_resource 'Microsoft.ContainerRegistry/registries@2019-12-01-preview' = if (containerRegistryOption == 'new') {
  name: containerRegistryName
  location: location
  sku: {
    name: containerRegistrySku
  }
  tags: tagValues
  properties: {
    adminUserEnabled: true
    networkRuleSet: ((containerRegistryBehindVNet == 'true') ? networkRuleSetBehindVNet : json('null'))
  }
  dependsOn: [
    vnetName_subnetName
  ]
}

resource applicationInsightsName_resource 'Microsoft.Insights/components@2020-02-02-preview' = if (applicationInsightsOption == 'new') {
  name: applicationInsightsName
  location: appInsightsLocation
  kind: 'web'
  tags: tagValues
  properties: {
    Application_Type: 'web'
  }
}

resource workspaceName_resource 'Microsoft.MachineLearningServices/workspaces@2020-09-01-preview' = {
  name: workspaceName
  location: location
  sku: {
    tier: sku
    name: sku
  }
  identity: {
    type: identityType
    userAssignedIdentities: ((identityType == 'userAssigned') ? userAssignedIdentities : json('null'))
  }
  tags: tagValues
  properties: {
    friendlyName: workspaceName
    storageAccount: storageAccount
    keyVault: keyVault
    applicationInsights: applicationInsights
    containerRegistry: ((!(containerRegistryOption == 'none')) ? containerRegistry : json('null'))
    adbWorkspace: (empty(adbWorkspace) ? json('null') : adbWorkspace)
    primaryUserAssignedIdentity: ((identityType == 'userAssigned') ? primaryUserAssignedIdentity : json('null'))
    encryption: {
      status: encryption_status
      keyVaultProperties: {
        keyVaultArmId: cmk_keyvault
        keyIdentifier: resource_cmk_uri
      }
    }
    hbiWorkspace: confidential_data
  }
  dependsOn: [
    storageAccountName_resource
    keyVaultName_resource
    applicationInsightsName_resource
    containerRegistryName_resource
  ]
}

module DeployPrivateEndpoints './nested_DeployPrivateEndpoints.bicep' = {
  name: 'DeployPrivateEndpoints'
  scope: resourceGroup(vnetResourceGroupName)
  params: {
    resourceId_parameters_vnetResourceGroupName_Microsoft_Network_privateEndpoints_variables_privateEndpointName: resourceId(vnetResourceGroupName, 'Microsoft.Network/privateEndpoints', privateEndpointName)
    resourceid_parameters_vnetResourceGroupName_Microsoft_Network_privateDnsZones_privatelink_api_azureml_ms: resourceId(vnetResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.api.azureml.ms')
    resourceid_parameters_vnetResourceGroupName_Microsoft_Network_privateDnsZones_privatelink_notebooks_azure_net: resourceId(vnetResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.notebooks.azure.net')
    variables_enablePE: enablePE
    variables_defaultPEConnections: defaultPEConnections
    variables_subnet: subnet
    variables_vnet: vnet
    variables_privateEndpointName: privateEndpointName
    workspaceName: workspaceName
    vnetLocation: vnetLocation
    tagValues: tagValues
    privateEndpointType: privateEndpointType
  }
  dependsOn: [
    vnetName_subnetName
  ]
}