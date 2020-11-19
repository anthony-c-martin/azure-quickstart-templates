param existingVirtualMachineName string {
  metadata: {
    description: 'Existing SQL Server virtual machine name'
  }
}
param sqlCredentialName string {
  metadata: {
    description: 'SQL credential name to create on the SQL Server virtual machine'
  }
}
param sqlAkvUrl string {
  metadata: {
    description: 'Azure Key Vault URL'
  }
}
param servicePrincipalName string {
  metadata: {
    description: 'Azure Key Vault principal name or id'
  }
}
param servicePrincipalSecret string {
  metadata: {
    description: 'Azure Key Vault principal secret'
  }
  secure: true
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

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