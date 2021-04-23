@allowed([
  'RouteBased'
  'PolicyBased'
])
@description('Route based (Dynamic Gateway) or Policy based (Static Gateway)')
param vpnType string = 'RouteBased'

@description('Public IP of your local/on-prem gateway')
param localGatewayIpAddress string = '52.25.48.88'

@description('CIDR block representing the address space of your local/on-prem network\'s Subnet')
param localAddressPrefix string = '10.0.0.0/24'

@description('CIDR block representing the address space of the Azure VNet')
param azureVNetAddressPrefix string = '10.3.0.0/16'

@description('CIDR block for VM subnet, subset of azureVNetAddressPrefix address space')
param subnetPrefix string = '10.3.0.0/24'

@description('CIDR block for gateway subnet, subset of azureVNetAddressPrefix address space')
param gatewaySubnetPrefix string = '10.3.200.0/29'

@allowed([
  'Basic'
  'Standard'
  'HighPerformance'
])
@description('The Sku of the Gateway. This must be one of Basic, Standard or HighPerformance.')
param gatewaySku string = 'Basic'

@description('Shared key (PSK) for IPSec tunnel')
param sharedKey string

@description('Username for the VM')
param adminUsername string

@description('User password for the VM')
@secure()
param adminPassword string

@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Premium_LRS'
])
@description('Storage Account Type')
param storageAccountType string = 'Standard_LRS'

var vmName_var = 'zca-vm'
var gatewaySubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, 'GatewaySubnet')
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var nicName_var = '${vmName_var}-nic'
var vmStorageAccountContainerName = 'vhds'
var OSDiskName = 'osDisk'
var vmPublicIPName_var = '${vmName_var}-publicIP'
var storageAccountName_var = 'zerto${uniqueString(resourceGroup().id)}'
var vmSize = 'Standard_DS3_v2'
var vmOSDiskName = 'vmOSDisk'
var nsgName_var = 'zca-nsg'
var virtualNetworkName_var = 'vnet'
var connectionName_var = 'Azure2Other'
var gatewayName_var = 'AzureGateway'
var gatewayPublicIPName_var = 'azureGatewayIP'
var localGatewayName_var = 'localGateway'
var subnetName = 'Subnet1'

module pid_84d2edc4_86bd_439c_8373_e9f04e0f5ad2 './nested_pid_84d2edc4_86bd_439c_8373_e9f04e0f5ad2.bicep' = {
  name: 'pid-84d2edc4-86bd-439c-8373-e9f04e0f5ad2'
  params: {}
}

resource localGatewayName 'Microsoft.Network/localNetworkGateways@2017-03-01' = {
  name: localGatewayName_var
  location: resourceGroup().location
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: [
        localAddressPrefix
      ]
    }
    gatewayIpAddress: localGatewayIpAddress
  }
}

resource connectionName 'Microsoft.Network/connections@2017-03-01' = {
  name: connectionName_var
  location: resourceGroup().location
  properties: {
    virtualNetworkGateway1: {
      id: gatewayName.id
    }
    localNetworkGateway2: {
      id: localGatewayName.id
    }
    connectionType: 'IPsec'
    routingWeight: 10
    sharedKey: sharedKey
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2017-03-01' = {
  name: virtualNetworkName_var
  location: resourceGroup().location
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

resource gatewayPublicIPName 'Microsoft.Network/publicIPAddresses@2017-03-01' = {
  name: gatewayPublicIPName_var
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource vmPublicIPName 'Microsoft.Network/publicIPAddresses@2017-03-01' = {
  name: vmPublicIPName_var
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2017-06-01' = {
  name: storageAccountName_var
  location: resourceGroup().location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
}

resource gatewayName 'Microsoft.Network/virtualNetworkGateways@2017-03-01' = {
  name: gatewayName_var
  location: resourceGroup().location
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
    vpnType: vpnType
    enableBgp: 'false'
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource nicName 'Microsoft.Network/networkInterfaces@2017-03-01' = {
  name: nicName_var
  location: resourceGroup().location
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
    networkSecurityGroup: {
      id: nsgName.id
    }
  }
  dependsOn: [
    virtualNetworkName
    gatewayName
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName_var
  location: resourceGroup().location
  tags: {
    displayName: 'vm'
  }
  plan: {
    name: 'zerto60ga'
    publisher: 'zerto'
    product: 'zerto-cloud-appliance-50'
  }
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
        publisher: 'zerto'
        offer: 'zerto-cloud-appliance-50'
        sku: 'zerto60ga'
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
    storageAccountName
  ]
}

resource nsgName 'Microsoft.Network/networkSecurityGroups@2017-03-01' = {
  name: nsgName_var
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'AllowRDP'
        etag: 'W/"ec1cdead-18a3-4ae4-b0fa-1d58260ead30"'
        properties: {
          provisioningState: 'Succeeded'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}