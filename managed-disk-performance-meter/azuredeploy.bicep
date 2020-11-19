param vmSize string {
  allowed: [
    'Standard_A5'
    'Standard_A8'
    'Standard_D4'
    'Standard_D14'
    'Standard_DS3'
    'Standard_DS14'
    'Standard_D3_v2'
    'Standard_D15_v2'
    'Standard_DS3_v2'
    'Standard_DS15_v2'
  ]
  metadata: {
    description: 'Size of the VM that runs the test.'
  }
  default: 'Standard_DS3'
}
param dataDiskHostCaching string {
  allowed: [
    ''
    'ReadOnly'
    'ReadWrite'
  ]
  metadata: {
    description: 'Data disk caching type for the test disk'
  }
  default: 'ReadOnly'
}
param diskSizeGB string {
  allowed: [
    '128'
    '512'
    '1023'
  ]
  metadata: {
    description: 'Disk size in GB'
  }
  default: '1023'
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
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/managed-disk-performance-meter'
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
  default: 'sshPublicKey'
}
param adminPasswordOrKey string {
  metadata: {
    description: 'SSH Key or password for the Virtual Machine. SSH key is recommended.'
  }
  secure: true
}

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
      dataDisks: [
        {
          diskSizeGB: diskSizeGB
          lun: 0
          caching: dataDiskHostCaching
          createOption: 'Empty'
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
        storageUri: concat(reference(storageAccountName_var, '2016-01-01').primaryEndpoints.blob)
      }
    }
  }
}

resource vmName_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName_var}/CustomScriptExtension'
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