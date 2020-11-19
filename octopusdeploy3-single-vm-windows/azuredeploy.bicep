param vmAdminUsername string {
  metadata: {
    description: 'Admin username for the Octopus Deploy Virtual Machine.'
  }
  default: 'octoadmin'
}
param vmAdminPassword string {
  metadata: {
    description: 'Admin password for the Octopus Deploy Virtual Machine.'
  }
  secure: true
}
param networkDnsName string {
  metadata: {
    description: 'Unique DNS Name used to access the Octopus Deploy server via HTTP or RDP.'
  }
}
param sqlServerName string {
  metadata: {
    description: 'Unique DNS Name for the SQL DB Server that will hold the Octopus Deploy data.'
  }
}
param sqlAdminUsername string {
  metadata: {
    description: 'Admin username for the Octopus Deploy SQL DB Server.'
  }
  default: 'sqladmin'
}
param sqlAdminPassword string {
  metadata: {
    description: 'Admin password for the Octopus Deploy SQL DB Server.'
  }
  secure: true
}
param licenseFullName string {
  metadata: {
    description: 'Octopus Deploy Trial license - provide Full Name.'
  }
}
param licenseOrganisationName string {
  metadata: {
    description: 'Octopus Deploy Trial license - provide Organisation Name.'
  }
}
param licenseEmailAddress string {
  metadata: {
    description: 'Octopus Deploy Trial license - provide Email Address.'
  }
}
param octopusAdminUsername string {
  metadata: {
    description: 'Admin username for the Octopus Deploy web application.'
  }
  default: 'admin'
}
param octopusAdminPassword string {
  metadata: {
    description: 'Admin password for the Octopus Deploy web application.'
  }
  secure: true
}

var storageAccountName = '${uniqueString(resourceGroup().id)}storage'
var vmImagePublisher = 'MicrosoftWindowsServer'
var vmImageOffer = 'WindowsServer'
var vmOSDiskName = 'osdiskforwindowssimple'
var vmWindowsOSVersion = '2012-R2-Datacenter'
var vmStorageAccountType = 'Standard_LRS'
var vmStorageAccountContainerName = 'vhds'
var vmName = 'OctopusDeploy'
var vmSize = 'Standard_D2'
var networkNicName = 'OctopusDeployNIC'
var networkAddressPrefix = '10.0.0.0/16'
var networkSubnetName = 'OctopusDeploySubnet'
var networkSubnetPrefix = '10.0.0.0/24'
var networkPublicIPAddressName = 'OctopusDeployPublicIP'
var networkPublicIPAddressType = 'Dynamic'
var networkVNetName = 'OctopusDeployVNET'
var networkSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', networkVNetName, networkSubnetName)
var sqlDbName = 'OctopusDeploy'
var sqlDbEdition = 'Standard'
var sqlDbCollation = 'SQL_Latin1_General_CP1_CI_AS'
var sqlDbMaxSizeBytes = '268435456000'
var sqldbEditionPerformanceLevel = '1B1EBD4D-D903-4BAA-97F9-4EA675F5E928'
var sqlDbConnectionString = 'Data Source=tcp:${sqlServerName}.database.windows.net,1433;Database=${sqlDbName};User Id=${sqlAdminUsername}@${sqlServerName};Password=${sqlAdminPassword};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
var installerUri = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/octopusdeploy3-single-vm-windows/Install-OctopusDeploy.ps1'
var installerCommand = 'powershell.exe -File Install-OctopusDeploy.ps1 ${base64(sqlDbConnectionString)} ${base64(licenseFullName)} ${base64(licenseOrganisationName)} ${base64(licenseEmailAddress)} ${base64(octopusAdminUsername)} ${base64(octopusAdminPassword)} 2>&1 > D:\\Install-OctopusDeploy.ps1.log '

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-05-01-preview' = {
  name: storageAccountName
  location: resourceGroup().location
  tags: {
    env: 'trial'
    vendor: 'Octopus Deploy'
  }
  properties: {
    accountType: vmStorageAccountType
  }
}

resource networkPublicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: networkPublicIPAddressName
  location: resourceGroup().location
  tags: {
    env: 'trial'
    vendor: 'Octopus Deploy'
  }
  properties: {
    publicIPAllocationMethod: networkPublicIPAddressType
    dnsSettings: {
      domainNameLabel: networkDnsName
    }
  }
}

resource networkVNetName_resource 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
  name: networkVNetName
  location: resourceGroup().location
  tags: {
    env: 'trial'
    vendor: 'Octopus Deploy'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        networkAddressPrefix
      ]
    }
    subnets: [
      {
        name: networkSubnetName
        properties: {
          addressPrefix: networkSubnetPrefix
        }
      }
    ]
  }
}

resource networkNicName_resource 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: networkNicName
  location: resourceGroup().location
  tags: {
    env: 'trial'
    vendor: 'Octopus Deploy'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: networkPublicIPAddressName_resource.id
          }
          subnet: {
            id: networkSubnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    networkPublicIPAddressName_resource
    networkVNetName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: resourceGroup().location
  tags: {
    env: 'trial'
    vendor: 'Octopus Deploy'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: vmImagePublisher
        offer: vmImageOffer
        sku: vmWindowsOSVersion
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkNicName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    storageAccountName_resource
    networkNicName_resource
  ]
}

resource vmName_OctopusDeployInstaller 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  name: '${vmName}/OctopusDeployInstaller'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: 'true'
    settings: {
      fileUris: [
        installerUri
      ]
      commandToExecute: installerCommand
    }
  }
  dependsOn: [
    vmName_resource
    sqlServerName_sqlDbName
  ]
}

resource sqlServerName_resource 'Microsoft.Sql/servers@2014-04-01-preview' = {
  name: sqlServerName
  location: resourceGroup().location
  tags: {
    env: 'trial'
    vendor: 'Octopus Deploy'
  }
  properties: {
    version: '12.0'
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
  }
}

resource sqlServerName_sqlDbName 'Microsoft.Sql/servers/databases@2014-04-01-preview' = {
  name: '${sqlServerName}/${sqlDbName}'
  location: resourceGroup().location
  tags: {
    env: 'trial'
    vendor: 'Octopus Deploy'
  }
  properties: {
    edition: sqlDbEdition
    collation: sqlDbCollation
    maxSizeBytes: sqlDbMaxSizeBytes
    requestedServiceObjectiveId: sqldbEditionPerformanceLevel
  }
  dependsOn: [
    sqlServerName_resource
  ]
}

resource sqlServerName_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallrules@2014-04-01-preview' = {
  location: resourceGroup().location
  name: '${sqlServerName}/AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
  dependsOn: [
    sqlServerName_resource
  ]
}

output octopusServerName string = reference(networkPublicIPAddressName).dnsSettings.fqdn
output sqlServerName_output string = reference('Microsoft.Sql/servers/${sqlServerName}').fullyQualifiedDomainName