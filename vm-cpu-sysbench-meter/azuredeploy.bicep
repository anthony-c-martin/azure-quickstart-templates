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
  default: 'Standard_A5'
}
param maxPrimeNumberForTest int {
  metadata: {
    description: 'Limit for for prime number test.'
  }
  default: 20000
}
param threadsToRunTest int {
  minValue: 1
  maxValue: 100
  metadata: {
    description: 'Number of threads for the test to run.'
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
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/vm-cpu-sysbench-meter'
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
var OSDiskName = 'osdiskforwindowssimple'
var nicName_var = 'testVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var storageAccountType = 'Standard_LRS'
var publicIPAddressName_var = 'publicIP'
var vmStorageAccountContainerName = 'vhds'
var virtualNetworkName_var = 'testVNET'
var scriptFolder = 'scripts'
var vhdStorageAccountName_var = '${uniqueString(resourceGroup().id)}storage'
var frontEndNSGName_var = 'webtestnsg-${uniqueString(resourceGroup().id)}'
var vmName_var = 'testVM'
var testScriptFileName = 'cputest.sh'
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

resource vhdStorageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: vhdStorageAccountName_var
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
    vhdStorageAccountName
  ]
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
        '${artifactsLocation}/${scriptFolder}/${testScriptFileName}${artifactsLocationSasToken}'
      ]
      commandToExecute: 'sudo bash ${testScriptFileName} ${threadsToRunTest} ${maxPrimeNumberForTest}'
    }
  }
  dependsOn: [
    vmName
  ]
}

output totaltime string = split(split(reference('CustomScriptExtension').instanceView.statuses[0].message, '\n')[2], ' ')[0]
output perrequestmin string = split(split(reference('CustomScriptExtension').instanceView.statuses[0].message, '\n')[2], ' ')[1]
output perrequestavg string = split(split(reference('CustomScriptExtension').instanceView.statuses[0].message, '\n')[2], ' ')[2]
output perrequestmax string = split(split(reference('CustomScriptExtension').instanceView.statuses[0].message, '\n')[2], ' ')[3]
output perrequest95percentile string = split(split(reference('CustomScriptExtension').instanceView.statuses[0].message, '\n')[2], ' ')[4]