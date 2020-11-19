param newStorageAccountName string {
  metadata: {
    description: 'Name of new Storage Account that will hold VM OS disk'
  }
}
param adminUsername string {
  metadata: {
    description: 'Username assigned to new local user on VM'
  }
}
param vmDnsName string {
  metadata: {
    description: 'Hostname and Azure DNS name that the VM will be assigned'
  }
}
param githubClientKey string {
  metadata: {
    description: 'GitHub application client key required by the Drone CI components for synchronizing repositories'
  }
}
param githubSecret string {
  metadata: {
    description: 'GitHub application client secret required by the Drone CI components for synchronizing repositories'
  }
  secure: true
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

var nicName = 'myVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet-1'
var subnetPrefix = '10.0.0.0/24'
var storageAccountType = 'Standard_LRS'
var publicIPAddressName = 'myPublicIPTest'
var publicIPAddressType = 'Dynamic'
var vmStorageAccountContainerName = 'vhds'
var vmName = vmDnsName
var vmSize = 'Standard_A3'
var virtualNetworkName = 'droneCINET'
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
var networkSecurityGroupName = 'default-NSG'

resource newStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-05-01-preview' = {
  name: newStorageAccountName
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: vmDnsName
    }
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-22'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
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

resource nicName_resource 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
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
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '14.04.2-LTS'
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

resource vmName_DockerExtension 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  name: '${vmName}/DockerExtension'
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

resource vmName_installDrone 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  name: '${vmName}/installDrone'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/drone-ubuntu-vm/install_drone.sh'
      ]
      commandToExecute: 'sh install_drone.sh ${githubClientKey} ${githubSecret}'
    }
  }
  dependsOn: [
    vmName_resource
  ]
}