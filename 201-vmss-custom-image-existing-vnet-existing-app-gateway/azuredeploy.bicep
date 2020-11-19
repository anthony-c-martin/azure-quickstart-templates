param vmSku string {
  metadata: {
    description: 'Size of VMs in the VM Scale Set.'
  }
  default: 'Standard_F2'
}
param vmssName string {
  maxLength: 61
  metadata: {
    description: 'The name of the VM Scale Set.'
  }
}
param instanceCount int {
  maxValue: 100
  metadata: {
    description: 'Initial number of VM instances (100 or less).'
  }
  default: 2
}
param adminUsername string {
  metadata: {
    description: 'Admin username on all VMs.'
  }
}
param adminPassword string {
  metadata: {
    description: 'Admin password on all VMs.'
  }
  secure: true
}
param upgradePolicy string {
  allowed: [
    'Manual'
    'Automatic'
  ]
  metadata: {
    description: 'The upgrade policy for the VM Scale Set, either Manual of Automatic.'
  }
  default: 'Manual'
}
param existingVirtualNetworkResourceGroup string {
  metadata: {
    description: 'The name of the Resource Group which contains the existing Virtual Network that this VM Scale Set will be connected to.'
  }
}
param existingVirtualNetworkName string {
  metadata: {
    description: 'The name of the existing Virtual Network that this VM Scale Set will be connected to.'
  }
}
param existingVirtualNetworkSubnet string {
  metadata: {
    description: 'The name of the existing subnet that this VM Scale Set will be connected to.'
  }
}
param existingManagedImageResourceGroup string {
  metadata: {
    description: 'The name of the Resource Group containing the Image that instances of the VM Scale Set will be created from. Images can be created by capturing Azure VMs.'
  }
}
param existingManagedImageName string {
  metadata: {
    description: 'The name of the Image that instances of the VM Scale Set will be created from. Images can be created by capturing Azure VMs.'
  }
}
param existingAppGatewayResourceGroup string {
  metadata: {
    description: 'The name of the Resource Group which contains the existing Application Gateway that will load-balance the instances of this VM Scale Set.'
  }
}
param existingAppGatewayName string {
  metadata: {
    description: 'The name of the existing Application Gateway that will load-balance the instances of this VM Scale Set.'
  }
}
param existingAppGatewayBackendPoolName string {
  metadata: {
    description: 'The name of the Backend Pool in the existing Application Gateway that will load-balance the instances of this VM Scale Set.'
  }
  default: 'appGatewayBackendPool'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var vmssName_variable = toLower(take(vmssName, 9))
var subnetId = resourceId(existingVirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', existingVirtualNetworkName, existingVirtualNetworkSubnet)
var appGwBePoolId = resourceId(existingAppGatewayResourceGroup, 'Microsoft.Network/applicationGateways/backendAddressPools/', existingAppGatewayName, existingAppGatewayBackendPoolName)
var managedImageId = resourceId(existingManagedImageResourceGroup, 'Microsoft.Compute/images', existingManagedImageName)

resource vmssName_resource 'Microsoft.Compute/virtualMachineScaleSets@2020-06-01' = {
  name: vmssName_variable
  location: location
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: instanceCount
  }
  properties: {
    overprovision: true
    singlePlacementGroup: false
    upgradePolicy: {
      mode: upgradePolicy
    }
    virtualMachineProfile: {
      storageProfile: {
        imageReference: {
          id: managedImageId
        }
      }
      osProfile: {
        computerNamePrefix: vmssName_variable
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig'
                  properties: {
                    subnet: {
                      id: subnetId
                    }
                    ApplicationGatewayBackendAddressPools: [
                      {
                        id: appGwBePoolId
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
}