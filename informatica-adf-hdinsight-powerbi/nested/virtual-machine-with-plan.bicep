@description('Network Security Group Deployment Location')
param location string = 'westus'

@allowed([
  '2015-05-01-preview'
  '2015-06-15'
])
@description('API Version for the Compute Resources')
param computeApiVersion string = '2015-06-15'

@description('Tag Values')
param tag object = {
  key1: 'key'
  value1: 'value'
}

@description('Virtual Machine Name')
param vmName string = 'vmName'

@description('Virtual Machine Size')
param vmSize string = 'Standard_D2'

@description('Admin Username of Virtual Machine to SSH or RDP')
param adminUsername string = 'sysgain'

@description('Admin Password of Virtual Machine to SSH or RDP')
@secure()
param adminPassword string = 'Sysga1n4205!'

@description('Virtual Machine Image Publisher')
param imagePublisher string = ' '

@description('Virtual Machine Image Offer')
param imageOffer string = ' '

@description('Virtual Machine Image SKU')
param imageSKU string = ' '

@description('Virtual Machine Image Version')
param imageVersion string = 'latest'

@description('Storage Account Name')
param storageAccountName string = 'storageAccountName'

@description('Caintainer name in the storage account')
param vmStorageAccountContainerName string = 'vhds'

@description('Network Security Group Name')
param networkInterfaceName string = 'networkInterfaceName'
param informaticaTags object
param quickstartTags object

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: location
  tags: {
    '${tag.key1}': tag.value1
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
  plan: {
    name: imageSKU
    product: imageOffer
    publisher: imagePublisher
  }
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
        version: imageVersion
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
          id: resourceId('Microsoft.Network/networkInterfaces', networkInterfaceName)
        }
      ]
    }
  }
}