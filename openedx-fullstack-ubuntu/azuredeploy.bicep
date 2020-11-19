param adminUsername string {
  metadata: {
    description: 'Administrator username.'
  }
  default: 'openedxuser'
}
param dnsLabelPrefix string {
  metadata: {
    description: 'DNS Label for the Public IP. Must be lowercase. It should match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.'
  }
}
param vmSize string {
  allowed: [
    'Standard_A2'
    'Standard_A3'
    'Standard_A4'
    'Standard_A5'
    'Standard_A6'
    'Standard_A7'
    'Standard_A8'
    'Standard_A9'
    'Standard_A10'
    'Standard_A11'
    'Standard_D2'
    'Standard_D3'
    'Standard_D4'
    'Standard_D11'
    'Standard_D12'
    'Standard_D13'
    'Standard_D14'
    'Standard_D2_v2'
    'Standard_D3_v2'
    'Standard_D4_v2'
    'Standard_D5_v2'
    'Standard_D11_v2'
    'Standard_D12_v2'
    'Standard_D13_v2'
    'Standard_D14_v2'
    'Standard_D15_v2'
  ]
  metadata: {
    description: 'Virtual machine size.'
  }
  default: 'Standard_D3_v2'
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

var openedxVersion = 'open-release/ficus.master'
var scriptDownloadUri = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/openedx-fullstack-ubuntu/'
var installScript = 'install-openedx.sh'
var installCommand = 'bash -c \'nohup ./${installScript} ${openedxVersion} </dev/null &>/var/log/azure/openedx-install.log &\''
var vmName = 'jumpbox2'
var osImagePublisher = 'Canonical'
var osImageOffer = 'UbuntuServer'
var osImageSKU = '16.04-LTS'
var publicIPAddressName = 'myPublicIP'
var publicIPAddressType = 'Dynamic'
var virtualNetworkName = 'VNET'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var subnetName = 'Subnet'
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var nsgName = 'node-nsg'
var nsgID = nsgName_resource.id
var storageAccountType = 'Standard_LRS'
var storageAccountName = '${uniqueString(resourceGroup().id)}vhdsa'
var vhdBlobContainer = 'vhds'
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

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageAccountName
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-06-15' = {
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
          networkSecurityGroup: {
            id: nsgID
          }
        }
      }
    ]
  }
  dependsOn: [
    nsgID
  ]
}

resource nsgName_resource 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'ssh'
        properties: {
          description: 'SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'LMS'
        properties: {
          description: 'HTTP for Open edX LMS'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 201
          direction: 'Inbound'
        }
      }
      {
        name: 'CMS'
        properties: {
          description: 'HTTP for Open edX CMS'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '18010'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 203
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vmName_nic 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfigNode'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName_resource.id
          }
          subnet: {
            id: subnetRef
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

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
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
        publisher: osImagePublisher
        offer: osImageOffer
        sku: osImageSKU
        version: 'latest'
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
          id: vmName_nic.id
        }
      ]
    }
  }
  dependsOn: [
    storageAccountName_resource
    'Microsoft.Network/networkInterfaces/${vmName}-nic'
  ]
}

resource vmName_installscript 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName}/installscript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        concat(scriptDownloadUri, installScript)
        '${scriptDownloadUri}server-vars.yml'
      ]
      commandToExecute: installCommand
    }
  }
  dependsOn: [
    vmName_resource
  ]
}