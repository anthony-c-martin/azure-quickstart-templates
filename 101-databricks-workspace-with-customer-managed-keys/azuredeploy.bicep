@description('Specifies whether to deploy Azure Databricks workspace with Secure Cluster Connectivity (No Public IP) enabled or not')
param disablePublicIp bool = false

@description('The name of the Azure Databricks workspace to create.')
param workspaceName string = 'ws${uniqueString(resourceGroup().id)}'

@description('The Azure Key Vault name.')
param keyVaultName string

@description('The Azure Key Vault encryption key name.')
param keyName string

@description('The Azure Key Vault resource group name.')
param keyVaultResourceGroupName string

@allowed([
  'standard'
  'premium'
])
@description('The pricing tier of workspace.')
param pricingTier string = 'premium'

@description('Location for all resources.')
param location string = resourceGroup().location

var managedResourceGroupName = 'databricks-rg-${workspaceName}-${uniqueString(workspaceName, resourceGroup().id)}'

resource workspaceName_resource 'Microsoft.Databricks/workspaces@2018-04-01' = {
  name: workspaceName
  location: location
  sku: {
    name: pricingTier
  }
  properties: {
    managedResourceGroupId: subscriptionResourceId('Microsoft.Resources/resourceGroups', managedResourceGroupName)
    parameters: {
      prepareEncryption: {
        value: true
      }
    }
  }
}

module addAccessPolicy './nested_addAccessPolicy.bicep' = {
  name: 'addAccessPolicy'
  scope: resourceGroup(keyVaultResourceGroupName)
  params: {
    resourceId_Microsoft_Databricks_workspaces_parameters_workspaceName: reference(workspaceName_resource.id, '2018-04-01')
    keyVaultName: keyVaultName
  }
}

module configureCMKOnWorkspace './nested_configureCMKOnWorkspace.bicep' = {
  name: 'configureCMKOnWorkspace'
  params: {
    variables_managedResourceGroupName: managedResourceGroupName
    workspaceName: workspaceName
    location: location
    pricingTier: pricingTier
    keyVaultName: keyVaultName
    keyName: keyName
    disablePublicIp: disablePublicIp
  }
  dependsOn: [
    addAccessPolicy
  ]
}

output workspace object = workspaceName_resource.properties