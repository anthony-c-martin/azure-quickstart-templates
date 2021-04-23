@description('Unique public dns name where the master node will be exposed')
param dnsName string

@description('Unique DNS Name for the Storage Account where the Virtual Machine\'s disks will be placed.')
param newStorageAccountName string

@description('User name for the Virtual Machine.')
param adminUsername string

@description('Admin password')
@secure()
param adminPassword string

@description('Size of the nodes.')
param vmSize string = 'Standard_D1_v2'

@description('This template create N worker node. Use scaleNumber to specify that N.')
param scaleNumber int = 2

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located. For example, if stored on a public GitHub repo, you\'d use the following URI: https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/torque-cluster/.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/torque-cluster/'

@description('The sasToken required to access _artifactsLocation.  If your artifacts are stored on a public repo or public storage account you can leave this blank.')
@secure()
param artifactsLocationSasToken string = ''

var imagePublisher = 'OpenLogic'
var imageOffer = 'CentOS'
var OSVersion = '6.10'
var publicIPAddressType = 'Dynamic'
var publicIPAddressName_var = 'publicips'
var masterVMName_var = 'master'
var workerVMName_var = 'worker'
var nicName_var = 'nic'
var networkSettings = {
  virtualNetworkName: 'virtualnetwork'
  addressPrefix: '10.0.0.0/16'
  subnet: {
    dse: {
      name: 'dse'
      prefix: '10.0.0.0/24'
      vnet: 'virtualnetwork'
    }
  }
  statics: {
    workerRange: {
      base: '10.0.0.'
      start: 5
    }
    master: '10.0.0.254'
  }
}
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', networkSettings.virtualNetworkName, networkSettings.subnet.dse.name)
var installationCLI = 'sh azuredeploy.sh ${masterVMName_var} ${networkSettings.statics.master} ${workerVMName_var} ${networkSettings.statics.workerRange.base} ${networkSettings.statics.workerRange.start} ${scaleNumber} ${adminUsername} ${adminPassword} ${artifactsLocation}'
var storageAccountType = 'Standard_LRS'

resource newStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: newStorageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource networkSettings_virtualNetworkName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: networkSettings.virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        networkSettings.addressPrefix
      ]
    }
    subnets: [
      {
        name: networkSettings.subnet.dse.name
        properties: {
          addressPrefix: networkSettings.subnet.dse.prefix
        }
      }
    ]
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsName
    }
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: networkSettings.statics.master
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
  dependsOn: [
    networkSettings_virtualNetworkName
  ]
}

resource masterVMName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: masterVMName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: masterVMName_var
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        name: '${masterVMName_var}_OSDisk'
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
  dependsOn: [
    newStorageAccountName_resource
  ]
}

resource masterVMName_Installation 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  parent: masterVMName
  name: 'Installation'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'azuredeploy.sh${artifactsLocationSasToken}')
      ]
    }
    protectedSettings: {
      commandToExecute: installationCLI
    }
  }
}

resource nicName_worker 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, scaleNumber): {
  name: '${nicName_var}worker${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: concat(networkSettings.statics.workerRange.base, (i + networkSettings.statics.workerRange.start))
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    networkSettings_virtualNetworkName
  ]
}]

resource workerVMName 'Microsoft.Compute/virtualMachines@2019-12-01' = [for i in range(0, scaleNumber): {
  name: concat(workerVMName_var, i)
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(workerVMName_var, i)
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        name: '${workerVMName_var}${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${nicName_var}worker${i}')
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccountName_resource
    resourceId('Microsoft.Network/networkInterfaces/', '${nicName_var}worker${i}')
  ]
}]