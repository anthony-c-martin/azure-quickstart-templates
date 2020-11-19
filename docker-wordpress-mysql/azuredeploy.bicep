param newStorageAccountName string {
  metadata: {
    description: 'Unique DNS Name for the Storage Account where the Virtual Machine\'s disks will be placed.'
  }
}
param mysqlPassword string {
  metadata: {
    description: 'Root password password for the MySQL database.'
  }
  secure: true
}
param adminUsername string {
  metadata: {
    description: 'Username for the Virtual Machine.'
  }
}
param dnsNameForPublicIP string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Virtual Machine.'
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
  default: 'sshPublicKey'
}
param adminPasswordOrKey string {
  metadata: {
    description: 'SSH Key or password for the Virtual Machine. SSH key is recommended.'
  }
  secure: true
}
param vmSize string {
  metadata: {
    description: 'Size of the virtual machine.'
  }
  default: 'Standard_D1_v2'
}

var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var ubuntuOSVersion = '18.04-LTS'
var nsgName = 'myNSG'
var nicName = 'myVMNic'
var extensionName = 'DockerExtension'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var storageAccountType = 'Standard_LRS'
var publicIPAddressName = 'myPublicIP'
var publicIPAddressType = 'Dynamic'
var vmName = 'MyDockerVM'
var virtualNetworkName = 'MyVNET'
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

resource newStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: newStorageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
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

resource nsgName_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
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

resource vmName_resource 'Microsoft.Compute/virtualMachines@2020-06-01' = {
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
    newStorageAccountName_resource
    nicName_resource
  ]
}

resource vmName_extensionName 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${vmName}/${extensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'DockerExtension'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      environment: {
        MYSQL_ROOT_PASSWORD: mysqlPassword
      }
    }
    settings: {
      compose: {
        db: {
          image: 'mysql'
          ports: [
            '3306:3306'
          ]
          volumes: [
            '/var/lib/mysql:/var/lib/mysql'
          ]
          environment: [
            'MYSQL_ROOT_PASSWORD'
          ]
        }
        wordpress: {
          image: 'wordpress'
          ports: [
            '80:80'
          ]
          links: [
            'db:mysql'
          ]
        }
      }
    }
  }
  dependsOn: [
    vmName_resource
  ]
}