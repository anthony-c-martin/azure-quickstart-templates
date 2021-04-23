@description('The base URI where artifacts required by this template are located. For example, if stored on a public GitHub repo, you\'d use the following URI: https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/minecraft-on-ubuntu/.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/minecraft-on-ubuntu/'

@description('The sasToken required to access _artifactsLocation.  If your artifacts are stored on a public repo or public storage account you can leave this blank.')
@secure()
param artifactsLocationSasToken string = ''

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('Admin user name you will use to log on to the Virtual Machine.')
param adminUsername string

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@allowed([
  '0'
  '1'
  '2'
  '3'
])
@description('0 - Peaceful, 1 - Easy, 2 - Normal, 3 - Hard')
param difficulty string = '1'

@description('Put a unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsNameForPublicIP string

@allowed([
  'false'
  'true'
])
@description('enable command blocks')
param enable_command_block string = 'false'

@allowed([
  '0'
  '1'
  '2'
  '3'
])
@description('0 - Survival, 1 - Creative, 2 - Adventure, 3 - Spectator')
param gamemode string = '0'

@allowed([
  'false'
  'true'
])
@description('Generates villages etc.')
param generate_structures string = 'true'

@description('Name of your world')
param level_name string = 'world'

@description('Add a seed for your world')
param level_seed string = ' '

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Your Minecraft user name')
param minecraftUser string

@allowed([
  'false'
  'true'
])
@description('Enables monster spawning')
param spawn_monsters string = 'true'

@description('This is the Azure Virtual Machine size, and will affect the cost. If you don\'t know, just leave the default value.')
param virtualMachineSize string = 'Standard_A1'

@allowed([
  'false'
  'true'
])
@description('Only ops and whitelisted players can connect')
param white_list string = 'false'

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
var networkSecurityGroupName_var = '${lowerCaseDNSName}nsg'
var nicName_var = 'minecraftvmnic'
var publicIPAddressName_var = 'minecraftpublicip'
var publicIPAddressType = 'Dynamic'
var subnetName = 'subnet'
var subnetPrefix = '10.0.0.0/24'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var ubuntuOSVersion = '18.04-LTS'
var virtualNetworkName_var = 'minecraftvnet'
var vmName_var = 'minecraftvm'

resource vmName_newuserscript 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  parent: vmName
  name: 'newuserscript'
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
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName_var
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

resource nicName 'Microsoft.Network/networkInterfaces@2020-05-01' = {
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
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: lowerCaseDNSName
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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

resource vmName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
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
          id: nicName.id
        }
      ]
    }
  }
}