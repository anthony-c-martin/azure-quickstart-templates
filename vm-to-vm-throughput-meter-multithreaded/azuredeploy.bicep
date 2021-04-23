@description('Size of the VM that runs the test.')
param probeVmSize string = 'Standard_A8m_v2'

@description('Size of the target VM.')
param targetVmSize string = 'Standard_A8m_v2'

@allowed([
  'Async'
  'Sync'
])
@description('Data transfer mode for NTttcp tool.')
param testDataTransferMode string = 'Async'

@allowed([
  '8k'
  '16k'
  '32k'
  '64k'
  '128k'
  '256k'
  '512k'
  '1m'
])
@description('Size of the send buffer for NTttcp tool.')
param testSendBufferSize string = '128k'

@allowed([
  '8k'
  '16k'
  '32k'
  '64k'
  '128k'
  '256k'
  '512k'
  '1m'
])
@description('Size of the receive buffer for NTttcp tool.')
param testReceiveBufferSize string = '64k'

@description('Number of posted send overlapped buffers for NTttcp tool.')
param testSendOverlappedBuffers int = 2

@description('Number of posted receive overlapped buffers for NTttcp tool.')
param testReceiveOverlappedBuffers int = 16

@description('Number of the sender threads for NTttcp tool.')
param testSenderThreadNumber int = 8

@description('Number of the receiver threads for NTttcp tool.')
param testReceiverThreadNumber int = 8

@description('Number of seconds for NTttcp tool test run.')
param testDurationSeconds int = 15

@description('Username for the probe and target VMs.')
param adminUsername string

@description('Password for the probe and target VMs.')
@secure()
param adminPassword string

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/vm-to-vm-throughput-meter-multithreaded'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

var OSDiskName = 'osdiskforwindowssimple'
var nicName = 'myVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var storageAccountType = 'Standard_LRS'
var publicIPAddressName = 'publicIP'
var publicIPAddressType = 'Dynamic'
var vmStorageAccountContainerName = 'vhds'
var virtualNetworkName_var = 'testVNET'
var scriptFolder = 'scripts'
var scriptFileName = 'tptest.ps1'
var vhdStorageAccountName = '${uniqueString(resourceGroup().id)}storage'
var osVersion = '2012-R2-Datacenter'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var vmName = [
  'probeVM'
  'targetVM'
]
var testMode = [
  'Sender'
  'Receiver'
]
var testBufferSize = [
  testSendBufferSize
  testReceiveBufferSize
]
var testOverlappedBuffers = [
  testSendOverlappedBuffers
  testReceiveOverlappedBuffers
]
var testThreadNumber = [
  testSenderThreadNumber
  testReceiverThreadNumber
]
var vmSize = [
  probeVmSize
  targetVmSize
]
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var networkSecurityGroupName_var = 'default-NSG'

resource vhdStorageAccountName_1 'Microsoft.Storage/storageAccounts@2016-01-01' = [for i in range(0, 2): {
  name: concat(vhdStorageAccountName, (i + 1))
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
}]

resource publicIPAddressName_1 'Microsoft.Network/publicIPAddresses@2015-06-15' = [for i in range(0, 2): {
  name: concat(publicIPAddressName, (i + 1))
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
  }
}]

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: virtualNetworkName_var
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
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource nicName_1 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, 2): {
  name: concat(nicName, (i + 1))
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', concat(publicIPAddressName, (i + 1)))
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    concat(publicIPAddressName, (i + 1))
    virtualNetworkName
  ]
}]

resource vmName_0 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, 2): {
  name: vmName[(i + 0)]
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize[(i + 0)]
    }
    osProfile: {
      computerName: vmName[(i + 0)]
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: osVersion
        version: 'latest'
      }
      osDisk: {
        name: '${vmName[(i + 0)]}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(nicName, (i + 1)))
        }
      ]
    }
  }
  dependsOn: [
    concat(vhdStorageAccountName, (i + 1))
    nicName_1
  ]
}]

resource vmName_0_CustomScriptExtension_1 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for i in range(0, 2): {
  name: '${vmName[(i + 0)]}/CustomScriptExtension${(i + 1)}'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.8'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, '${scriptFolder}/${scriptFileName}${artifactsLocationSasToken}')
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File ${scriptFileName} -ReceiverIP ${reference('${nicName}2').ipConfigurations[0].properties.privateIPAddress} -Mode ${testMode[(i + 0)]} -BufferSize ${testBufferSize[(i + 0)]} -OverlappedBuffers ${testOverlappedBuffers[(i + 0)]} -DataTransferMode ${testDataTransferMode} -ThreadNumber ${testThreadNumber[(i + 0)]} -Duration ${testDurationSeconds}'
    }
  }
  dependsOn: [
    vmName[(i + 0)]
  ]
}]

output Throughput_MB_s string = split(reference('CustomScriptExtension1').instanceView.substatuses[0].message, ' ')[0]
output Throughput_mbps string = split(reference('CustomScriptExtension1').instanceView.substatuses[0].message, ' ')[1]
output Throughput_buffers_s string = split(reference('CustomScriptExtension1').instanceView.substatuses[0].message, ' ')[2]