param vmName string {
  metadata: {
    description: 'The name of you Virtual Machine.'
  }
  default: 'EdgeVM'
}
param IoTHubname string {
  metadata: {
    description: 'Name for your IotHub'
  }
  default: 'IoThub${uniqueString(resourceGroup().id)}'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param VmSize string {
  allowed: [
    'Standard_B1ls'
    'Standard_B1s'
    'Standard_B1ms'
    'Standard_B2s'
    'Standard_B2ms'
    'Standard_B4ms'
    'Standard_B8ms'
    'Standard_B12ms'
    'Standard_B16ms'
    'Standard_B20ms'
  ]
  metadata: {
    description: 'The size of the VM'
  }
}
param adminUsername string {
  metadata: {
    description: 'Username for the Virtual Machine.'
  }
}
param adminPassword string {
  metadata: {
    description: 'Password for the Virtual Machine. The password must be at least 12 characters long and have lower case, upper characters, digit and a special character (Regex match)'
  }
  secure: true
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
  default: 'Subnet'
}
param networkSecurityGroupName string {
  metadata: {
    description: 'Name of the Network Security Group'
  }
  default: 'SecGroupNet'
}
param IoTsku_name string {
  metadata: {
    description: 'The SKU for the IoT hub to use'
  }
  default: 'F1'
}
param IoTsku_units string {
  metadata: {
    description: 'This is linked to the SKU'
  }
  default: '1'
}
param IoTsku_partitions string {
  metadata: {
    description: 'This is linked to the SKU'
  }
  default: '2'
}
param IoTfeatures string {
  metadata: {
    description: 'This is linked to the SKU'
  }
  default: 'None'
}

var networkInterfaceName = '${vmName}NetInt'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var publicIpAddressName = '${vmName}PublicIP'
var osDiskType = 'Standard_LRS'
var subnetAddressPrefix = '10.1.0.0/24'
var addressPrefix = '10.1.0.0/16'

resource IoTHubname_resource 'Microsoft.Devices/IotHubs@2019-03-22' = {
  name: IoTHubname
  location: location
  properties: {
    eventHubEndpoints: {
      events: {
        retentionTimeInDays: 1
        partitionCount: IoTsku_partitions
      }
    }
    features: IoTfeatures
  }
  sku: {
    name: IoTsku_name
    capacity: IoTsku_units
  }
}

resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2019-07-01' = {
  name: networkInterfaceName
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
          publicIpAddress: {
            id: publicIpAddressName_resource.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroupName_resource.id
    }
  }
  dependsOn: [
    networkSecurityGroupName_resource
    virtualNetworkName_resource
    publicIpAddressName_resource
  ]
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-02-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 300
          protocol: 'TCP'
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

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-04-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
        }
      }
    ]
  }
}

resource publicIpAddressName_resource 'Microsoft.Network/publicIpAddresses@2019-02-01' = {
  name: publicIpAddressName
  location: location
  properties: {
    publicIpAllocationMethod: 'Dynamic'
  }
  sku: {
    name: 'Basic'
  }
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2019-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: VmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'microsoft_iot_edge'
        offer: 'iot_edge_vm_ubuntu'
        sku: 'ubuntu_1604_edgeruntimeonly'
        version: '1.0.1'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName_resource.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
  }
  plan: {
    name: 'ubuntu_1604_edgeruntimeonly'
    publisher: 'microsoft_iot_edge'
    product: 'iot_edge_vm_ubuntu'
  }
  dependsOn: [
    networkInterfaceName_resource
    IoTHubname_resource
  ]
}

output adminUsername_output string = adminUsername