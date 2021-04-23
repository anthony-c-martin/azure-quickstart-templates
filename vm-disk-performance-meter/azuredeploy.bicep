@description('Size of the VM that runs the test.')
param vmSize string = 'Standard_D2s_v3'

@allowed([
  'Standard_LRS'
  'Premium_LRS'
  'StandardSSD_LRS'
  'UltraSSD_LRS'
])
@description('Storage Account type for the test disk')
param dataDiskStorageAccountType string = 'StandardSSD_LRS'

@allowed([
  'None'
  'ReadOnly'
  'ReadWrite'
])
@description('Data disk caching type for the test disk')
param dataDiskHostCaching string = 'ReadOnly'

@allowed([
  'read'
  'write'
  'randread'
  'randwrite'
  'randtrim'
  'rw'
  'readwrite'
  'randrw'
])
@description('Disk test type to run. (rand: random, sequential otherwise; rw - read/write)')
param testType string = 'randread'

@allowed([
  '32m'
  '64m'
  '128m'
  '256m'
  '512m'
  '1g'
  '2g'
  '10g'
  '30g'
])
@description('Size of the file to test.')
param testSize string = '1g'

@allowed([
  '4k'
  '8k'
  '16k'
  '32k'
  '64k'
])
@description('Size of the block to test.')
param testBlockSize string = '8k'

@description('Number of seconds for the test to run.')
param secondsToRunTest int = 30

@minValue(1)
@maxValue(10)
@description('Number of worker threads for the test to run.')
param threadsToRunTest int = 4

@description('Username for the test VMs.')
param adminUsername string

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/vm-disk-performance-meter/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var osVersion = '18.04-LTS'
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var nicName_var = 'testVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressName_var = 'publicIP'
var virtualNetworkName_var = 'testVNET'
var scriptFolder = 'scripts'
var frontEndNSGName_var = 'webtestnsg-${uniqueString(resourceGroup().id)}'
var vmName_var = 'testVM'
var testScriptFileName = 'disktest.sh'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2019-11-01' = {
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
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2019-11-01' = {
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
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource frontEndNSGName 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: frontEndNSGName_var
  location: location
  tags: {
    displayName: 'NSG'
  }
  properties: {
    securityRules: [
      {
        name: 'ssh-rule'
        properties: {
          description: 'Allow SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: osVersion
        version: 'latest'
      }
      osDisk: {
        name: '${vmName_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          name: '${vmName_var}_DataDisk'
          diskSizeGB: 1023
          lun: 0
          caching: dataDiskHostCaching
          createOption: 'Empty'
          managedDisk: {
            storageAccountType: dataDiskStorageAccountType
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
  }
}

resource vmName_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  parent: vmName
  name: 'CustomScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.OSTCExtensions'
    type: 'CustomScriptForLinux'
    typeHandlerVersion: '1.5'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, '${scriptFolder}/${testScriptFileName}${artifactsLocationSasToken}')
      ]
      commandToExecute: 'sudo bash ${testScriptFileName} ${testSize} ${testType} ${secondsToRunTest} ${threadsToRunTest} ${testBlockSize}'
    }
  }
}

output testresult string = trim(split(reference('CustomScriptExtension').instanceView.statuses[0].message, '\n')[2])