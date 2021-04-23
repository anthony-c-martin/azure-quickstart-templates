@description('Resource group of User Assigned Identity passed in workspace.properties.primaryUserAssignedIdentity.')
param primaryUserAssignedIdentityResourceGroup string = resourceGroup().name

@description('Resource name of User Assigned Identity passed in workspace.properties.primaryUserAssignedIdentity.')
param primaryUserAssignedIdentityName string

@description('If assign AML workspace resource group permissions.')
param assignWorkspaceResourceGroup bool = false

@description('Resource group of AML workspace resource group.')
param workspaceResourceGroup string = resourceGroup().name

@description('If assign AML workspace keyvault permissions.')
param assignWorkspaceKeyVault bool = false

@description('Resource group of AML workspace key vault.')
param workspaceKeyVaultResourceGroup string = resourceGroup().name

@description('Resource name of AML workspace key vault.')
param workspaceKeyVaultName string

@description('If assign AML workspace storage account permissions.')
param assignWorkspaceStorageAccount bool = false

@description('Resource group of AML workspace storage account.')
param workspaceStorageAccountResourceGroup string = resourceGroup().name

@description('Resource name of AML workspace storage account.')
param workspaceStorageAccountName string = ''

@description('If assign AML workspace container registry permissions.')
param assignWorkspaceContainerRegistry bool = false

@description('Resource group of AML workspace container registry.')
param workspaceContainerRegistryResourceGroup string = resourceGroup().name

@description('Resource name of AML workspace container registry.')
param workspaceContainerRegistryName string = ''

@description('If assign AML workspace linked Azure DataBrick permissions.')
param assignWorkspaceDataBrick bool = false

@description('Resource group of AML workspace linked Azure DataBrick.')
param workspaceDataBrickResourceGroup string = resourceGroup().name

@description('Resource name of AML workspace linked Azure DataBrick.')
param workspaceDataBrickName string = ''

@description('If assign keyvault that hosts data encryption key of cmk workspace permissions.')
param assignWorkspaceCMKKeyVault bool = false

@description('Resource group of keyvault that hosts data encryption key of cmk workspace.')
param workspaceCMKKeyVaultResourceGroup string = resourceGroup().name

@description('Resource name of keyvault that hosts data encryption key of cmk workspace.')
param workspaceCMKKeyVaultName string = ''

var primaryUserAssignedIdentity = resourceId(primaryUserAssignedIdentityResourceGroup, 'microsoft.managedidentity/userassignedidentities', primaryUserAssignedIdentityName)
var workspaceResourceGroup_var = subscriptionResourceId('Microsoft.Resources/resourceGroups', workspaceResourceGroup)
var workspaceKeyVault = resourceId(workspaceKeyVaultResourceGroup, 'microsoft.keyvault/vaults', workspaceKeyVaultName)
var workspaceStorageAccount = resourceId(workspaceStorageAccountResourceGroup, 'microsoft.storage/storageaccounts', workspaceStorageAccountName)
var workspaceContainerRegistry = resourceId(workspaceContainerRegistryResourceGroup, 'Microsoft.ContainerRegistry/registries', workspaceContainerRegistryName)
var workspaceDataBrick = resourceId(workspaceDataBrickResourceGroup, 'Microsoft.Databricks/workspaces', workspaceDataBrickName)
var workspaceCMKKeyVault = resourceId(workspaceCMKKeyVaultResourceGroup, 'microsoft.keyvault/vaults', workspaceCMKKeyVaultName)
var contributorRoleDefinition = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var storageBlobDataContributorRoleDefinition = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var keyVaultAdministratorRoleDefinition = '00482a5a-887f-4fb3-b363-3b7fe8e74483'
var workspaceResourceGroupContributorRoleName = guid(workspaceResourceGroup_var, primaryUserAssignedIdentity, contributorRoleDefinition)
var workspaceStorageAccountContributorRoleName = guid(workspaceStorageAccount, primaryUserAssignedIdentity, contributorRoleDefinition)
var workspaceStorageAccountBlobDataContributorRoleName = guid(workspaceStorageAccount, primaryUserAssignedIdentity, storageBlobDataContributorRoleDefinition)
var workspaceKeyVaultAdministratorRoleName = guid(workspaceKeyVault, primaryUserAssignedIdentity, keyVaultAdministratorRoleDefinition)
var workspaceContainerRegistryContributorRoleName = guid(workspaceContainerRegistry, primaryUserAssignedIdentity, contributorRoleDefinition)
var workspaceDataBrickContributorRoleName = guid(workspaceDataBrick, primaryUserAssignedIdentity, contributorRoleDefinition)
var workspaceCMKKeyVaultContributorRoleName = guid(workspaceCMKKeyVault, primaryUserAssignedIdentity, contributorRoleDefinition)

