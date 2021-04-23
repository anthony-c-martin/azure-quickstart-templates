@description('This is the name of the your VM')
param customVmName string

@description('This is the name of the your storage account')
param bootDiagnosticsStorageAccountName string

@description('Resource group of the existing storage account')
param bootDiagnosticsStorageAccountResourceGroupName string

@description('URI in Azure storage of the blob (VHD) that you want to use for the OS disk. eg. https://mystorageaccount.blob.core.windows.net/osimages/osimage.vhd')
param osDiskVhdUri string

@description('URI in Azure storage of the blob (VHD) that you want to use for the data disk. eg. https://mystorageaccount.blob.core.windows.net/dataimages/dataimage.vhd')
param dataDiskVhdUri string

@allowed([
  'Standard_LRS'
  'Premium_LRS'
])
param diskStorageType string = 'Premium_LRS'

@description('DNS Label for the Public IP. Must be lowercase. It should match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.')
param dnsLabelPrefix string

@description('User Name for the Virtual Machine')
param adminUsername string

@description('Password for the Virtual Machine')
@secure()
param adminPassword string

@allowed([
  'Windows'
  'Linux'
])
@description('This is the OS that your VM will be running')
param osType string

@description('This is the size of your VM')
param vmSize string

@allowed([
  'new'
  'existing'
])
@description('Select if this template needs a new VNet or will reference an existing VNet')
param newOrExistingVnet string

@description('New or Existing VNet Name')
param newOrExistingVnetName string = ''

@description('New or Existing subnet Name')
param newOrExistingSubnetName string

@description('Resource group of the existing VNET')
param existingVnetResourceGroupName string

@description('Location for all resources.')
param location string = resourceGroup().location

var imageName_var = 'myCustomImage'
var publicIPAddressName_var = '${customVmName}IP'
var vmName_var = customVmName
var nicName_var = '${customVmName}Nic'
var publicIPAddressType = 'Dynamic'
var apiVersion = '2015-06-15'
var templatelink = 'https://raw.githubusercontent.com/azure/azure-quickstart-templates/master/101-vm-user-image-data-disks/${newOrExistingVnet}vnet.json'

resource imageName 'Microsoft.Compute/images@2017-03-30' = {
  name: imageName_var
  location: location
  properties: {
    storageProfile: {
      osDisk: {
        osType: osType
        osState: 'Generalized'
        blobUri: osDiskVhdUri
        storageAccountType: 'Standard_LRS'
      }
      dataDisks: [
        {
          lun: 1
          blobUri: dataDiskVhdUri
          storageAccountType: 'Standard_LRS'
        }
      ]
    }
  }
}

module vnet_template '?' /*TODO: replace with correct path to [variables('templatelink')]*/ = {
  name: 'vnet-template'
  params: {
    virtualNetworkName: newOrExistingVnetName
    subnetName: newOrExistingSubnetName
    existingVnetResourceGroupName: existingVnetResourceGroupName
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2016-03-30' = {
  name: nicName_var
  location: location
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
            id: reference('vnet-template').outputs.subnet1Ref.value
          }
        }
      }
    ]
  }
  dependsOn: [
    vnet_template
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName_var
  location: location
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
        id: imageName.id
      }
      osDisk: {
        name: '${customVmName}_OSDisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: diskStorageType
        }
      }
      dataDisks: [
        {
          name: '${customVmName}_DataDisk1'
          lun: 1
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: diskStorageType
          }
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
        storageUri: concat(reference(resourceId(bootDiagnosticsStorageAccountResourceGroupName, 'Microsoft.Storage/storageAccounts/', bootDiagnosticsStorageAccountName), apiVersion).primaryEndpoints.blob)
      }
    }
  }
}