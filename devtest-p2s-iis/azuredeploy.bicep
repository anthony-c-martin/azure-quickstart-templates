param environmentPrefix string {
  metadata: {
    description: 'Prefix to use for most of the resources.'
  }
  default: 'DevTest'
}
param adminUsername string {
  metadata: {
    description: 'Admin username'
  }
}
param adminPassword string {
  metadata: {
    description: 'Admin password'
  }
  secure: true
}
param vpnClientAddressPoolPrefix string {
  metadata: {
    description: 'The IP address range from which VPN clients will receive an IP address when connected. Range specified must not overlap with on-premise network.'
  }
  default: '10.10.8.0/24'
}
param clientRootCertName string {
  metadata: {
    description: 'The name of the client root certificate used to authenticate VPN clients. This is a common name used to identify the root cert.'
  }
}
param clientRootCertData string {
  metadata: {
    description: 'Client root certificate data used to authenticate VPN clients.'
  }
}

var location = resourceGroup().location
var newStorageAccount_var = '${uniqueString(resourceGroup().id)}store'
var storageAccountType = 'Standard_LRS'
var vnetName_var = '${environmentPrefix}Vnet'
var vnetAddressPrefix = '10.0.0.0/23'
var gatewaySubnetPrefix = '10.0.1.0/24'
var gatewayPublicIPName_var = '${environmentPrefix}GatewayPIP'
var gatewayName_var = '${environmentPrefix}Gateway'
var gatewaySku = 'Basic'
var gatewaySubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', vnetName_var, 'GatewaySubnet')
var appSubnetName = 'appSubnet'
var appSubnetPrefix = '10.0.0.0/24'
var appSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', vnetName_var, appSubnetName)
var nicName_var = '${environmentPrefix}NIC01'
var vmName_var = '${environmentPrefix}VM01'
var vmSize = 'Standard_D1'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var imageSKU = '2012-R2-Datacenter'
var vmExtensionName = 'dscExtension'
var modulesUrl = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/devtest-p2s-iis/DevTestWebsite.ps1.zip'
var configurationFunction = 'DevTestWebsite.ps1\\DevTestWebsite'

resource newStorageAccount 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: newStorageAccount_var
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource gatewayPublicIPName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: gatewayPublicIPName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource vnetName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: vnetName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gatewaySubnetPrefix
        }
      }
      {
        name: appSubnetName
        properties: {
          addressPrefix: appSubnetPrefix
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: appSubnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetName
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
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
        name: '${vmName_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName.id
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccount
  ]
}

resource vmName_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName_var}/${vmExtensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: modulesUrl
      ConfigurationFunction: configurationFunction
      Properties: {
        MachineName: vmName_var
      }
    }
    protectedSettings: null
  }
  dependsOn: [
    vmName
  ]
}

resource gatewayName 'Microsoft.Network/virtualNetworkGateways@2015-06-15' = {
  name: gatewayName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnetRef
          }
          publicIPAddress: {
            id: gatewayPublicIPName.id
          }
        }
        name: 'vnetGatewayConfig'
      }
    ]
    sku: {
      name: gatewaySku
      tier: gatewaySku
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: 'false'
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          vpnClientAddressPoolPrefix
        ]
      }
      vpnClientRootCertificates: [
        {
          name: clientRootCertName
          properties: {
            publicCertData: clientRootCertData
          }
        }
      ]
    }
  }
  dependsOn: [
    vnetName
  ]
}