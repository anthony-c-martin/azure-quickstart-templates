param variables_managedResourceGroupName ? /* TODO: fill in correct type */

@description('The name of the Azure Databricks workspace to create.')
param workspaceName string

@description('Location for all resources.')
param location string

@allowed([
  'standard'
  'premium'
])
@description('The pricing tier of workspace.')
param pricingTier string

@description('The Azure Key Vault name.')
param keyVaultName string

@description('The Azure Key Vault encryption key name.')
param keyName string

@description('Specifies whether to deploy Azure Databricks workspace with Secure Cluster Connectivity (No Public IP) enabled or not')
param disablePublicIp bool

resource workspaceName_resource 'Microsoft.Databricks/workspaces@2018-04-01' = {
  name: workspaceName
  location: location
  sku: {
    name: pricingTier
  }
  properties: {
    managedResourceGroupId: subscriptionResourceId('Microsoft.Resources/resourceGroups', variables_managedResourceGroupName)
    parameters: {
      prepareEncryption: {
        value: true
      }
      encryption: {
        value: {
          keySource: 'Microsoft.Keyvault'
          keyvaulturi: 'https://${keyVaultName}${environment().suffixes.keyvaultDns}'
          KeyName: keyName
        }
      }
      enableNoPublicIp: {
        value: disablePublicIp
      }
    }
  }
}