module keyvaultTemplate './nested_keyvaultTemplate.bicep' = {
  name: 'keyvaultTemplate'
  scope: resourceGroup(workspaceKeyVaultResourceGroup)
  params: {
    reference_variables_primaryUserAssignedIdentity_2018_11_30_tenantId: reference(primaryUserAssignedIdentity, '2018-11-30')
    reference_variables_primaryUserAssignedIdentity_2018_11_30_principalId: reference(primaryUserAssignedIdentity, '2018-11-30')
    variables_workspaceKeyVaultAdministratorRoleName: workspaceKeyVaultAdministratorRoleName
    variables_workspaceKeyVault: workspaceKeyVault
    variables_keyVaultAdministratorRoleDefinition: keyVaultAdministratorRoleDefinition
    assignWorkspaceKeyVault: assignWorkspaceKeyVault
    workspaceKeyVaultName: workspaceKeyVaultName
  }
}

module storageAccountTemplate './nested_storageAccountTemplate.bicep' = {
  name: 'storageAccountTemplate'
  scope: resourceGroup(workspaceStorageAccountResourceGroup)
  params: {
    reference_variables_primaryUserAssignedIdentity_2018_11_30_principalId: reference(primaryUserAssignedIdentity, '2018-11-30')
    variables_workspaceStorageAccountContributorRoleName: workspaceStorageAccountContributorRoleName
    variables_workspaceStorageAccount: workspaceStorageAccount
    variables_contributorRoleDefinition: contributorRoleDefinition
    variables_workspaceStorageAccountBlobDataContributorRoleName: workspaceStorageAccountBlobDataContributorRoleName
    variables_storageBlobDataContributorRoleDefinition: storageBlobDataContributorRoleDefinition
    assignWorkspaceStorageAccount: assignWorkspaceStorageAccount
    workspaceStorageAccountName: workspaceStorageAccountName
  }
}

module databrickTemplate './nested_databrickTemplate.bicep' = {
  name: 'databrickTemplate'
  scope: resourceGroup(workspaceDataBrickResourceGroup)
  params: {
    reference_variables_primaryUserAssignedIdentity_2018_11_30_principalId: reference(primaryUserAssignedIdentity, '2018-11-30')
    variables_workspaceDataBrickContributorRoleName: workspaceDataBrickContributorRoleName
    variables_workspaceDataBrick: workspaceDataBrick
    variables_contributorRoleDefinition: contributorRoleDefinition
    assignWorkspaceDataBrick: assignWorkspaceDataBrick
    workspaceDataBrickName: workspaceDataBrickName
  }
}

module containerRegistryTemplate './nested_containerRegistryTemplate.bicep' = {
  name: 'containerRegistryTemplate'
  scope: resourceGroup(workspaceContainerRegistryResourceGroup)
  params: {
    reference_variables_primaryUserAssignedIdentity_2018_11_30_principalId: reference(primaryUserAssignedIdentity, '2018-11-30')
    variables_workspaceContainerRegistryContributorRoleName: workspaceContainerRegistryContributorRoleName
    variables_workspaceContainerRegistry: workspaceContainerRegistry
    variables_contributorRoleDefinition: contributorRoleDefinition
    assignWorkspaceContainerRegistry: assignWorkspaceContainerRegistry
    workspaceContainerRegistryName: workspaceContainerRegistryName
  }
}

module cmkKeyvaultTemplate './nested_cmkKeyvaultTemplate.bicep' = {
  name: 'cmkKeyvaultTemplate'
  scope: resourceGroup(workspaceCMKKeyVaultResourceGroup)
  params: {
    reference_variables_primaryUserAssignedIdentity_2018_11_30_principalId: reference(primaryUserAssignedIdentity, '2018-11-30')
    variables_workspaceCMKKeyVaultContributorRoleName: workspaceCMKKeyVaultContributorRoleName
    variables_workspaceCMKKeyVault: workspaceCMKKeyVault
    variables_contributorRoleDefinition: contributorRoleDefinition
    assignWorkspaceCMKKeyVault: assignWorkspaceCMKKeyVault
    workspaceCMKKeyVaultName: workspaceCMKKeyVaultName
  }
}

module workspaceResourceGroupTemplate './nested_workspaceResourceGroupTemplate.bicep' = {
  name: 'workspaceResourceGroupTemplate'
  scope: resourceGroup(workspaceResourceGroup)
  params: {
    reference_variables_primaryUserAssignedIdentity_2018_11_30_principalId: reference(primaryUserAssignedIdentity, '2018-11-30')
    variables_workspaceResourceGroupContributorRoleName: workspaceResourceGroupContributorRoleName
    variables_workspaceResourceGroup: workspaceResourceGroup_var
    variables_contributorRoleDefinition: contributorRoleDefinition
    assignWorkspaceResourceGroup: assignWorkspaceResourceGroup
  }
}