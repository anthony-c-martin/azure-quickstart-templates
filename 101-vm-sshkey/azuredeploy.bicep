param projectName string {
  metadata: {
    description: 'Specifies a name for generating resource names.'
  }
}
param location string {
  metadata: {
    description: 'Specifies the location for all resources.'
  }
  default: resourceGroup().location
}
param adminUsername string {
  metadata: {
    description: 'Specifies a username for the Virtual Machine.'
  }
}
param adminPublicKey string {
  metadata: {
    description: 'Specifies the SSH rsa public key file as a string. Use "ssh-keygen -t rsa -b 2048" to generate your SSH key pairs.'
  }
}
param vmSize string {
  metadata: {
    description: 'description'
  }
  default: 'Standard_D2s_v3'
}

var vNetName = '${projectName}-vnet'
var vNetAddressPrefixes = '10.0.0.0/16'
var vNetSubnetName = 'default'
var vNetSubnetAddressPrefix = '10.0.0.0/24'
var vmName = '${projectName}-vm'
var publicIPAddressName = '${projectName}-ip'
var networkInterfaceName = '${projectName}-nic'
var networkSecurityGroupName = '${projectName}-nsg'
var networkSecurityGroupName2 = '${vNetSubnetName}-nsg'

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'ssh_rule'
        properties: {
          description: 'Locks inbound down to ssh default port 22.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 123
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  sku: {
    name: 'Basic'
  }
}

resource networkSecurityGroupName2_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName2
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

resource vNetName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNetAddressPrefixes
      ]
    }
    subnets: [
      {
        name: vNetSubnetName
        properties: {
          addressPrefix: vNetSubnetAddressPrefix
          networkSecurityGroup: {
            id: networkSecurityGroupName2_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    networkSecurityGroupName2_resource
  ]
}

resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: networkInterfaceName
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
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNetName, vNetSubnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
    vNetName_resource
    networkSecurityGroupName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'fromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    networkInterfaceName_resource
  ]
}