param adminUsername string {
  minLength: 1
  metadata: {
    description: 'Username for the Virtual Machine.'
  }
}
param adminPassword string {
  metadata: {
    description: 'Password for the Virtual Machine.'
  }
  secure: true
}
param windowsOSVersion string {
  allowed: [
    '2012-R2-Datacenter'
    '2016-Datacenter'
  ]
  metadata: {
    description: 'The Windows version for the VM. This will pick a fully patched image of this given Windows version. Allowed values: 2012-R2-Datacenter, 2016-Datacenter.'
  }
  default: '2016-Datacenter'
}
param virtualMachineSize string {
  allowed: [
    'Standard_A1'
    'Standard_A2'
    'Standard_A3'
    'Standard_D1_v2'
    'Standard_D2_v2'
    'Standard_D3_v2'
  ]
  metadata: {
    description: 'The virtual machine size. Allowed values: Standard_A1, Standard_A2, Standard_A3.'
  }
  default: 'Standard_D2_v2'
}
param applicationGatewaySize string {
  allowed: [
    'WAF_Medium'
    'WAF_Large'
  ]
  metadata: {
    description: 'Application Gateway size'
  }
  default: 'WAF_Medium'
}
param capacity int {
  allowed: [
    1
    2
    3
    4
    5
    6
    7
    8
    9
    10
  ]
  metadata: {
    description: 'Number of instances'
  }
  default: 2
}
param wafMode string {
  allowed: [
    'Detection'
    'Prevention'
  ]
  metadata: {
    description: 'WAF Mode'
  }
  default: 'Prevention'
}
param frontendCertData string {
  metadata: {
    description: 'Base-64 encoded form of the .pfx file. This is the cert terminating on the Application Gateway.'
  }
}
param frontendCertPassword string {
  metadata: {
    description: 'Password for .pfx certificate'
  }
  secure: true
}
param backendCertData string {
  metadata: {
    description: 'Base-64 encoded form of the .pfx file. This is the cert installed on the web servers.'
  }
}
param backendCertPassword string {
  metadata: {
    description: 'Password for .pfx certificate'
  }
  secure: true
}
param backendPublicKeyData string {
  metadata: {
    description: 'Base-64 encoded form of the .cer file. This is the public key for the cert on the web servers.'
  }
}
param backendCertDnsName string {
  metadata: {
    description: 'DNS name of the backend cert'
  }
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. For example, if stored on a public GitHub repo, you\'d use the following URI: https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vmss-windows-webapp-dsc-autoscale.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-application-gateway-2vms-iis-ssl'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  If your artifacts are stored on a public repo or public storage account you can leave this blank.'
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

var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var vm1NicName_var = 'vm1Nic'
var vm2NicName_var = 'vm2Nic'
var addressPrefix = '10.0.0.0/16'
var webSubnetName = 'WebSubnet'
var webSubnetPrefix = '10.0.0.0/24'
var appGatewaySubnetName = 'AppGatewaySubnet'
var appGatewaySubnetPrefix = '10.0.1.0/24'
var vm1PublicIPAddressName_var = 'vm1PublicIP'
var vm1PublicIPAddressType = 'Dynamic'
var vm2PublicIPAddressName_var = 'vm2PublicIP'
var vm2PublicIPAddressType = 'Dynamic'
var vm1IpAddress = '10.0.0.4'
var vm2IpAddress = '10.0.0.5'
var vm1Name_var = 'iisvm1'
var vm2Name_var = 'iisvm2'
var vmSize = virtualMachineSize
var virtualNetworkName_var = 'MyVNet'
var webSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, webSubnetName)
var webAvailabilitySetName_var = 'IISAvailabilitySet'
var webNsgName_var = 'WebNSG'
var appGwNsgName_var = 'AppGwNSG'
var applicationGatewayName_var = 'ApplicationGateway'
var appGwPublicIpName_var = 'ApplicationGatewayPublicIp'
var appGatewaySubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, appGatewaySubnetName)
var appGwPublicIPRef = appGwPublicIpName.id
var wafEnabled = true
var wafMode_var = wafMode
var wafRuleSetType = 'OWASP'
var wafRuleSetVersion = '3.0'
var applicationGatewayID = applicationGatewayName.id
var dscZipFullPath = '${artifactsLocation}/DSC/iisInstall.ps1.zip${artifactsLocationSasToken}'
var webConfigFullPath = '${artifactsLocation}/artifacts/web.config${artifactsLocationSasToken}'
var vm1DefaultHtmFullPath = '${artifactsLocation}/artifacts/vm1.default.htm${artifactsLocationSasToken}'
var vm2DefaultHtmFullPath = '${artifactsLocation}/artifacts/vm2.default.htm${artifactsLocationSasToken}'

