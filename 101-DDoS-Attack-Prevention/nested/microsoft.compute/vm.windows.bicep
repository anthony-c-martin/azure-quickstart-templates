@description('Name of the virtual machine')
param vmName string

@description('Admin user name for the virtual machine')
param adminUsername string

@description('Admin user password for virtual machine')
@secure()
param adminPassword string

@description('Size of VM')
param vmSize string = 'Standard_DS2_v2'
param imagePublisher string = 'MicrosoftWindowsServer'
param imageOffer string = 'WindowsServer'

@description('OS sku for VM')
param osSku string = '2012-R2-Datacenter'

@description('Network interface id.')
param nicId string

@description('VM deployment location.')
param location string

@description('Size for Data Disks.')
param dataDiskSizeInGB int = 128

@minValue(0)
@maxValue(16)
@description('The number of dataDisks to be returned in the output array.')
param numberOfDataDisks int = 1
param tags object

resource vmName_resource 'Microsoft.Compute/virtualMachines@2018-06-01' = {
  name: vmName
  location: location
  tags: tags
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
        sku: osSku
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [for j in range(0, numberOfDataDisks): {
        diskSizeGB: dataDiskSizeInGB
        lun: j
        createOption: 'Empty'
      }]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicId
        }
      ]
    }
  }
}