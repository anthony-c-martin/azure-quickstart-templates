@description('The prefix of the HDInsight cluster name.')
param clusterNamePrefix string

@description('These credentials can be used to remotely access the cluster.')
param sshUserName string

@description('Region for the first vNet.')
param Vnet1Region string

@description('Region for the second vNet. This should be in another Azure region from the first vNet.')
param Vnet2Region string

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('This is the Unbuntu DNS node Azure Virtual Machine size, and will affect the cost. If you don\'t know, just leave the default value.')
param UnbuntuNodeVirtualMachineSize string = 'Standard_D3_v2'

var Ubuntu = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: '16.04.0-LTS'
  version: 'latest'
}
var vNet1 = {
  name: '${clusterNamePrefix}-vnet1'
  location: Vnet1Region
  addressSpacePrefix: '10.1.0.0/16'
  subnetName: 'subnet1'
  subnetPrefix: '10.1.0.0/24'
  gatewaySubnetName: 'GatewaySubnet'
  gatewaySubnetPrefix: '10.1.255.0/27'
  vpnGatewayName: 'vnet1gw'
  vpnGatewayIP: 'vnet1gwip'
  dnsName: 'vnet1DNS'
  dnsNICName: 'vnet1DNSNIC'
  dnsIPName: 'vnet1DNSPublicIP'
  dnsIPAddress: '10.1.0.4'
}
var vNet2 = {
  name: '${clusterNamePrefix}-vnet2'
  location: Vnet2Region
  addressSpacePrefix: '10.2.0.0/16'
  subnetName: 'subnet1'
  subnetPrefix: '10.2.0.0/24'
  gatewaySubnetName: 'GatewaySubnet'
  gatewaySubnetPrefix: '10.2.255.0/27'
  vpnGatewayName: 'vnet2gw'
  vpnGatewayIP: 'vnet2gwip'
  dnsName: 'vnet2DNS'
  dnsNICName: 'vnet2DNSNIC'
  dnsIPName: 'vnet2DNSPublicIP'
  dnsIPAddress: '10.2.0.4'
}
var vpnConnections = {
  name1: 'vnet1tovnet2'
  name2: 'vnet2tovnet1'
  sharedKey: 'A1b2C3D4'
}
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${sshUserName}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}
var networkSecurityGroupName_var = 'vNet1-subnet1-nsg'
var networkSecurityGroupName2_var = 'vNet2-subnet1-nsg'

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2020-04-01' = {
  name: networkSecurityGroupName_var
  location: vNet1.location
  properties: {}
}

resource networkSecurityGroupName2 'Microsoft.Network/networkSecurityGroups@2020-04-01' = {
  name: networkSecurityGroupName2_var
  location: vNet2.location
  properties: {}
}

resource vNet1_name 'Microsoft.Network/virtualNetworks@2020-04-01' = {
  name: vNet1.name
  location: vNet1.location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNet1.addressSpacePrefix
      ]
    }
    dhcpOptions: {
      dnsServers: [
        vNet1.dnsIPAddress
      ]
    }
    subnets: [
      {
        name: vNet1.subnetName
        properties: {
          addressPrefix: vNet1.subnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
      {
        name: vNet1.gatewaySubnetName
        properties: {
          addressPrefix: vNet1.gatewaySubnetPrefix
        }
      }
    ]
  }
}

resource vNet1_vpnGatewayIP 'Microsoft.Network/publicIPAddresses@2020-04-01' = {
  name: vNet1.vpnGatewayIP
  location: vNet1.location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource vNet1_vpnGatewayName 'Microsoft.Network/virtualNetworkGateways@2020-04-01' = {
  name: vNet1.vpnGatewayName
  location: vNet1.location
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    sku: {
      name: 'Basic'
      tier: 'Basic'
    }
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet1.name, vNet1.gatewaySubnetName)
          }
          publicIPAddress: {
            id: vNet1_vpnGatewayIP.id
          }
        }
      }
    ]
  }
  dependsOn: [
    vNet1_name
  ]
}

