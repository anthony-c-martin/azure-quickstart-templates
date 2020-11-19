param storageAccountNamePrefix string {
  maxLength: 11
  metadata: {
    description: 'Unique DNS Name for the Storage Account where the Virtual Machine\'s disks will be placed.'
  }
}
param vmSize string {
  allowed: [
    'Standard_A0'
    'Standard_A1'
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
    'Standard_D1'
    'Standard_D2'
    'Standard_D3'
    'Standard_D4'
    'Standard_D11'
    'Standard_D12'
    'Standard_D13'
    'Standard_D14'
  ]
  metadata: {
    description: 'The size of the virtual machines used when provisioning the node.'
  }
  default: 'Standard_A1'
}
param openchainVersion string {
  allowed: [
    '0.6.2'
    '0.7.1'
  ]
  metadata: {
    description: 'The version of Openchain to deploy.'
  }
  default: '0.7.1'
}
param openchainAdminKey string {
  metadata: {
    description: 'The address of the administrator of the Openchain instance.'
  }
}
param adminUsername string {
  metadata: {
    description: 'Username for the Virtual Machine.'
  }
}
param dnsLabelPrefix string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Openchain instance.'
  }
}
param openPermissions string {
  allowed: [
    'true'
    'false'
  ]
  metadata: {
    description: 'If True, anyone can join the ledger after generating a key pair. If False, users must be granted permission to transact on the ledger (except for the admin).'
  }
  default: 'true'
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

var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var ubuntuOSVersion = '16.04-LTS'
var osDiskName = 'openchain-osdisk'
var nsgName = 'SecurityGroup'
var nicName = 'NIC'
var dockerExtensionName = 'Docker'
var scriptExtensionName = 'OpenchainInstallScript'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var storageAccountName = replace(replace(toLower(concat(storageAccountNamePrefix, uniqueString(resourceGroup().id))), '-', ''), '.', '')
var storageAccountType = 'Standard_LRS'
var publicIPAddressName = 'PublicIP'
var publicIPAddressType = 'Dynamic'
var vmStorageAccountContainerName = 'vhds'
var vmName = 'openchain'
var virtualNetworkName = 'VirtualNetwork'
var nsgID = nsgName_resource.id
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
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

resource nicName_resource 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
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

resource nsgName_resource 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'http'
        properties: {
          description: 'Allow HTTP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'ssh'
        properties: {
          description: 'Allow SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
    ]
  }
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
        publisher: imagePublisher
        offer: imageOffer
        sku: ubuntuOSVersion
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
          id: nicName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    storageAccountName_resource
    nicName_resource
  ]
}

resource vmName_dockerExtensionName 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName}/${dockerExtensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'DockerExtension'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {}
  }
  dependsOn: [
    vmName_resource
  ]
}

resource vmName_scriptExtensionName 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName}/${scriptExtensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/openchain-blockchain-coinprism/install_openchain.sh'
      ]
      commandToExecute: 'bash install_openchain.sh http://${publicIPAddressName_resource.properties.dnsSettings.fqdn}/ ${openchainVersion} ${openchainAdminKey} ${openPermissions}'
    }
  }
  dependsOn: [
    vmName_dockerExtensionName
  ]
}

output endpointURL string = 'http://${publicIPAddressName_resource.properties.dnsSettings.fqdn}/'
output instructions string = 'Connect to this endpoint using the wallet hosted at http://nossl.wallet.openchain.org/.'