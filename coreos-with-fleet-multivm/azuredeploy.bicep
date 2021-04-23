@description('Name of the storage account for VM OS Disks')
param newStorageAccountName string = 'storageaccount'

@allowed([
  'Standard_A1'
  'Standard_A2'
  'Standard_A3'
  'Standard_A4'
])
@description('Instance size for the VMs')
param vmSize string = 'Standard_A1'

@description('Number of compute nodes to create (3+ recommended)')
param numberOfNodes int = 3

@description('Username to login to the VMs')
param adminUsername string = 'core'

@description('Public key for SSH authentication')
param sshKeyData string

@description('discoveryUrl for etcd2 cluster')
param discoveryUrl string

@description('Location for all resources.')
param location string = resourceGroup().location

var virtualNetworkName_var = 'ClusterVNET'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var publicIPAddressType = 'Dynamic'
var vnetID = virtualNetworkName.id
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var vmNamePrefix_var = 'coreos'
var imageSku = 'Stable'
var storageAccountType = 'Standard_LRS'
var sshKeyPath = '/home/${adminUsername}/.ssh/authorized_keys'
var unitFile = '#cloud-config\n\ncoreos:\n  etcd2:\n    discovery: ${discoveryUrl}\n    advertise-client-urls: http://$private_ipv4:2379,http://$private_ipv4:4001\n    initial-advertise-peer-urls: http://$private_ipv4:2380\n    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001\n    listen-peer-urls: http://$private_ipv4:2380\n  units:\n    - name: etcd2.service\n      command: start\n    - name: fleet.service\n      command: start'
var networkSecurityGroupName_var = 'default-NSG'

resource newStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-05-01-preview' = {
  name: newStorageAccountName
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = [for i in range(0, numberOfNodes): {
  name: 'publicIP${i}'
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
  }
}]

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
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

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
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
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = [for i in range(0, numberOfNodes): {
  name: 'nic${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIpAddresses', 'publicIP${i}')
          }
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
  dependsOn: [
    'Microsoft.Network/publicIPAddresses/publicIP${i}'
    virtualNetworkName
  ]
}]

resource vmNamePrefix 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, numberOfNodes): {
  name: concat(vmNamePrefix_var, i)
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(vmNamePrefix_var, i)
      adminUsername: adminUsername
      customData: base64(unitFile)
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
        publisher: 'CoreOS'
        offer: 'CoreOS'
        sku: imageSku
        version: 'latest'
      }
      osDisk: {
        name: '${vmNamePrefix_var}${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'nic${i}')
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccountName_resource
    'Microsoft.Network/networkInterfaces/nic${i}'
  ]
}]