param vmName string {
  metadata: {
    description: 'Name of the VM'
  }
}
param osType string {
  allowed: [
    'Linux'
  ]
  metadata: {
    description: 'Type of OS on the existing vhd'
  }
  default: 'Linux'
}
param osDiskVhdUri string {
  metadata: {
    description: 'URI of the existing VHD in ARM standard or premium storage'
  }
}
param vmSize string {
  metadata: {
    description: 'Size of the VM'
  }
  default: 'Standard_A1_v2'
}
param vmDiskSizeGB string {
  allowed: [
    '150'
    '300'
  ]
  metadata: {
    description: 'Diskspace size of the VM'
  }
  default: '150'
}
param existingVirtualNetworkResourceGroup string {
  metadata: {
    description: 'Name of the existing VNET resource group'
  }
  default: resourceGroup().name
}
param existingVirtualNetworkName string {
  metadata: {
    description: 'Name of the existing VNET'
  }
}
param subnetName string {
  metadata: {
    description: 'Name of the subnet in the virtual network you want to use'
  }
}
param existingSecurityGroupName string {
  metadata: {
    description: 'Name of the network Security Group that needs to be assocated to virtual NIC. '
  }
}
param dnsNameForPublicIP string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Virtual Machine.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var diagStorageAccountName_var = '${uniqueString(resourceGroup().id)}specvm'
var publicIPAddressType = 'Dynamic'
var subnetRef = resourceId(existingVirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', existingVirtualNetworkName, subnetName)
var nicName_var = vmName
var publicIPAddressName_var = vmName

resource diagStorageAccountName 'Microsoft.Storage/storageAccounts@2018-02-01' = {
  name: diagStorageAccountName_var
  location: location
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'Storage'
  properties: {}
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName_var
  location: location
  tags: {
    displayName: 'PublicIPAddress'
  }
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2017-03-01' = {
  name: nicName_var
  location: location
  tags: {
    displayName: 'NetworkInterface'
  }
  properties: {
    networkSecurityGroup: {
      id: resourceId(existingVirtualNetworkResourceGroup, 'Microsoft.Network/networkSecurityGroups', existingSecurityGroupName)
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
}

resource vmName_OSdisk 'Microsoft.Compute/disks@2017-03-30' = {
  name: '${vmName}_OSdisk'
  location: location
  properties: {
    creationData: {
      createOption: 'Import'
      sourceUri: osDiskVhdUri
    }
    osType: osType
  }
}

resource vmName_res 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: location
  tags: {
    displayName: 'VirtualMachine'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        osType: osType
        caching: 'ReadWrite'
        managedDisk: {
          id: vmName_OSdisk.id
        }
        createOption: 'Attach'
        diskSizeGB: vmDiskSizeGB
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(diagStorageAccountName.id, '2016-01-01').primaryEndpoints.blob
      }
    }
  }
}