param adminUsername string {
  metadata: {
    description: 'Username for Administrator Account'
  }
}
param vmName string {
  metadata: {
    description: 'The name of you Virtual Machine.'
  }
  default: 'vmName'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param cpu_gpu string {
  allowed: [
    'CPU-4GB'
    'CPU-7GB'
    'CPU-8GB'
    'CPU-14GB'
    'CPU-16GB'
    'GPU-56GB'
  ]
  metadata: {
    description: 'Choose between CPU or GPU processing'
  }
  default: 'CPU-4GB'
}
param virtualNetworkName string {
  metadata: {
    description: 'Name of the VNET'
  }
  default: 'vNet'
}
param subnetName string {
  metadata: {
    description: 'Name of the subnet in the virtual network'
  }
  default: 'subnet'
}
param networkSecurityGroupName string {
  metadata: {
    description: 'Name of the Network Security Group'
  }
  default: 'SecGroupNet'
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

var networkInterfaceName_var = '${vmName}NetInt'
var virtualMachineName = vmName
var publicIpAddressName_var = '${vmName}PublicIP'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var nsgId = networkSecurityGroupName_res.id
var osDiskType = 'Standard_LRS'
var storageAccountName_var = 'storage${uniqueString(resourceGroup().id)}'
var storageAccountType = 'Standard_LRS'
var storageAccountKind = 'Storage'
var vmSize = {
  'CPU-4GB': 'Standard_B2s'
  'CPU-7GB': 'Standard_DS2_v2'
  'CPU-8GB': 'Standard_D2s_v3'
  'CPU-14GB': 'Standard_DS3_v2'
  'CPU-16GB': 'Standard_D4s_v3'
  'GPU-56GB': 'Standard_NC6_Promo'
}
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

resource networkInterfaceName 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: networkInterfaceName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpAddressName.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
  }
  dependsOn: [
    virtualNetworkName_res
  ]
}

resource networkSecurityGroupName_res 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'JupyterHub'
        properties: {
          priority: 1010
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '8000'
        }
      }
      {
        name: 'RStudioServer'
        properties: {
          priority: 1020
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '8787'
        }
      }
      {
        name: 'SSH'
        properties: {
          priority: 1030
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource virtualNetworkName_res 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/24'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

resource publicIpAddressName 'Microsoft.Network/publicIpAddresses@2020-05-01' = {
  name: publicIpAddressName_var
  location: location
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: storageAccountType
  }
  kind: storageAccountKind
}

resource virtualMachineName_Cpu_Gpu 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: '${virtualMachineName}-${cpu_gpu}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize[cpu_gpu]
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'microsoft-dsvm'
        offer: 'ubuntu-1804'
        sku: '1804-gen2'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName.id
        }
      ]
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
  }
  dependsOn: [
    storageAccountName
  ]
}

output adminUsername_out string = adminUsername