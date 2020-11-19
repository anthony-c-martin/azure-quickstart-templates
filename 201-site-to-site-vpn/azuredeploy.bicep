param vpnType string {
  allowed: [
    'RouteBased'
    'PolicyBased'
  ]
  metadata: {
    description: 'Route based (Dynamic Gateway) or Policy based (Static Gateway)'
  }
  default: 'RouteBased'
}
param localGatewayName string {
  metadata: {
    description: 'Arbitrary name for gateway resource representing your local/on-prem gateway'
  }
  default: 'localGateway'
}
param localGatewayIpAddress string {
  metadata: {
    description: 'Public IP of your local/on-prem gateway'
  }
}
param localAddressPrefix string {
  metadata: {
    description: 'CIDR block representing the address space of your local/on-prem network\'s Subnet'
  }
}
param virtualNetworkName string {
  metadata: {
    description: 'Arbitrary name for the Azure Virtual Network'
  }
  default: 'azureVnet'
}
param azureVNetAddressPrefix string {
  metadata: {
    description: 'CIDR block representing the address space of the Azure VNet'
  }
  default: '10.3.0.0/16'
}
param subnetName string {
  metadata: {
    description: 'Arbitrary name for the Azure Subnet'
  }
  default: 'Subnet1'
}
param subnetPrefix string {
  metadata: {
    description: 'CIDR block for VM subnet, subset of azureVNetAddressPrefix address space'
  }
}
param gatewaySubnetPrefix string {
  metadata: {
    description: 'CIDR block for gateway subnet, subset of azureVNetAddressPrefix address space'
  }
  default: '10.3.200.0/29'
}
param gatewayPublicIPName string {
  metadata: {
    description: 'Arbitrary name for public IP resource used for the new azure gateway'
  }
  default: 'azureGatewayIP'
}
param gatewayName string {
  metadata: {
    description: 'Arbitrary name for the new gateway'
  }
  default: 'azureGateway'
}
param gatewaySku string {
  allowed: [
    'Basic'
    'Standard'
    'HighPerformance'
  ]
  metadata: {
    description: 'The Sku of the Gateway. This must be one of Basic, Standard or HighPerformance.'
  }
  default: 'Basic'
}
param connectionName string {
  metadata: {
    description: 'Arbitrary name for the new connection between Azure VNet and other network'
  }
  default: 'Azure2Other'
}
param sharedKey string {
  metadata: {
    description: 'Shared key (PSK) for IPSec tunnel'
  }
}
param vmName string {
  metadata: {
    description: 'Name of the sample VM to create'
  }
  default: 'node-1'
}
param vmImageSKU string {
  metadata: {
    description: 'VM Image SKU'
  }
  default: '18.04-LTS'
}
param vmSize string {
  metadata: {
    description: 'Size of the Virtual Machine.'
  }
  default: 'Standard_A1'
}
param adminUsername string {
  metadata: {
    description: 'Username for sample VM'
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
param location string {
  metadata: {
    description: 'Location for the resources.'
  }
  default: resourceGroup().location
}

var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var imageSKU = vmImageSKU
var gatewaySubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'GatewaySubnet')
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var nicName = '${vmName}-nic'
var vmPublicIPName = '${vmName}-publicIP'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}
var networkSecurityGroupName = 'default-NSG'

resource localGatewayName_resource 'Microsoft.Network/localNetworkGateways@2018-07-01' = {
  name: localGatewayName
  location: location
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: [
        localAddressPrefix
      ]
    }
    gatewayIpAddress: localGatewayIpAddress
  }
}

resource connectionName_resource 'Microsoft.Network/connections@2018-07-01' = {
  name: connectionName
  location: location
  properties: {
    virtualNetworkGateway1: {
      id: gatewayName_resource.id
    }
    localNetworkGateway2: {
      id: localGatewayName_resource.id
    }
    connectionType: 'IPsec'
    routingWeight: 10
    sharedKey: sharedKey
  }
  dependsOn: [
    gatewayName_resource
    localGatewayName_resource
  ]
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-22'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2018-07-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        azureVNetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroupName_resource.id
          }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gatewaySubnetPrefix
        }
      }
    ]
  }
  dependsOn: [
    networkSecurityGroupName_resource
  ]
}

resource gatewayPublicIPName_resource 'Microsoft.Network/publicIPAddresses@2018-07-01' = {
  name: gatewayPublicIPName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource vmPublicIPName_resource 'Microsoft.Network/publicIPAddresses@2018-07-01' = {
  name: vmPublicIPName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource gatewayName_resource 'Microsoft.Network/virtualNetworkGateways@2018-07-01' = {
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
    vpnType: vpnType
    enableBgp: 'false'
  }
  dependsOn: [
    gatewayPublicIPName_resource
    virtualNetworkName_resource
  ]
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2018-07-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vmPublicIPName_resource.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    vmPublicIPName_resource
    virtualNetworkName_resource
    gatewayName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2019-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
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
          id: nicName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    nicName_resource
  ]
}