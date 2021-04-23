@description('Location where the resources will be deployed.')
param location string = resourceGroup().location

@description('Do you want to create a public IP address for the source server?')
param createPublicIP bool = true

@description('Windows Authentication user name for the source server')
param sourceWindowsAdminUserName string

@description('Windows Authentication password for the source server')
@secure()
param sourceWindowsAdminPassword string

@description('Sql Authentication password for the source server (User name will be same as Windows Auth)')
@secure()
param sourceSqlAuthenticationPassword string

@description('Source VM size')
param vmSize string = 'Standard_DS4_v2'

@description('Administrator User name for the Target Azure SQL DB Server.')
param targetSqlDbAdministratorLogin string

@description('Administrator Password for the Target Azure SQL DB Server.')
@secure()
param targetSqlDbAdministratorPassword string

@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-azure-database-migration-service/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

var DMSServiceName_var = 'DMS${uniqueString(resourceGroup().id)}'
var sourceServerName_var = take('Source${uniqueString(resourceGroup().id)}', 15)
var targetServerName_var = 'targetservername${uniqueString(resourceGroup().id)}'
var scriptLocation = 'AddDatabaseToSqlServer.ps1'
var bakFileLocation = 'AdventureWorks2016.bak'
var scriptFiles = [
  uri(artifactsLocation, concat(scriptLocation, artifactsLocationSasToken))
  uri(artifactsLocation, concat(bakFileLocation, artifactsLocationSasToken))
]
var scriptParameters = '-userName ${sourceWindowsAdminUserName} -password "${sourceWindowsAdminPassword}'
var storageAccountNamePrefix = 'storage'
var storageAccountName_var = toLower(concat(storageAccountNamePrefix, uniqueString(resourceGroup().id)))
var sourceNicName_var = 'SourceNIC-1'
var publicIPSourceServer_var = 'SourceServer1-ip'
var sourceServerNSG_var = 'SourceServer1-nsg'
var adVNet_var = 'AzureDataMigrationServiceTemplateRG-vnet'
var defaultSubnetName = 'default'
var databaseName = 'TargetDatabaseName1'
var publicIpAddressId = {
  id: publicIPSourceServer.id
}

resource sourceServerName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: sourceServerName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftSQLServer'
        offer: 'SQL2016SP1-WS2016'
        sku: 'Standard'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: 127
      }
      dataDisks: [
        {
          lun: 0
          name: '${sourceServerName_var}_disk-1'
          createOption: 'Empty'
          caching: 'ReadOnly'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
          diskSizeGB: 1023
        }
      ]
    }
    osProfile: {
      computerName: sourceServerName_var
      adminUsername: sourceWindowsAdminUserName
      adminPassword: sourceWindowsAdminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: sourceNicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(storageAccountName_var, '2019-06-01').primaryEndpoints.blob
      }
    }
  }
}

resource sourceServerName_SqlIaasExtension 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  parent: sourceServerName
  name: 'SqlIaasExtension'
  location: location
  properties: {
    type: 'SqlIaaSAgent'
    publisher: 'Microsoft.SqlServer.Management'
    typeHandlerVersion: '1.2'
    autoUpgradeMinorVersion: 'true'
    settings: {
      AutoTelemetrySettings: {
        Region: location
      }
      AutoPatchingSettings: {
        PatchCategory: 'WindowsMandatoryUpdates'
        Enable: false
        DayOfWeek: 'Sunday'
        MaintenanceWindowStartingHour: '2'
        MaintenanceWindowDuration: '60'
      }
      KeyVaultCredentialSettings: {
        Enable: false
      }
      ServerConfigurationsManagementSettings: {
        SQLConnectivityUpdateSettings: {
          ConnectivityType: 'Private'
          Port: '1433'
        }
        SQLWorkloadTypeUpdateSettings: {
          SQLWorkloadType: 'OLTP'
        }
        SQLStorageUpdateSettings: {
          DiskCount: '1'
          NumberOfColumns: '8'
          StartingDeviceID: '2'
          DiskConfigurationType: 'NEW'
        }
        AdditionalFeaturesServerConfigurations: {
          IsRServicesEnabled: 'false'
        }
      }
    }
    protectedSettings: {
      SQLAuthUpdateUserName: sourceWindowsAdminUserName
      SQLAuthUpdatePassword: sourceSqlAuthenticationPassword
    }
  }
}

