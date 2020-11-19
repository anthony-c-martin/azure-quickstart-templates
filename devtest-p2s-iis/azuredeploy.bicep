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
var newStorageAccount = '${uniqueString(resourceGroup().id)}store'
var storageAccountType = 'Standard_LRS'
var vnetName = '${environmentPrefix}Vnet'
var vnetAddressPrefix = '10.0.0.0/23'
var gatewaySubnetPrefix = '10.0.1.0/24'
var gatewayPublicIPName = '${environmentPrefix}GatewayPIP'
var gatewayName = '${environmentPrefix}Gateway'
var gatewaySku = 'Basic'
var gatewaySubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', vnetName, 'GatewaySubnet')
var appSubnetName = 'appSubnet'
var appSubnetPrefix = '10.0.0.0/24'
var appSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', vnetName, appSubnetName)
var nicName = '${environmentPrefix}NIC01'
var vmName = '${environmentPrefix}VM01'
var vmSize = 'Standard_D1'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var imageSKU = '2012-R2-Datacenter'
var vmExtensionName = 'dscExtension'
var modulesUrl = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/devtest-p2s-iis/DevTestWebsite.ps1.zip'
var configurationFunction = 'DevTestWebsite.ps1\\DevTestWebsite'

resource newStorageAccount_resource 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: newStorageAccount
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource gatewayPublicIPName_resource 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: gatewayPublicIPName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: vnetName
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

resource nicName_resource 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName
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
    vnetName_resource
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
    newStorageAccount_resource
    nicName_resource
  ]
}

resource vmName_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName}/${vmExtensionName}'
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
        MachineName: vmName
      }
    }
    protectedSettings: null
  }
  dependsOn: [
    vmName_resource
  ]
}

resource gatewayName_resource 'Microsoft.Network/virtualNetworkGateways@2015-06-15' = {
  name: gatewayName
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
            id: gatewayPublicIPName_resource.id
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
            PublicCertData: clientRootCertData
          }
        }
      ]
    }
  }
  dependsOn: [
    gatewayPublicIPName_resource
    vnetName_resource
  ]
}