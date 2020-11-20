param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located.'
  }
  default: deployment().properties.templateLink.uri
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation when they\'re located in a storage account with private access.'
  }
  secure: true
  default: ''
}
param vmName string {
  metadata: {
    description: 'VM Name'
  }
  default: 'VM'
}
param vmSize string {
  metadata: {
    description: 'VM Size'
  }
  default: 'Standard_D2_v3'
}
param adminUsername string {
  metadata: {
    description: 'Administrator name'
  }
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

var vnetName_var = 'vnet'
var vNetAddressSpace = '10.0.0.0/16'
var subnetName = 'subnet01'
var subnetAdressPrefix = '10.0.0.0/24'
var subnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetName)
var asgName_var = 'webServersAsg'
var asgId = asgName.id
var nsgName_var = 'webNsg'
var nsgId = nsgName.id
var pipName_var = 'webServerPip'
var pipId = pipName.id
var imageInfo = {
  publisher: 'OpenLogic'
  offer: 'CentOS'
  sku: '6.9'
  version: 'latest'
}
var vmStorageType = 'Standard_LRS'
var scriptUrl = uri(artifactsLocation, 'install_nginx.sh${artifactsLocationSasToken}')
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

resource asgName 'Microsoft.Network/applicationSecurityGroups@2020-05-01' = {
  name: asgName_var
  location: location
  properties: {}
}

resource nsgName 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: nsgName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHttpAll'
        properties: {
          description: 'Allow http traffic to web servers'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          direction: 'Inbound'
          access: 'Allow'
          priority: 100
          protocol: 'Tcp'
          destinationPortRange: '80'
          destinationApplicationSecurityGroups: [
            {
              id: asgId
            }
          ]
        }
      }
      {
        name: 'AllowSshAll'
        properties: {
          description: 'Allow SSH traffic to web servers'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          direction: 'Inbound'
          access: 'Allow'
          priority: 200
          protocol: 'Tcp'
          destinationPortRange: '22'
          destinationApplicationSecurityGroups: [
            {
              id: asgId
            }
          ]
        }
      }
    ]
  }
}

resource vNetName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnetName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNetAddressSpace
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAdressPrefix
          networkSecurityGroup: {
            id: nsgId
          }
        }
      }
    ]
  }
}

resource pipName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: pipName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource vmName_NIC 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: '${vmName}-NIC'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pipId
          }
          subnet: {
            id: subnetId
          }
          applicationSecurityGroups: [
            {
              id: asgId
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    vNetName
  ]
}

resource vmName_res 'Microsoft.Compute/virtualMachines@2020-06-01' = {
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
      imageReference: imageInfo
      osDisk: {
        name: '${vmName}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: vmStorageType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmName_NIC.id
        }
      ]
    }
  }
}

resource vmName_linuxconfig 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${vmName}/linuxconfig'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        scriptUrl
      ]
      commandToExecute: 'sh install_nginx.sh'
    }
  }
  dependsOn: [
    vmName_res
  ]
}