resource sourceServerName_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  parent: sourceServerName
  name: 'CustomScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: scriptFiles
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File ./${scriptLocation} ${scriptParameters}'
    }
  }
  dependsOn: [
    sourceServerName_SqlIaasExtension
  ]
}

resource DMSServiceName 'Microsoft.DataMigration/services@2018-07-15-preview' = {
  sku: {
    name: 'Standard_4vCores'
    tier: 'Standard'
    size: '4 vCores'
  }
  name: DMSServiceName_var
  location: location
  properties: {
    virtualSubnetId: adVNet_defaultSubnetName.id
  }
}

resource DMSServiceName_SqlToSqlDbMigrationProject 'Microsoft.DataMigration/services/projects@2018-07-15-preview' = {
  parent: DMSServiceName
  name: 'SqlToSqlDbMigrationProject'
  location: location
  properties: {
    sourcePlatform: 'SQL'
    targetPlatform: 'SQLDB'
  }
}

resource sourceNicName 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: sourceNicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: adVNet_defaultSubnetName.id
          }
          publicIPAddress: (createPublicIP ? publicIpAddressId : json('null'))
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
}

resource sourceServerNSG 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: sourceServerNSG_var
  location: location
  properties: {
    defaultSecurityRules: [
      {
        name: 'AllowVnetInBound'
        properties: {
          description: 'Allow inbound traffic from all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAzureLoadBalancerInBound'
        properties: {
          description: 'Allow inbound traffic from azure load balancer'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 65001
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          description: 'Deny all inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowVnetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowInternetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 65001
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny all outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource publicIPSourceServer 'Microsoft.Network/publicIPAddresses@2020-05-01' = if (createPublicIP) {
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  name: publicIPSourceServer_var
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Dynamic'
    idleTimeoutInMinutes: 4
  }
}

resource adVNet 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: adVNet_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/24'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.2.0.0/24'
        }
      }
    ]
    enableDdosProtection: false
    enableVmProtection: false
  }
}

resource adVNet_defaultSubnetName 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  parent: adVNet
  name: '${defaultSubnetName}'
  properties: {
    addressPrefix: '10.2.0.0/24'
  }
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  name: storageAccountName_var
  location: location
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: false
    encryption: {
      services: {
        file: {
          enabled: true
        }
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

resource targetServerName 'Microsoft.Sql/servers@2020-02-02-preview' = {
  name: concat(targetServerName_var)
  location: location
  properties: {
    administratorLogin: targetSqlDbAdministratorLogin
    administratorLoginPassword: targetSqlDbAdministratorPassword
    version: '12.0'
  }
}

resource targetServerName_databaseName 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  sku: {
    name: 'S3'
    tier: 'Standard'
  }
  name: '${targetServerName_var}/${databaseName}'
  location: location
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648
    zoneRedundant: false
  }
  dependsOn: [
    targetServerName
  ]
}

resource targetServerName_databaseName_Import 'Microsoft.Sql/servers/databases/extensions@2014-04-01' = {
  parent: targetServerName_databaseName
  name: 'Import'
  properties: {
    storageKey: artifactsLocationSasToken
    storageKeyType: 'SharedAccessKey'
    storageUri: uri(artifactsLocation, 'templatefiles/AdventureWorks2016.bacpac')
    administratorLogin: targetSqlDbAdministratorLogin
    administratorLoginPassword: targetSqlDbAdministratorPassword
    operationMode: 'Import'
  }
}

resource targetServerName_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallrules@2020-02-02-preview' = {
  name: '${targetServerName_var}/AllowAllWindowsAzureIps'
  location: location
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
  dependsOn: [
    targetServerName
  ]
}