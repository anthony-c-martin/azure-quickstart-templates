@allowed([
  'RouteBased'
  'PolicyBased'
])
@description('Route based (Dynamic Gateway) or Policy based (Static Gateway)')
param vpnType string = 'RouteBased'

@description('Arbitrary name for gateway resource representing your local/on-prem gateway')
param localGatewayName string = 'localGateway'

@description('Public IP of your local/on-prem gateway')
param localGatewayIpAddress string

@description('CIDR block representing the address space of your local/on-prem network\'s Subnet')
param localAddressPrefix string

@description('Arbitrary name for the Azure Virtual Network')
param virtualNetworkName string = 'azureVnet'

@description('CIDR block representing the address space of the Azure VNet')
param azureVNetAddressPrefix string = '10.3.0.0/16'

@description('Arbitrary name for the Azure Subnet')
param subnetName string = 'Subnet1'

@description('CIDR block for VM subnet, subset of azureVNetAddressPrefix address space')
param subnetPrefix string

@description('CIDR block for gateway subnet, subset of azureVNetAddressPrefix address space')
param gatewaySubnetPrefix string = '10.3.200.0/29'

@description('Arbitrary name for public IP resource used for the new azure gateway')
param gatewayPublicIPName string = 'azureGatewayIP'

@description('Arbitrary name for the new gateway')
param gatewayName string = 'azureGateway'

@allowed([
  'Basic'
  'Standard'
  'HighPerformance'
])
@description('The Sku of the Gateway. This must be one of Basic, Standard or HighPerformance.')
param gatewaySku string = 'Basic'

@description('Arbitrary name for the new connection between Azure VNet and other network')
param connectionName string = 'Azure2Other'

@description('Shared key (PSK) for IPSec tunnel')
param sharedKey string

@description('Name of the sample VM to create')
param vmName string = 'node-1'

@description('VM Image SKU')
param vmImageSKU string = '18.04-LTS'

@description('Size of the Virtual Machine.')
param vmSize string = 'Standard_A1'

@description('Username for sample VM')
param adminUsername string

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('Location for the resources.')
param location string = resourceGroup().location

var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var imageSKU = vmImageSKU
var gatewaySubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'GatewaySubnet')
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var nicName_var = '${vmName}-nic'
var vmPublicIPName_var = '${vmName}-publicIP'
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
var networkSecurityGroupName_var = 'default-NSG'

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
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName_var
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
            id: networkSecurityGroupName.id
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
}

resource gatewayPublicIPName_resource 'Microsoft.Network/publicIPAddresses@2018-07-01' = {
  name: gatewayPublicIPName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource vmPublicIPName 'Microsoft.Network/publicIPAddresses@2018-07-01' = {
  name: vmPublicIPName_var
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
    virtualNetworkName_resource
  ]
}

resource nicName 'Microsoft.Network/networkInterfaces@2018-07-01' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vmPublicIPName.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
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
          id: nicName.id
        }
      ]
    }
  }
}