@description('Reference to the subnet to put the VM\'s NIC in')
param subnetId string

@description('The name of the VM, also sets the computer name and is the based for the NIC\'s name')
param vmName string

@description('The size of the VM')
param vmSize string = 'Standard_A1'

@description('The name of the Administrator of the new VM and Domain')
param adminUsername string

@description('The password for the Administrator account of the new VM and Domain')
@secure()
param adminPassword string

@description('Image Publisher')
param imagePublisher string

@description('Image Offer')
param imageOffer string

@description('Image SKU')
param imageSKU string

@description('Location for all resources.')
param location string = resourceGroup().location

var nicName_var = '${vmName}-nic'

resource nicName 'Microsoft.Network/networkInterfaces@2016-12-01' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}_OSDisk'
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