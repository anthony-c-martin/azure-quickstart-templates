param vmName string {
  metadata: {
    description: 'This is the name of the Virtual Machine'
  }
}
param vmSize string {
  metadata: {
    description: 'This is the size of the Virtual Machine'
  }
  default: 'Standard_A0'
}
param imagePublisher string {
  metadata: {
    description: 'Image Publisher'
  }
  default: 'MicrosoftWindowsServer'
}
param imageOffer string {
  metadata: {
    description: 'Image Offer'
  }
  default: 'WindowsServer'
}
param imageSKU string {
  metadata: {
    description: 'Image SKU'
  }
  default: '2012-R2-Datacenter'
}
param adminUsername string {
  metadata: {
    description: 'This is the Virtual Machine administrator login name'
  }
}
param adminPassword string {
  metadata: {
    description: 'This is the Virtual Machine administrator login password'
  }
  secure: true
}
param dnsName string {
  metadata: {
    description: 'This is the DNS name of the Virtual Machine'
  }
}
param configurationFunction string {
  metadata: {
    description: 'This is the link to the Web Deploy package to be deployed to the Virtual Machine. It is a github URL in this example.'
  }
}
param DatabaseServerName string {
  metadata: {
    description: 'This is database server name'
  }
}
param DatabaseServerLocation string {
  metadata: {
    description: 'This is database server location'
  }
}
param databaseServerAdminLogin string {
  metadata: {
    description: 'This is database server administrator login name'
  }
}
param databaseServerAdminLoginPassword string {
  metadata: {
    description: 'This is database server administrator login password'
  }
  secure: true
}
param databaseName string {
  metadata: {
    description: 'This is name of the database hosted in the database server'
  }
}
param databaseCollation string {
  metadata: {
    description: 'This is database collation - rule for comparing the encodings in the database'
  }
  default: 'SQL_Latin1_General_CP1_CI_AS'
}
param databaseEdition string {
  allowed: [
    'Basic'
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'This is database edition'
  }
}
param modulesUrl string {
  metadata: {
    description: 'This is the URL for downloading the PowerShell DSC module. In this case it should be the link to a zip file hosted under an Azure storage container'
  }
}
param webdeploypkg string {
  metadata: {
    description: 'This is the link to the Web Deploy package for the website that\'s going to be deployed to the Virtual Machine'
  }
}

var virtualNetworkName = '${vmName}-VNET'
var vnetID = virtualNetworkName_resource.id
var nicName = '${vmName}-NIC'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet2Name = 'Subnet-2'
var subnet1Prefix = '10.0.0.0/24'
var subnet2Prefix = '10.0.1.0/24'
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var publicIPAddressName = '${vmName}-PublicIP-VM'
var storageAccountType = 'Standard_LRS'
var networkSecurityGroupName = 'default-NSG'

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: publicIPAddressName
  location: resourceGroup().location
  tags: {
    displayName: 'PublicIPAddress'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsName
    }
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'default-allow-80'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '80'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
  name: virtualNetworkName
  location: resourceGroup().location
  tags: {
    displayName: 'VirtualNetwork'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
          networkSecurityGroup: {
            id: networkSecurityGroupName_resource.id
          }
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2Prefix
        }
      }
    ]
  }
  dependsOn: [
    networkSecurityGroupName_resource
  ]
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: nicName
  location: resourceGroup().location
  tags: {
    displayName: 'NetworkInterface'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName_resource.id
          }
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
    virtualNetworkName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: resourceGroup().location
  tags: {
    displayName: 'VirtualMachine'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
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
          id: nicName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    nicName_resource
  ]
}

resource vmName_DSCExt1 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  name: '${vmName}/DSCExt1'
  location: resourceGroup().location
  tags: {
    displayName: 'DSCExt1'
  }
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: modulesUrl
      configurationFunction: 'ConfigureWebServer.ps1\\Main'
      properties: {
        MachineName: vmName
        WebDeployPackagePath: webdeploypkg
        UserName: adminUsername
        Password: adminPassword
        DbServerName: DatabaseServerName
        DbName: databaseName
        DbUserName: databaseServerAdminLogin
        DbPassword: databaseServerAdminLoginPassword
      }
    }
    protectedSettings: {}
  }
  dependsOn: [
    vmName_resource
  ]
}

resource DatabaseServerName_resource 'Microsoft.Sql/servers@2014-04-01-preview' = {
  name: DatabaseServerName
  location: DatabaseServerLocation
  tags: {
    displayName: DatabaseServerName
  }
  properties: {
    administratorLogin: databaseServerAdminLogin
    administratorLoginPassword: databaseServerAdminLoginPassword
  }
  dependsOn: []
}

resource DatabaseServerName_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallrules@2014-04-01-preview' = {
  name: '${DatabaseServerName}/AllowAllWindowsAzureIps'
  location: DatabaseServerLocation
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
  dependsOn: [
    DatabaseServerName_resource
  ]
}

resource DatabaseServerName_databaseName 'Microsoft.Sql/servers/databases@2014-04-01-preview' = {
  name: '${DatabaseServerName}/${databaseName}'
  location: DatabaseServerLocation
  tags: {
    displayName: 'cawadb1'
  }
  properties: {
    collation: databaseCollation
    edition: databaseEdition
    maxSizeBytes: '1073741824'
  }
  dependsOn: [
    DatabaseServerName_resource
  ]
}