resource vNet2_name 'Microsoft.Network/virtualNetworks@2020-04-01' = {
  name: vNet2.name
  location: vNet2.location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNet2.addressSpacePrefix
      ]
    }
    dhcpOptions: {
      dnsServers: [
        vNet2.dnsIPAddress
      ]
    }
    subnets: [
      {
        name: vNet2.subnetName
        properties: {
          addressPrefix: vNet2.subnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroupName2.id
          }
        }
      }
      {
        name: vNet2.gatewaySubnetName
        properties: {
          addressPrefix: vNet2.gatewaySubnetPrefix
        }
      }
    ]
  }
}

resource vNet2_vpnGatewayIP 'Microsoft.Network/publicIPAddresses@2020-04-01' = {
  name: vNet2.vpnGatewayIP
  location: vNet2.location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource vNet2_vpnGatewayName 'Microsoft.Network/virtualNetworkGateways@2020-04-01' = {
  name: vNet2.vpnGatewayName
  location: vNet2.location
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    sku: {
      name: 'Basic'
      tier: 'Basic'
    }
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet2.name, vNet2.gatewaySubnetName)
          }
          publicIPAddress: {
            id: vNet2_vpnGatewayIP.id
          }
        }
      }
    ]
  }
  dependsOn: [
    vNet2_name
  ]
}

resource vpnConnections_name1 'Microsoft.Network/connections@2020-04-01' = {
  name: vpnConnections.name1
  location: vNet1.location
  properties: {
    connectionType: 'Vnet2Vnet'
    virtualNetworkGateway1: {
      id: vNet1_vpnGatewayName.id
    }
    virtualNetworkGateway2: {
      id: vNet2_vpnGatewayName.id
    }
    sharedKey: vpnConnections.sharedKey
    routingWeight: 0
    enableBgp: false
    usePolicyBasedTrafficSelectors: false
  }
}

resource vpnConnections_name2 'Microsoft.Network/connections@2020-04-01' = {
  name: vpnConnections.name2
  location: vNet2.location
  properties: {
    connectionType: 'Vnet2Vnet'
    virtualNetworkGateway1: {
      id: vNet2_vpnGatewayName.id
    }
    virtualNetworkGateway2: {
      id: vNet1_vpnGatewayName.id
    }
    sharedKey: vpnConnections.sharedKey
    routingWeight: 0
    enableBgp: false
    usePolicyBasedTrafficSelectors: false
  }
}

resource vNet1_dnsIPName 'Microsoft.Network/publicIPAddresses@2020-04-01' = {
  name: vNet1.dnsIPName
  location: vNet1.location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource vNet1_dnsNICName 'Microsoft.Network/networkInterfaces@2020-04-01' = {
  name: vNet1.dnsNICName
  location: vNet1.location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vNet1_dnsIPName.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet1.name, vNet1.subnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    vNet1_name
  ]
}

resource vNet1_dnsName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vNet1.dnsName
  location: vNet1.location
  properties: {
    hardwareProfile: {
      vmSize: UnbuntuNodeVirtualMachineSize
    }
    osProfile: {
      computerName: vNet1.dnsName
      adminUsername: sshUserName
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: Ubuntu
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vNet1_dnsNICName.id
        }
      ]
    }
  }
}

resource vNet2_dnsIPName 'Microsoft.Network/publicIPAddresses@2020-04-01' = {
  name: vNet2.dnsIPName
  location: vNet2.location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource vNet2_dnsNICName 'Microsoft.Network/networkInterfaces@2020-04-01' = {
  name: vNet2.dnsNICName
  location: vNet2.location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vNet2_dnsIPName.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet2.name, vNet2.subnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    vNet2_name
  ]
}

resource vNet2_dnsName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vNet2.dnsName
  location: vNet2.location
  properties: {
    hardwareProfile: {
      vmSize: UnbuntuNodeVirtualMachineSize
    }
    osProfile: {
      computerName: vNet2.dnsName
      adminUsername: sshUserName
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: Ubuntu
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vNet2_dnsNICName.id
        }
      ]
    }
  }
}

output vnet1 object = vNet1_name.properties
output vnet2 object = vNet2_name.properties