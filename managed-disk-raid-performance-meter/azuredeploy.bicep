@allowed([
  'Standard_A5'
  'Standard_A8'
  'Standard_D4'
  'Standard_D14'
  'Standard_DS4'
  'Standard_DS14'
  'Standard_D3_v2'
  'Standard_D15_v2'
  'Standard_DS3_v2'
  'Standard_DS15_v2'
])
@description('Size of the VM that runs the test.')
param vmSize string = 'Standard_DS4'

@allowed([
  ''
  'ReadOnly'
  'ReadWrite'
])
@description('Data disk caching type for the test disk.')
param dataDiskHostCaching string = 'ReadOnly'

@allowed([
  '128'
  '512'
  '1023'
])
@description('Disk size in GB.')
param diskSizeGB string = '1023'

@minValue(1)
@maxValue(10)
@description('Number of disks striped in RAID. Should not be greater than selected instance type allows.')
param disksInRAID int = 5

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
@description('Disk test type to run. (rand: random, sequential otherwise; rw - read/write).')
param testType string = 'write'

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
  '128k'
  '256k'
])
@description('Size of the block to test.')
param testBlockSize string = '64k'

@description('Number of seconds for the test to run.')
param secondsToRunTest int = 30

@minValue(1)
@maxValue(10)
@description('Number of worker threads for the test to run.')
param threadsToRunTest int = 8

@description('Username for the test VMs.')
param adminUsername string

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/managed-disk-raid-performance-meter'

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
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var osVersion = '14.04.5-LTS'
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var nicName_var = 'testVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var storageAccountType = 'Standard_LRS'
var publicIPAddressName_var = 'publicIP'
var virtualNetworkName_var = 'testVNET'
var scriptFolder = 'scripts'
var storageAccountName_var = '${uniqueString(resourceGroup().id)}storage'
var frontEndNSGName_var = 'webtestnsg-${uniqueString(resourceGroup().id)}'
var vmName_var = 'testVM'
var testScriptFileName = 'disktest.sh'
var diskArray = [
  {
    diskSizeGB: diskSizeGB
    lun: 0
    caching: dataDiskHostCaching
    createOption: 'Empty'
  }
  {
    diskSizeGB: diskSizeGB
    lun: 1
    caching: dataDiskHostCaching
    createOption: 'Empty'
  }
  {
    diskSizeGB: diskSizeGB
    lun: 2
    caching: dataDiskHostCaching
    createOption: 'Empty'
  }
  {
    diskSizeGB: diskSizeGB
    lun: 3
    caching: dataDiskHostCaching
    createOption: 'Empty'
  }
  {
    diskSizeGB: diskSizeGB
    lun: 4
    caching: dataDiskHostCaching
    createOption: 'Empty'
  }
  {
    diskSizeGB: diskSizeGB
    lun: 5
    caching: dataDiskHostCaching
    createOption: 'Empty'
  }
  {
    diskSizeGB: diskSizeGB
    lun: 6
    caching: dataDiskHostCaching
    createOption: 'Empty'
  }
  {
    diskSizeGB: diskSizeGB
    lun: 7
    caching: dataDiskHostCaching
    createOption: 'Empty'
  }
  {
    diskSizeGB: diskSizeGB
    lun: 8
    caching: dataDiskHostCaching
    createOption: 'Empty'
  }
  {
    diskSizeGB: diskSizeGB
    lun: 9
    caching: dataDiskHostCaching
    createOption: 'Empty'
  }
]
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

resource storageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
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
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2015-06-15' = {
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

resource frontEndNSGName 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
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

resource vmName 'Microsoft.Compute/virtualMachines@2016-04-30-preview' = {
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
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: take(diskArray, disksInRAID)
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
        storageUri: concat(reference(storageAccountName_var, '2016-01-01').primaryEndpoints.blob)
      }
    }
  }
  dependsOn: [
    storageAccountName
  ]
}

resource vmName_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
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
        '${artifactsLocation}/${scriptFolder}/${testScriptFileName}${artifactsLocationSasToken}'
      ]
      commandToExecute: 'sudo bash ${testScriptFileName} ${testSize} ${testType} ${secondsToRunTest} ${threadsToRunTest} ${testBlockSize} ${disksInRAID}'
    }
  }
}

output testresult string = trim(split(reference('CustomScriptExtension').instanceView.statuses[0].message, '\n')[2])