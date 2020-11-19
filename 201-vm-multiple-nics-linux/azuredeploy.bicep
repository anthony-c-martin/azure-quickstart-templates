param adminUsername string {
  metadata: {
    description: 'User name for the Virtual Machine.'
  }
  default: 'azureuser'
}
param sshKeyData string {
  metadata: {
    description: 'SSH rsa public key file as a string.'
  }
}
param vmName string {
  metadata: {
    description: 'Name of the VM'
  }
  default: 'multinicvm'
}
param vmSize string {
  metadata: {
    description: 'Size of the VM'
  }
  default: 'Standard_D2_v2'
}
param ubuntuOSVersion string {
  allowed: [
    '12.04.5-LTS'
    '14.04.4-LTS'
    '15.10'
    '18.04-LTS'
  ]
  metadata: {
    description: 'The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version. Allowed values: 12.04.5-LTS, 14.04.4-LTS, 15.10, 18.04-LTS.'
  }
  default: '18.04-LTS'
}
param location string {
  metadata: {
    description: 'description'
  }
  default: resourceGroup().location
}

var storageAccountName = '${uniqueString(resourceGroup().id)}samultinic'
var storageAccountType = 'Standard_LRS'
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var sshKeyPath = '/home/${adminUsername}/.ssh/authorized_keys'
var nic1Name = 'nic1'
var nic2Name = 'nic2'
var vnetName = 'vnet'
var vnetId = vnetName_resource.id
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Frontend'
var subnet1Id = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnet1Name)
var subnet1Prefix = '10.0.1.0/24'
var subnet1PrivateAddress = '10.0.1.5'
var subnet2Name = 'Web'
var subnet2Id = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnet2Name)
var subnet2Prefix = '10.0.2.0/24'
var subnet2PrivateAddress = '10.0.2.5'
var publicIPAddressName = '${uniqueString(resourceGroup().id)}PublicIp'
var publicIPAddressType = 'Dynamic'
var publicIPAddressId = publicIPAddressName_resource.id
var networkSecurityGroupName = 'default-NSG'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  location: location
  name: storageAccountName
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
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

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  location: location
  name: vnetName
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
          networkSecurityGroup: {
            id: networkSecurityGroupName_resource.id
          }
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2Prefix
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

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  location: location
  name: publicIPAddressName
  properties: {
    dnsSettings: {
      domainNameLabel: vmName
    }
    idleTimeoutInMinutes: 30
    publicIPAllocationMethod: publicIPAddressType
  }
}

resource nic1Name_resource 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  location: location
  name: nic1Name
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: subnet1PrivateAddress
          privateIPAllocationMethod: 'Static'
          PublicIpAddress: {
            Id: publicIPAddressId
          }
          subnet: {
            id: subnet1Id
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetId
    publicIPAddressId
  ]
}

resource nic2Name_resource 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  location: location
  name: nic2Name
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig2'
        properties: {
          privateIPAddress: subnet2PrivateAddress
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnet2Id
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetId
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  location: location
  name: vmName
  properties: {
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(storageAccountName_resource.id, '2019-06-01').primaryEndpoints.blob
      }
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic1Name_resource.id
          properties: {
            primary: true
          }
        }
        {
          id: nic2Name_resource.id
          properties: {
            primary: false
          }
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: sshKeyPath
              keyData: sshKeyData
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: ubuntuOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
  }
  dependsOn: [
    storageAccountName_resource
    nic1Name_resource
    nic2Name_resource
  ]
}

output sshCommand string = 'ssh ${adminUsername}@${vmName}.${location}.cloudapp.azure.com'