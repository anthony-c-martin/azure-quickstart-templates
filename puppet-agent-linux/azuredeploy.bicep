param vmSize string {
  allowed: [
    'Standard_A1'
    'Standard_A2'
    'Standard_A3'
    'Standard_A4'
    'Standard_D1'
    'Standard_D2'
    'Standard_D3'
    'Standard_D4'
  ]
  metadata: {
    description: 'Size of vm, e.g: Standard_D2'
  }
  default: 'Standard_D2'
}
param username string {
  metadata: {
    description: 'Username for the Virtual Machine, e.g: joetheadmin.'
  }
}
param newStorageAccountName string {
  metadata: {
    description: 'Unique DNS prefix for the Storage Account where the Virtual Machine\'s disks will be placed.'
  }
}
param dnsNameForPublicIP string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Virtual Machine.'
  }
}
param pupmstrFQDN string {
  metadata: {
    description: 'FQDN of your PE box, e.g: pupmstr.cloudapp.net'
  }
  default: 'pupmstr.cloudapp.net'
}
param pupmstrIP string {
  metadata: {
    description: 'IP of your PE box, e.g: 192.168.1.1'
  }
  default: '192.168.1.1'
}
param pupmstrInternalFQDN string {
  metadata: {
    description: 'Internal FQDN of your PE box, e.g: pupmstr.pupmstr.d6.internal.cloudapp.net.  Get it from node requests page in PE Console.'
  }
  default: 'pupmstr.pupmstr.d6.internal.cloudapp.net'
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

var scenarioPrefix = 'puppetAgentLinux'
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var ubuntuOSVersion = '14.04.5-LTS'
var OSDiskName = '${scenarioPrefix}OSDisk'
var nicName = '${scenarioPrefix}Nic'
var vnetAddressPrefix = '10.0.0.0/16'
var subnetName = '${scenarioPrefix}Subnet'
var subnetPrefix = '10.0.0.0/24'
var storageAccountType = 'Standard_LRS'
var publicIPAddressName = '${scenarioPrefix}PublicIp'
var publicIPAddressType = 'Dynamic'
var vmStorageAccountContainerName = 'vhds'
var vmName = '${scenarioPrefix}VM'
var virtualNetworkName = '${scenarioPrefix}Vnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var fileUris = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/puppet-agent-linux/install_puppet_agent.sh'
var commandToExecute = './install_puppet_agent.sh ${pupmstrIP} ${pupmstrFQDN} ${pupmstrInternalFQDN}'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${username}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource newStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: newStorageAccountName
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
      domainNameLabel: dnsNameForPublicIP
    }
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
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

resource nicName_resource 'Microsoft.Network/networkInterfaces@2015-06-15' = {
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
      adminUsername: username
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
    newStorageAccountName_resource
    nicName_resource
  ]
}

resource vmName_installcustomscript 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName}/installcustomscript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: split(fileUris, ' ')
      commandToExecute: commandToExecute
    }
  }
  dependsOn: [
    vmName_resource
  ]
}