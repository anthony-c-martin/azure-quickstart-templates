@minLength(1)
@description('Username for the Virtual Machines.')
param adminUsername string

@description('Password for the Virtual Machines.')
@secure()
param adminPassword string

@description('description')
param vmSize string = 'Standard_D3_v2'

@description('Location for all resources.')
param location string = resourceGroup().location

var NSGName_var = 'myVNetNSG'
var VM01Name_var = 'IIS01'
var VM02Name_var = 'AppVM01'
var VM03Name_var = 'AppVM02'
var VM04Name_var = 'DNS01'
var VNetName_var = 'VNet01'
var Subnet1Name = 'FrontEnd'
var Subnet1Prefix = '10.0.1.0/24'
var Subnet2Name = 'BackEnd'
var Subnet2Prefix = '10.0.2.0/24'
var NIC01SubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', VNetName_var, Subnet1Name)
var NIC02SubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', VNetName_var, Subnet2Name)
var NIC03SubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', VNetName_var, Subnet2Name)
var NIC04SubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', VNetName_var, Subnet2Name)
var imageOffer = 'WindowsServer'
var imagePublisher = 'MicrosoftWindowsServer'
var windowsOSVersion = '2019-Datacenter'

resource VNetName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: VNetName_var
  location: location
  tags: {
    displayName: 'VNet01'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        Subnet1Prefix
        Subnet2Prefix
      ]
    }
    subnets: [
      {
        name: Subnet1Name
        properties: {
          addressPrefix: Subnet1Prefix
          networkSecurityGroup: {
            id: NSGName.id
          }
        }
      }
      {
        name: Subnet2Name
        properties: {
          addressPrefix: Subnet2Prefix
          networkSecurityGroup: {
            id: NSGName.id
          }
        }
      }
    ]
  }
  dependsOn: [
    VM01Name_NIC_PIP
  ]
}

resource VM01Name_NIC_PIP 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: '${VM01Name_var}_NIC_PIP'
  location: location
  tags: {
    displayName: 'IIS01 NIC PIP'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    idleTimeoutInMinutes: 4
  }
}

resource VM01Name_NIC 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: '${VM01Name_var}_NIC'
  location: location
  tags: {
    displayName: 'IIS01 NIC'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.1.5'
          publicIPAddress: {
            id: VM01Name_NIC_PIP.id
          }
          subnet: {
            id: NIC01SubnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    VNetName
  ]
}

resource VM02Name_NIC 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: '${VM02Name_var}_NIC'
  location: location
  tags: {
    displayName: 'AppVM01 NIC'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.2.5'
          subnet: {
            id: NIC02SubnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    VNetName
  ]
}

resource VM03Name_NIC 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: '${VM03Name_var}_NIC'
  location: location
  tags: {
    displayName: 'AppVM02 NIC'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.2.6'
          subnet: {
            id: NIC03SubnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    VNetName
  ]
}

resource VM04Name_NIC 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: '${VM04Name_var}_NIC'
  location: location
  tags: {
    displayName: 'DNS01 NIC'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.2.4'
          subnet: {
            id: NIC04SubnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    VNetName
  ]
}

resource VM01Name 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: VM01Name_var
  location: location
  tags: {
    displayName: 'IIS01'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: VM01Name_var
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
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary: true
          }
          id: VM01Name_NIC.id
        }
      ]
    }
  }
}

resource VM02Name 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: VM02Name_var
  location: location
  tags: {
    displayName: 'AppVM01'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: VM02Name_var
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
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary: true
          }
          id: VM02Name_NIC.id
        }
      ]
    }
  }
}

resource VM03Name 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: VM03Name_var
  location: location
  tags: {
    displayName: 'AppVM02'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: VM03Name_var
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
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary: true
          }
          id: VM03Name_NIC.id
        }
      ]
    }
  }
}

resource VM04Name 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: VM04Name_var
  location: location
  tags: {
    displayName: 'DNS01'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: VM04Name_var
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
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary: true
          }
          id: VM04Name_NIC.id
        }
      ]
    }
  }
}

resource NSGName 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: NSGName_var
  location: location
  tags: {
    displayName: 'myVNetNSG'
  }
  properties: {
    securityRules: [
      {
        name: 'enable_dns_rule'
        properties: {
          description: 'Enable Internal DNS'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '53'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '10.0.2.4'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'enable_rdp_rule'
        properties: {
          description: 'Allow RDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'enable_web_rule'
        properties: {
          description: 'Enable Internet to [variables(\'VM01Name\')]'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '10.0.1.5'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'enable_app_rule'
        properties: {
          description: 'Enable [variables(\'VM01Name\')] to [variables(\'VM02Name\')]'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '10.0.1.5'
          destinationAddressPrefix: '10.0.2.5'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'deny_internet_rule'
        properties: {
          description: 'Isolate the [variables(\'VNetName\')] VNet from the Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Deny'
          priority: 140
          direction: 'Inbound'
        }
      }
      {
        name: 'deny_frontend_rule'
        properties: {
          description: 'Isolate the [variables(\'Subnet1Name\')] subnet from the [variables(\'Subnet2Name\')] subnet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: Subnet1Prefix
          destinationAddressPrefix: Subnet2Prefix
          access: 'Deny'
          priority: 150
          direction: 'Inbound'
        }
      }
    ]
  }
}