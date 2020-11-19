param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. For example, if stored on a public GitHub repo, you\'d use the following URI: https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/minecraft-on-ubuntu/.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/minecraft-on-ubuntu/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  If your artifacts are stored on a public repo or public storage account you can leave this blank.'
  }
  secure: true
  default: ''
}
param adminPasswordOrKey string {
  metadata: {
    description: 'SSH Key or password for the Virtual Machine. SSH key is recommended.'
  }
  secure: true
}
param adminUsername string {
  metadata: {
    description: 'Admin user name you will use to log on to the Virtual Machine.'
  }
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
param difficulty string {
  allowed: [
    '0'
    '1'
    '2'
    '3'
  ]
  metadata: {
    description: '0 - Peaceful, 1 - Easy, 2 - Normal, 3 - Hard'
  }
  default: '1'
}
param dnsNameForPublicIP string {
  metadata: {
    description: 'Put a unique DNS Name for the Public IP used to access the Virtual Machine.'
  }
}
param enable_command_block string {
  allowed: [
    'false'
    'true'
  ]
  metadata: {
    description: 'enable command blocks'
  }
  default: 'false'
}
param gamemode string {
  allowed: [
    '0'
    '1'
    '2'
    '3'
  ]
  metadata: {
    description: '0 - Survival, 1 - Creative, 2 - Adventure, 3 - Spectator'
  }
  default: '0'
}
param generate_structures string {
  allowed: [
    'false'
    'true'
  ]
  metadata: {
    description: 'Generates villages etc.'
  }
  default: 'true'
}
param level_name string {
  metadata: {
    description: 'Name of your world'
  }
  default: 'world'
}
param level_seed string {
  metadata: {
    description: 'Add a seed for your world'
  }
  default: ' '
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param minecraftUser string {
  metadata: {
    description: 'Your Minecraft user name'
  }
}
param spawn_monsters string {
  allowed: [
    'false'
    'true'
  ]
  metadata: {
    description: 'Enables monster spawning'
  }
  default: 'true'
}
param virtualMachineSize string {
  metadata: {
    description: 'This is the Azure Virtual Machine size, and will affect the cost. If you don\'t know, just leave the default value.'
  }
  default: 'Standard_A1'
}
param white_list string {
  allowed: [
    'false'
    'true'
  ]
  metadata: {
    description: 'Only ops and whitelisted players can connect'
  }
  default: 'false'
}

var addressPrefix = '10.0.0.0/16'
var imageOffer = 'UbuntuServer'
var imagePublisher = 'Canonical'
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
var lowerCaseDNSName = toLower(dnsNameForPublicIP)
var networkSecurityGroupName = '${lowerCaseDNSName}nsg'
var nicName = 'minecraftvmnic'
var publicIPAddressName = 'minecraftpublicip'
var publicIPAddressType = 'Dynamic'
var subnetName = 'subnet'
var subnetPrefix = '10.0.0.0/24'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var ubuntuOSVersion = '18.04-LTS'
var virtualNetworkName = 'minecraftvnet'
var vmName = 'minecraftvm'

resource vmName_newuserscript 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  name: '${vmName}/newuserscript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'install_minecraft.sh${artifactsLocationSasToken}')
      ]
      commandToExecute: 'bash install_minecraft.sh ${minecraftUser} ${difficulty} ${level_name} ${gamemode} ${white_list} ${enable_command_block} ${spawn_monsters} ${generate_structures} ${level_seed}'
    }
  }
  dependsOn: [
    vmName_resource
  ]
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'ssh'
        properties: {
          description: 'SSH port'
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
      {
        name: 'minecraft'
        properties: {
          description: 'Minecraft server port'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '25565'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2020-05-01' = {
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

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: lowerCaseDNSName
    }
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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
            id: networkSecurityGroupName_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    networkSecurityGroupName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
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
        caching: 'ReadWrite'
        createOption: 'FromImage'
        diskSizeGB: '100'
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
    nicName_resource
  ]
}