resource webAvailabilitySetName 'Microsoft.Compute/availabilitySets@2016-04-30-preview' = {
  sku: {
    name: 'Aligned'
  }
  name: webAvailabilitySetName_var
  location: location
  properties: {
    platformUpdateDomainCount: 5
    platformFaultDomainCount: 2
    virtualMachines: [
      {
        id: vm1Name.id
      }
      {
        id: vm2Name.id
      }
    ]
  }
}

resource vm1PublicIPAddressName 'Microsoft.Network/publicIPAddresses@2016-03-30' = {
  name: vm1PublicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: vm1PublicIPAddressType
  }
}

resource vm2PublicIPAddressName 'Microsoft.Network/publicIPAddresses@2016-03-30' = {
  name: vm2PublicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: vm2PublicIPAddressType
  }
}

resource appGwPublicIpName 'Microsoft.Network/publicIPAddresses@2017-03-01' = {
  name: appGwPublicIpName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource webNsgName 'Microsoft.Network/networkSecurityGroups@2016-03-30' = {
  name: webNsgName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow80'
        properties: {
          description: 'Allow 80 from local VNet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow443'
        properties: {
          description: 'Allow 443 from local VNet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowRDP'
        properties: {
          description: 'Allow RDP from everywhere'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 102
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource appGwNsgName 'Microsoft.Network/networkSecurityGroups@2016-03-30' = {
  name: appGwNsgName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow80'
        properties: {
          description: 'Allow 80 from Internet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow443'
        properties: {
          description: 'Allow 443 from Internet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 102
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAppGwProbes'
        properties: {
          description: 'Allow ports for App Gw probes'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '65503-65534 '
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 103
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2016-03-30' = {
  name: virtualNetworkName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: webSubnetName
        properties: {
          addressPrefix: webSubnetPrefix
          networkSecurityGroup: {
            id: webNsgName.id
          }
        }
      }
      {
        name: appGatewaySubnetName
        properties: {
          addressPrefix: appGatewaySubnetPrefix
          networkSecurityGroup: {
            id: appGwNsgName.id
          }
        }
      }
    ]
  }
}

resource vm1NicName 'Microsoft.Network/networkInterfaces@2016-03-30' = {
  name: vm1NicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfigVm1'
        properties: {
          privateIPAddress: vm1IpAddress
          privateIPAllocationMethod: 'Static'
          publicIPAddress: {
            id: vm1PublicIPAddressName.id
          }
          subnet: {
            id: webSubnetRef
          }
        }
      }
    ]
  }
}

resource vm2NicName 'Microsoft.Network/networkInterfaces@2016-03-30' = {
  name: vm2NicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfigVm2'
        properties: {
          privateIPAddress: vm2IpAddress
          privateIPAllocationMethod: 'Static'
          publicIPAddress: {
            id: vm2PublicIPAddressName.id
          }
          subnet: {
            id: webSubnetRef
          }
        }
      }
    ]
  }
}

resource vm1Name 'Microsoft.Compute/virtualMachines@2016-04-30-preview' = {
  name: vm1Name_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vm1Name_var
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        name: vm1Name_var
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vm1NicName.id
        }
      ]
    }
  }
}

resource vm1Name_Microsoft_Powershell_DSC 'Microsoft.Compute/virtualMachines/extensions@2016-04-30-preview' = {
  name: '${vm1Name_var}/Microsoft.Powershell.DSC'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.9'
    autoUpgradeMinorVersion: true
    forceUpdateTag: '1.0'
    settings: {
      configuration: {
        url: dscZipFullPath
        script: 'iisInstall.ps1'
        function: 'InstallIIS'
      }
      configurationArguments: {
        nodeName: vm1Name_var
        vmNumber: 'vm1'
        backendCert: backendCertData
        backendCertPw: backendCertPassword
        backendCertDnsName: backendCertDnsName
        webConfigPath: webConfigFullPath
        defaultHtmPath: vm1DefaultHtmFullPath
      }
    }
    protectedSettings: {}
  }
}

