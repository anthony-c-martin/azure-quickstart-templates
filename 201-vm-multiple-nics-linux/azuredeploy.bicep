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

var storageAccountName_var = '${uniqueString(resourceGroup().id)}samultinic'
var storageAccountType = 'Standard_LRS'
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var sshKeyPath = '/home/${adminUsername}/.ssh/authorized_keys'
var nic1Name_var = 'nic1'
var nic2Name_var = 'nic2'
var vnetName_var = 'vnet'
var vnetId = vnetName.id
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Frontend'
var subnet1Id = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnet1Name)
var subnet1Prefix = '10.0.1.0/24'
var subnet1PrivateAddress = '10.0.1.5'
var subnet2Name = 'Web'
var subnet2Id = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnet2Name)
var subnet2Prefix = '10.0.2.0/24'
var subnet2PrivateAddress = '10.0.2.5'
var publicIPAddressName_var = '${uniqueString(resourceGroup().id)}PublicIp'
var publicIPAddressType = 'Dynamic'
var publicIPAddressId = publicIPAddressName.id
var networkSecurityGroupName_var = 'default-NSG'

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  location: location
  name: storageAccountName_var
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName_var
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

resource vnetName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  location: location
  name: vnetName_var
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
            id: networkSecurityGroupName.id
          }
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2Prefix
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  location: location
  name: publicIPAddressName_var
  properties: {
    dnsSettings: {
      domainNameLabel: vmName
    }
    idleTimeoutInMinutes: 30
    publicIPAllocationMethod: publicIPAddressType
  }
}

resource nic1Name 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  location: location
  name: nic1Name_var
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: subnet1PrivateAddress
          privateIPAllocationMethod: 'Static'
          publicIPAddress: {
            id: publicIPAddressId
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

resource nic2Name 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  location: location
  name: nic2Name_var
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

resource vmName_res 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  location: location
  name: vmName
  properties: {
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(storageAccountName.id, '2019-06-01').primaryEndpoints.blob
      }
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic1Name.id
          properties: {
            primary: true
          }
        }
        {
          id: nic2Name.id
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
}

output sshCommand string = 'ssh ${adminUsername}@${vmName}.${location}.cloudapp.azure.com'