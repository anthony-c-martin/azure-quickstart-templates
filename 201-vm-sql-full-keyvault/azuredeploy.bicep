param virtualMachineName string {
  metadata: {
    description: 'SQL Server Virtual Machine Name'
  }
}
param virtualMachineSize string {
  allowed: [
    'Standard_DS1'
    'Standard_DS2'
    'Standard_DS3'
    'Standard_DS4'
    'Standard_DS11'
    'Standard_DS12'
    'Standard_DS13'
    'Standard_DS14'
  ]
  metadata: {
    description: 'SQL Server Virtual Machine Size'
  }
  default: 'Standard_DS4'
}
param adminUsername string {
  metadata: {
    description: 'SQL Server Virtual Machine Administrator User Name'
  }
}
param adminPassword string {
  metadata: {
    description: 'SQL Server Virtual Machine Administrator Password'
  }
  secure: true
}
param storageAccountType string {
  allowed: [
    'Premium_LRS'
    'Standard_LRS'
  ]
  metadata: {
    description: 'SQL Server Virtual Machine Storage Account Type'
  }
  default: 'Premium_LRS'
}
param virtualNetworkName string {
  metadata: {
    description: 'SQL Server Virtual Machine Virtual Network Name'
  }
}
param networkInterfaceName string {
  metadata: {
    description: 'SQL Server Virtual Machine Network Interface Name'
  }
}
param networkSecurityGroupName string {
  metadata: {
    description: 'SQL Server Virtual Machine Network Security Group Name'
  }
}
param addressPrefix string {
  metadata: {
    description: 'SQL Server Virtual Machine Subnet Name'
  }
  default: '10.0.0.0/16'
}
param subnetName string {
  metadata: {
    description: 'SQL Server Virtual Machine Subnet Name'
  }
  default: 'default'
}
param subnetPrefix string {
  metadata: {
    description: 'SQL Server Virtual Machine Subnet Name'
  }
  default: '10.0.0.0/24'
}
param publicIpAddressName string {
  metadata: {
    description: 'SQL Server Virtual Machine Public IP Address Name'
  }
}
param publicIpAddressType string {
  metadata: {
    description: 'SQL Server Virtual Machine Public IP Address Type'
  }
  default: 'Dynamic'
}
param sqlConnectivityType string {
  metadata: {
    description: 'SQL Server Virtual Machine SQL Connectivity Type'
  }
  default: 'Public'
}
param sqlPortNumber int {
  metadata: {
    description: 'SQL Server Virtual Machine SQL Port Number'
  }
  default: 1579
}
param sqlStorageDisksCount int {
  metadata: {
    description: 'SQL Server Virtual Machine Data Disk Count'
  }
  default: '2'
}
param sqlStorageWorkloadType string {
  allowed: [
    'GENERAL'
    'OLTP'
    'DW'
  ]
  metadata: {
    description: 'SQL Server Virtual Machine Workload Type: GENERAL - general work load; DW - datawear house work load; OLTP - Transactional processing work load'
  }
  default: 'General'
}
param sqlAkvCredentialName string {
  metadata: {
    description: 'SQL credential name to create on the SQL Server virtual machine'
  }
}
param sqlAkvUrl string {
  metadata: {
    description: 'Azure Key Vault URL'
  }
}
param sqlAkvPrincipalName string {
  metadata: {
    description: 'Azure Key Vault principal name or id'
  }
}
param sqlAkvPrincipalSecret string {
  metadata: {
    description: 'Azure Key Vault principal secret'
  }
  secure: true
}
param sqlAuthenticationLogin string {
  metadata: {
    description: 'SQL Server Authentication Login Account Name'
  }
  default: 'mysa'
}
param sqlAuthenticationPassword string {
  metadata: {
    description: 'SQL Server Authentication Login Account Password'
  }
  secure: true
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-sql-full-keyvault/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}

var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)

resource virtualMachineName_resource 'Microsoft.Compute/virtualMachines@2019-03-01' = {
  name: virtualMachineName
  location: location
  properties: {
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVmAgent: 'true'
      }
    }
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftSQLServer'
        offer: 'sql2014sp3-ws2012r2'
        sku: 'Enterprise'
        version: 'latest'
      }
      osDisk: {
        name: '${virtualMachineName}_OSDisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageAccountType
        }
      }
      dataDisks: [
        {
          name: '${virtualMachineName}_DataDisk-1'
          createOption: 'Empty'
          lun: 0
          diskSizeGB: 1023
          caching: 'ReadOnly'
        }
        {
          name: '${virtualMachineName}_DataDisk-2'
          createOption: 'Empty'
          lun: 1
          diskSizeGB: 1023
          caching: 'ReadOnly'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    networkInterfaceName_resource
  ]
}

resource virtualMachineName_SqlIaasExtension 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = {
  name: '${virtualMachineName}/SqlIaasExtension'
  location: location
  properties: {
    type: 'SqlIaaSAgent'
    publisher: 'Microsoft.SqlServer.Management'
    typeHandlerVersion: '1.2'
    autoUpgradeMinorVersion: true
    settings: {
      AutoTelemetrySettings: {
        Region: location
      }
      KeyVaultCredentialSettings: {
        Enable: true
        CredentialName: sqlAkvCredentialName
      }
    }
    protectedSettings: {
      PrivateKeyVaultCredentialSettings: {
        AzureKeyVaultUrl: sqlAkvUrl
        ServicePrincipalName: sqlAkvPrincipalName
        ServicePrincipalSecret: sqlAkvPrincipalSecret
      }
    }
  }
  dependsOn: [
    virtualMachineName_resource
  ]
}

module prepareSqlVmDeployment '<failed to parse [uri(parameters(\'_artifactsLocation\'), concat(\'nested/preparingSqlServerSa.json\', parameters(\'_artifactsLocationSasToken\')))]>' = {
  name: 'prepareSqlVmDeployment'
  params: {
    sqlVMName: virtualMachineName
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
    sqlUsername: sqlAuthenticationLogin
    sqlPassword: sqlAuthenticationPassword
    disksCount: sqlStorageDisksCount
    diskSizeInGB: 1023
    sqlEnginePort: sqlPortNumber
    workloadType: sqlStorageWorkloadType
    connectionType: sqlConnectivityType
    sqlVMPrepareModulesURL: uri(artifactsLocation, 'scripts/PrepareSqlServer.ps1.zip${artifactsLocationSasToken}')
    sqlVMPrepareConfigurationFunction: 'PrepareSqlServerSa.ps1\\PrepareSqlServerSa'
  }
  dependsOn: [
    virtualMachineName_SqlIaasExtension
  ]
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2019-06-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIpAddress: {
            id: publicIpAddressName_resource.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroupName_resource.id
    }
  }
  dependsOn: [
    virtualNetworkName_resource
    publicIpAddressName_resource
    networkSecurityGroupName_resource
  ]
}

resource publicIpAddressName_resource 'Microsoft.Network/publicIPAddresses@2019-06-01' = {
  name: publicIpAddressName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: publicIpAddressType
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-06-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-rdp'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '3389'
          access: 'Allow'
          direction: 'inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-sql'
        properties: {
          priority: 1500
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '1433'
          access: 'Allow'
          direction: 'inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

output adminUsername_output string = adminUsername