param vmName string {
  metadata: {
    description: 'The name of the VM to create'
  }
  default: 'tfsvm'
}
param vmSize string {
  metadata: {
    description: 'The size of the VM to create'
  }
  default: 'Standard_DS2_v2'
}
param adminUsername string {
  metadata: {
    description: 'The name of the administrator account to create'
  }
}
param adminPassword string {
  metadata: {
    description: 'The password for the Administrator account'
  }
  secure: true
}
param domainName string {
  metadata: {
    description: 'The FQDN of the domain to create'
  }
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/tfs-basic-domain'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var publicIpName = 'tfsBasicPublicIp'
var vNetName = 'tfsBasicVNet'
var subnetName = 'tfsBasicSubnet'
var networkInterfaceName = '${vmName}nic'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', vNetName, subnetName)
var networkSecurityGroupName = 'default-NSG'

resource publicIpName_resource 'Microsoft.Network/publicIPAddresses@2017-09-01' = {
  name: publicIpName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName
  location: location
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

resource vNetName_resource 'Microsoft.Network/virtualNetworks@2017-09-01' = {
  name: vNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroupName_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    networkSecurityGroupName_resource
  ]
}

resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2017-09-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpName_resource.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIpName_resource
    vNetName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: location
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
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2016-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: 'tfsBasicManagedOSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
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

resource vmName_CreateDC 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = {
  name: '${vmName}/CreateDC'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: uri(artifactsLocation, 'DSC/CreateDC.ps1.zip${artifactsLocationSasToken}')
      ConfigurationFunction: 'CreateDC.ps1\\CreateDC'
      Properties: {
        DomainName: domainName
        AdminCreds: {
          UserName: adminUsername
          Password: 'PrivateSettingsRef:AdminPassword'
        }
      }
    }
    protectedSettings: {
      Items: {
        AdminPassword: adminPassword
      }
    }
  }
  dependsOn: [
    vmName_resource
  ]
}

resource vmName_ConfigureTfs 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = {
  name: '${vmName}/ConfigureTfs'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'scripts/ConfigureTfsBasic.ps1${artifactsLocationSasToken}')
      ]
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File ConfigureTfsBasic.ps1'
    }
  }
  dependsOn: [
    vmName_CreateDC
  ]
}