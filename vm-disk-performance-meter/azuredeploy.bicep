param vmSize string {
  metadata: {
    description: 'Size of the VM that runs the test.'
  }
  default: 'Standard_D2s_v3'
}
param dataDiskStorageAccountType string {
  allowed: [
    'Standard_LRS'
    'Premium_LRS'
    'StandardSSD_LRS'
    'UltraSSD_LRS'
  ]
  metadata: {
    description: 'Storage Account type for the test disk'
  }
  default: 'StandardSSD_LRS'
}
param dataDiskHostCaching string {
  allowed: [
    'None'
    'ReadOnly'
    'ReadWrite'
  ]
  metadata: {
    description: 'Data disk caching type for the test disk'
  }
  default: 'ReadOnly'
}
param testType string {
  allowed: [
    'read'
    'write'
    'randread'
    'randwrite'
    'randtrim'
    'rw'
    'readwrite'
    'randrw'
  ]
  metadata: {
    description: 'Disk test type to run. (rand: random, sequential otherwise; rw - read/write)'
  }
  default: 'randread'
}
param testSize string {
  allowed: [
    '32m'
    '64m'
    '128m'
    '256m'
    '512m'
    '1g'
    '2g'
    '10g'
    '30g'
  ]
  metadata: {
    description: 'Size of the file to test.'
  }
  default: '1g'
}
param testBlockSize string {
  allowed: [
    '4k'
    '8k'
    '16k'
    '32k'
    '64k'
  ]
  metadata: {
    description: 'Size of the block to test.'
  }
  default: '8k'
}
param secondsToRunTest int {
  metadata: {
    description: 'Number of seconds for the test to run.'
  }
  default: 30
}
param threadsToRunTest int {
  minValue: 1
  maxValue: 10
  metadata: {
    description: 'Number of worker threads for the test to run.'
  }
  default: 4
}
param adminUsername string {
  metadata: {
    description: 'Username for the test VMs.'
  }
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/vm-disk-performance-meter/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param authenticationType string {
  allowed: [
    'sshPublicKey'
    'password'
  ]
  metadata: {
    description: 'Type of authentication to use on the Virtual Machine. SSH key is recommended.'
  }
  default: 'password'
}
param adminPasswordOrKey string {
  metadata: {
    description: 'SSH Key or password for the Virtual Machine. SSH key is recommended.'
  }
  secure: true
}

var osVersion = '18.04-LTS'
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var nicName = 'testVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressName = 'publicIP'
var virtualNetworkName = 'testVNET'
var scriptFolder = 'scripts'
var frontEndNSGName = 'webtestnsg-${uniqueString(resourceGroup().id)}'
var vmName = 'testVM'
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

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: virtualNetworkName
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

resource nicName_resource 'Microsoft.Network/networkInterfaces@2019-11-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName_resource.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
    virtualNetworkName_resource
  ]
}

resource frontEndNSGName_resource 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: frontEndNSGName
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
    publicIPAddressName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
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
        name: '${vmName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          name: '${vmName}_DataDisk'
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
          id: nicName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    nicName_resource
  ]
}

resource vmName_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  name: '${vmName}/CustomScriptExtension'
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
  dependsOn: [
    vmName_resource
  ]
}

output testresult string = trim(split(reference('CustomScriptExtension').instanceView.statuses[0].message, '\n')[2])