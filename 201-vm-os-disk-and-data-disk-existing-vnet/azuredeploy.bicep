param vmName string {
  metadata: {
    description: 'Name of the VM'
  }
}
param osType string {
  allowed: [
    'Windows'
    'Linux'
  ]
  metadata: {
    description: 'Type of OS on the existing vhd'
  }
}
param osDiskVhdUri string {
  metadata: {
    description: 'Uri of the existing OS VHD in ARM standard or premium storage'
  }
}
param dataDisk0VhdUri string {
  metadata: {
    description: 'Uri of the existing data disk VHD in ARM standard or premium storage'
  }
}
param vmSize string {
  metadata: {
    description: 'Size of the VM'
  }
}
param existingVirtualNetworkName string {
  metadata: {
    description: 'Name of the existing VNET'
  }
}
param existingVirtualNetworkResourceGroup string {
  metadata: {
    description: 'Name of the existing VNET resource group'
  }
  default: resourceGroup().name
}
param subnetName string {
  metadata: {
    description: 'Name of the subnet in the virtual network you want to use'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var diagStorageAccountName_var = '${vmName}diag'
var publicIPAddressType = 'Dynamic'
var subnetRef = resourceId(existingVirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', existingVirtualNetworkName, subnetName)
var nicName_var = '${vmName}-nic1'
var publicIPAddressName_var = '${vmName}-pip'

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
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName_var
  location: location
  tags: {
    displayName: 'NetworkInterface'
  }
  properties: {
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

resource vmName_Datadisk 'Microsoft.Compute/disks@2017-03-30' = {
  name: '${vmName}_Datadisk'
  location: location
  properties: {
    creationData: {
      createOption: 'Import'
      sourceUri: dataDisk0VhdUri
    }
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
        createOption: 'Attach'
        managedDisk: {
          id: vmName_OSdisk.id
        }
      }
      dataDisks: [
        {
          lun: 0
          managedDisk: {
            id: vmName_Datadisk.id
          }
          caching: 'ReadOnly'
          createOption: 'Attach'
        }
      ]
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
        storageUri: concat(reference('Microsoft.Storage/storageAccounts/${diagStorageAccountName_var}', '2016-01-01').primaryEndpoints.blob)
      }
    }
  }
}