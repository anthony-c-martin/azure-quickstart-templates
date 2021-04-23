@description('Existing SQL Server virtual machine name')
param existingVirtualMachineName string

@description('SQL credential name to create on the SQL Server virtual machine')
param sqlCredentialName string

@description('Azure Key Vault URL')
param sqlAkvUrl string

@description('Azure Key Vault principal name or id')
param servicePrincipalName string

@description('Azure Key Vault principal secret')
@secure()
param servicePrincipalSecret string

@description('Location for all resources.')
param location string = resourceGroup().location

resource existingVirtualMachineName_SqlIaasExtension 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${existingVirtualMachineName}/SqlIaasExtension'
  location: location
  properties: {
    type: 'SqlIaaSAgent'
    publisher: 'Microsoft.SqlServer.Management'
    typeHandlerVersion: '1.2'
    autoUpgradeMinorVersion: 'true'
    settings: {
      KeyVaultCredentialSettings: {
        Enable: true
        CredentialName: sqlCredentialName
      }
    }
    protectedSettings: {
      PrivateKeyVaultCredentialSettings: {
        AzureKeyVaultUrl: sqlAkvUrl
        ServicePrincipalName: servicePrincipalName
        ServicePrincipalSecret: servicePrincipalSecret
      }
    }
  }
}