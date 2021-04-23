@description('Size of VMs in the VM Scale Set.')
param vmSku string = 'Standard_D1_v2'

@maxLength(61)
@description('Unique name for the scale set. Must be 3-61 characters in length and unique across the VNet.')
param vmssName string

@maxValue(100)
@description('Number of VM instances (100 or less).')
param instanceCount int = 2

@description('Admin username on all VMs.')
param adminUsername string

@description('Admin password on all VMs.')
@secure()
param adminPassword string

@description('vName of the existing virtual network to deploy the scale set into.')
param existingVnetName string

@description('Name of the existing subnet to deploy the scale set into.')
param existingSubnetName string

resource vmssName_resource 'Microsoft.Compute/virtualMachineScaleSets@2017-03-30' = {
  name: vmssName
  location: resourceGroup().location
  sku: {
    name: vmSku
    capacity: instanceCount
  }
  properties: {
    overprovision: 'false'
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
        }
        imageReference: {
          publisher: 'MicrosoftWindowsServer'
          offer: 'WindowsServer'
          sku: '2016-Datacenter'
          version: 'latest'
        }
      }
      osProfile: {
        computerNamePrefix: vmssName
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
                      id: resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', existingVnetName, existingSubnetName)
                    }
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