resource vm2Name 'Microsoft.Compute/virtualMachines@2016-04-30-preview' = {
  name: vm2Name_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vm2Name_var
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        name: vm2Name_var
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vm2NicName.id
        }
      ]
    }
  }
}

resource vm2Name_Microsoft_Powershell_DSC 'Microsoft.Compute/virtualMachines/extensions@2016-04-30-preview' = {
  name: '${vm2Name_var}/Microsoft.Powershell.DSC'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.9'
    autoUpgradeMinorVersion: true
    forceUpdateTag: '1.0'
    settings: {
      configuration: {
        url: dscZipFullPath
        script: 'iisInstall.ps1'
        function: 'InstallIIS'
      }
      configurationArguments: {
        nodeName: vm2Name_var
        vmNumber: 'vm2'
        backendCert: backendCertData
        backendCertPw: backendCertPassword
        backendCertDnsName: backendCertDnsName
        webConfigPath: webConfigFullPath
        defaultHtmPath: vm2DefaultHtmFullPath
      }
    }
    protectedSettings: {}
  }
}

resource applicationGatewayName 'Microsoft.Network/applicationGateways@2017-06-01' = {
  name: applicationGatewayName_var
  location: location
  properties: {
    sku: {
      name: applicationGatewaySize
      tier: 'WAF'
      capacity: capacity
    }
    sslCertificates: [
      {
        name: 'appGatewayFrontEndSslCert'
        properties: {
          data: frontendCertData
          password: frontendCertPassword
        }
      }
    ]
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: appGatewaySubnetRef
          }
        }
      }
    ]
    authenticationCertificates: [
      {
        properties: {
          data: backendPublicKeyData
        }
        name: 'appGatewayBackendCert'
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: appGwPublicIPRef
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort80'
        properties: {
          port: 80
        }
      }
      {
        name: 'appGatewayFrontendPort443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          backendAddresses: [
            {
              ipAddress: vm1IpAddress
            }
            {
              ipAddress: vm2IpAddress
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
        }
      }
      {
        name: 'appGatewayBackendHttpsSettings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          authenticationCertificates: [
            {
              id: '${applicationGatewayID}/authenticationCertificates/appGatewayBackendCert'
            }
          ]
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: '${applicationGatewayID}/frontendIPConfigurations/appGatewayFrontendIP'
          }
          frontendPort: {
            id: '${applicationGatewayID}/frontendPorts/appGatewayFrontendPort80'
          }
          protocol: 'Http'
          sslCertificate: null
        }
      }
      {
        name: 'appGatewayHttpsListener'
        properties: {
          frontendIPConfiguration: {
            id: '${applicationGatewayID}/frontendIPConfigurations/appGatewayFrontendIP'
          }
          frontendPort: {
            id: '${applicationGatewayID}/frontendPorts/appGatewayFrontendPort443'
          }
          protocol: 'Https'
          sslCertificate: {
            id: '${applicationGatewayID}/sslCertificates/appGatewayFrontEndSslCert'
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'HTTPRule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: '${applicationGatewayID}/httpListeners/appGatewayHttpListener'
          }
          backendAddressPool: {
            id: '${applicationGatewayID}/backendAddressPools/appGatewayBackendPool'
          }
          backendHttpSettings: {
            id: '${applicationGatewayID}/backendHttpSettingsCollection/appGatewayBackendHttpSettings'
          }
        }
      }
      {
        name: 'HTTPSRule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: '${applicationGatewayID}/httpListeners/appGatewayHttpsListener'
          }
          backendAddressPool: {
            id: '${applicationGatewayID}/backendAddressPools/appGatewayBackendPool'
          }
          backendHttpSettings: {
            id: '${applicationGatewayID}/backendHttpSettingsCollection/appGatewayBackendHttpsSettings'
          }
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: wafEnabled
      firewallMode: wafMode_var
      ruleSetType: wafRuleSetType
      ruleSetVersion: wafRuleSetVersion
      disabledRuleGroups: []
    }
  }
}