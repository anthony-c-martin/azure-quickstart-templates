param clusterNamePrefix string {
  metadata: {
    description: 'The prefix of the HDInsight cluster name.'
  }
}
param sshUserName string {
  metadata: {
    description: 'These credentials can be used to remotely access the cluster.'
  }
}
param Vnet1Region string {
  metadata: {
    description: 'Region for the first vNet.'
  }
}
param Vnet2Region string {
  metadata: {
    description: 'Region for the second vNet. This should be in another Azure region from the first vNet.'
  }
}
param authenticationType string {
  allowed: [
    'sshPublicKey'
    'password'
  ]
  metadata: {
    description: 'Type of authentication to use on the Virtual Machine. SSH key is recommended.'
  }
  default: 'sshPublicKey'
}
param adminPasswordOrKey string {
  metadata: {
    description: 'SSH Key or password for the Virtual Machine. SSH key is recommended.'
  }
  secure: true
}
param UnbuntuNodeVirtualMachineSize string {
  metadata: {
    description: 'This is the Unbuntu DNS node Azure Virtual Machine size, and will affect the cost. If you don\'t know, just leave the default value.'
  }
  default: 'Standard_D3_v2'
}

var Ubuntu = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: '16.04.0-LTS'
  version: 'latest'
}
var vNet1_variable = {
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
var vNet2_variable = {
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
var networkSecurityGroupName = 'vNet1-subnet1-nsg'
var networkSecurityGroupName2 = 'vNet2-subnet1-nsg'

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2020-04-01' = {
  name: networkSecurityGroupName
  location: vNet1_variable.location
  properties: {}
}

resource networkSecurityGroupName2_resource 'Microsoft.Network/networkSecurityGroups@2020-04-01' = {
  name: networkSecurityGroupName2
  location: vNet2_variable.location
  properties: {}
}

resource vNet1_name 'Microsoft.Network/virtualNetworks@2020-04-01' = {
  name: vNet1_variable.name
  location: vNet1_variable.location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNet1_variable.addressSpacePrefix
      ]
    }
    dhcpOptions: {
      dnsServers: [
        vNet1_variable.dnsIPAddress
      ]
    }
    subnets: [
      {
        name: vNet1_variable.subnetName
        properties: {
          addressPrefix: vNet1_variable.subnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroupName_resource.id
          }
        }
      }
      {
        name: vNet1_variable.gatewaySubnetName
        properties: {
          addressPrefix: vNet1_variable.gatewaySubnetPrefix
        }
      }
    ]
  }
  dependsOn: [
    networkSecurityGroupName_resource
  ]
}

resource vNet1_vpnGatewayIP 'Microsoft.Network/publicIPAddresses@2020-04-01' = {
  name: vNet1_variable.vpnGatewayIP
  location: vNet1_variable.location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource vNet1_vpnGatewayName 'Microsoft.Network/virtualNetworkGateways@2020-04-01' = {
  name: vNet1_variable.vpnGatewayName
  location: vNet1_variable.location
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
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet1_variable.name, vNet1_variable.gatewaySubnetName)
          }
          publicIpAddress: {
            id: vNet1_vpnGatewayIP.id
          }
        }
      }
    ]
  }
  dependsOn: [
    vNet1_vpnGatewayIP
    vNet1_name
  ]
}

resource vNet2_name 'Microsoft.Network/virtualNetworks@2020-04-01' = {
  name: vNet2_variable.name
  location: vNet2_variable.location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNet2_variable.addressSpacePrefix
      ]
    }
    dhcpOptions: {
      dnsServers: [
        vNet2_variable.dnsIPAddress
      ]
    }
    subnets: [
      {
        name: vNet2_variable.subnetName
        properties: {
          addressPrefix: vNet2_variable.subnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroupName2_resource.id
          }
        }
      }
      {
        name: vNet2_variable.gatewaySubnetName
        properties: {
          addressPrefix: vNet2_variable.gatewaySubnetPrefix
        }
      }
    ]
  }
  dependsOn: [
    networkSecurityGroupName2_resource
  ]
}

resource vNet2_vpnGatewayIP 'Microsoft.Network/publicIPAddresses@2020-04-01' = {
  name: vNet2_variable.vpnGatewayIP
  location: vNet2_variable.location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource vNet2_vpnGatewayName 'Microsoft.Network/virtualNetworkGateways@2020-04-01' = {
  name: vNet2_variable.vpnGatewayName
  location: vNet2_variable.location
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
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet2_variable.name, vNet2_variable.gatewaySubnetName)
          }
          publicIpAddress: {
            id: vNet2_vpnGatewayIP.id
          }
        }
      }
    ]
  }
  dependsOn: [
    vNet2_vpnGatewayIP
    vNet2_name
  ]
}

resource vpnConnections_name1 'Microsoft.Network/connections@2020-04-01' = {
  name: vpnConnections.name1
  location: vNet1_variable.location
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
  dependsOn: [
    vNet1_vpnGatewayName
    vNet2_vpnGatewayName
  ]
}

resource vpnConnections_name2 'Microsoft.Network/connections@2020-04-01' = {
  name: vpnConnections.name2
  location: vNet2_variable.location
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
  dependsOn: [
    vNet2_vpnGatewayName
    vNet1_vpnGatewayName
  ]
}

resource vNet1_dnsIPName 'Microsoft.Network/publicIPAddresses@2020-04-01' = {
  name: vNet1_variable.dnsIPName
  location: vNet1_variable.location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource vNet1_dnsNICName 'Microsoft.Network/networkInterfaces@2020-04-01' = {
  name: vNet1_variable.dnsNICName
  location: vNet1_variable.location
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
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet1_variable.name, vNet1_variable.subnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    vNet1_name
    vNet1_dnsIPName
  ]
}

resource vNet1_dnsName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vNet1_variable.dnsName
  location: vNet1_variable.location
  properties: {
    hardwareProfile: {
      vmSize: UnbuntuNodeVirtualMachineSize
    }
    osProfile: {
      computerName: vNet1_variable.dnsName
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
  dependsOn: [
    vNet1_dnsNICName
  ]
}

resource vNet2_dnsIPName 'Microsoft.Network/publicIPAddresses@2020-04-01' = {
  name: vNet2_variable.dnsIPName
  location: vNet2_variable.location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource vNet2_dnsNICName 'Microsoft.Network/networkInterfaces@2020-04-01' = {
  name: vNet2_variable.dnsNICName
  location: vNet2_variable.location
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
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet2_variable.name, vNet2_variable.subnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    vNet2_name
    vNet2_dnsIPName
  ]
}

resource vNet2_dnsName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vNet2_variable.dnsName
  location: vNet2_variable.location
  properties: {
    hardwareProfile: {
      vmSize: UnbuntuNodeVirtualMachineSize
    }
    osProfile: {
      computerName: vNet2_variable.dnsName
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
  dependsOn: [
    vNet2_dnsNICName
  ]
}

output vnet1 object = vNet1_name.properties
output vnet2 object = vNet2_name.properties