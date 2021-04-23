@description('The prefix of the HDInsight cluster name.')
param clusterNamePrefix string

@description('These credentials can be used to submit jobs to the cluster and to log into cluster dashboards.')
param clusterLoginUserName string

@description('The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter.')
@secure()
param clusterLoginPassword string

@description('These credentials can be used to remotely access the cluster.')
param sshUserName string

@description('The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter.')
@secure()
param sshPassword string

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'Standard_A4_v2'
  'Standard_A8_v2'
  'Standard_D1_v2'
  'Standard_D2_v2'
  'Standard_D3_v2'
  'Standard_D4_v2'
  'Standard_D5_v2'
  'Standard_D12_v2'
  'Standard_D13_v2'
])
@description('This is the headnode Azure Virtual Machine size, and will affect the cost. If you don\'t know, just leave the default value.')
param HeadNodeVirtualMachineSize string = 'Standard_D3_v2'

@allowed([
  'Standard_A4_v2'
  'Standard_A8_v2'
  'Standard_D1_v2'
  'Standard_D2_v2'
  'Standard_D3_v2'
  'Standard_D4_v2'
  'Standard_D5_v2'
  'Standard_D12_v2'
  'Standard_D13_v2'
])
@description('This is the worerdnode Azure Virtual Machine size, and will affect the cost. If you don\'t know, just leave the default value.')
param WorkerNodeVirtualMachineSize string = 'Standard_D3_v2'

@allowed([
  'Standard_A4_v2'
  'Standard_A8_v2'
  'Standard_D1_v2'
  'Standard_D2_v2'
  'Standard_D3_v2'
  'Standard_D4_v2'
  'Standard_D5_v2'
  'Standard_D12_v2'
  'Standard_D13_v2'
])
@description('This is the Zookeepernode Azure Virtual Machine size, and will affect the cost. If you don\'t know, just leave the default value.')
param ZookeeperNodeVirtualMachineSize string = 'Standard_D3_v2'

var clusterNode1 = {
  name: '${clusterNamePrefix}1'
  defaultStorageAccount: {
    name: uniqueString(resourceGroup().id)
    type: 'Standard_LRS'
  }
}
var clusterNode2 = {
  name: '${clusterNamePrefix}2'
  defaultStorageAccount: {
    name: uniqueString(resourceGroup().id, deployment().name)
    type: 'Standard_LRS'
  }
}
var vNet1 = {
  name: '${clusterNamePrefix}-vnet1'
  addressSpacePrefix: '10.1.0.0/16'
  subnetName: 'subnet1'
  subnetPrefix: '10.1.0.0/24'
  peeringName: '${clusterNamePrefix}-vnet1/PeeringToVNet2'
}
var vNet2 = {
  name: '${clusterNamePrefix}-vnet2'
  addressSpacePrefix: '10.2.0.0/16'
  subnetName: 'subnet1'
  subnetPrefix: '10.2.0.0/24'
  peeringName: '${clusterNamePrefix}-vnet2/PeeringToVNet1'
}

resource vNet1_name 'Microsoft.Network/virtualNetworks@2019-06-01' = {
  name: vNet1.name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNet1.addressSpacePrefix
      ]
    }
    subnets: [
      {
        name: vNet1.subnetName
        properties: {
          addressPrefix: vNet1.subnetPrefix
        }
      }
    ]
  }
}

resource vNet2_name 'Microsoft.Network/virtualNetworks@2019-06-01' = {
  name: vNet2.name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNet2.addressSpacePrefix
      ]
    }
    subnets: [
      {
        name: vNet2.subnetName
        properties: {
          addressPrefix: vNet2.subnetPrefix
        }
      }
    ]
  }
}

resource vNet1_peeringName 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-06-01' = {
  name: vNet1.peeringName
  location: location
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vNet2_name.id
    }
  }
  dependsOn: [
    vNet1_name
  ]
}

resource vNet2_peeringName 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-06-01' = {
  name: vNet2.peeringName
  location: location
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vNet1_name.id
    }
  }
  dependsOn: [
    vNet2_name
  ]
}

resource clusterNode1_defaultStorageAccount_name 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: clusterNode1.defaultStorageAccount.name
  location: location
  sku: {
    name: clusterNode1.defaultStorageAccount.type
  }
  kind: 'Storage'
  properties: {}
}

resource clusterNode1_name 'Microsoft.HDInsight/clusters@2018-06-01-preview' = {
  name: clusterNode1.name
  location: location
  tags: {}
  properties: {
    clusterVersion: '3.6'
    osType: 'Linux'
    clusterDefinition: {
      kind: 'hbase'
      configurations: {
        gateway: {
          'restAuthCredential.isEnabled': true
          'restAuthCredential.username': clusterLoginUserName
          'restAuthCredential.password': clusterLoginPassword
        }
      }
    }
    storageProfile: {
      storageaccounts: [
        {
          name: replace(replace(reference(clusterNode1_defaultStorageAccount_name.id, '2016-01-01').primaryEndpoints.blob, 'https://', ''), '/', '')
          isDefault: true
          container: clusterNode1.name
          key: listKeys(clusterNode1_defaultStorageAccount_name.id, '2016-01-01').keys[0].value
        }
      ]
    }
    computeProfile: {
      roles: [
        {
          name: 'headnode'
          targetInstanceCount: 2
          hardwareProfile: {
            vmSize: HeadNodeVirtualMachineSize
          }
          osProfile: {
            linuxOperatingSystemProfile: {
              username: sshUserName
              password: sshPassword
            }
          }
          virtualNetworkProfile: {
            id: vNet1_name.id
            subnet: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet1.name, vNet1.subnetName)
          }
        }
        {
          name: 'workernode'
          targetInstanceCount: 2
          hardwareProfile: {
            vmSize: WorkerNodeVirtualMachineSize
          }
          osProfile: {
            linuxOperatingSystemProfile: {
              username: sshUserName
              password: sshPassword
            }
          }
          virtualNetworkProfile: {
            id: vNet1_name.id
            subnet: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet1.name, vNet1.subnetName)
          }
        }
        {
          name: 'zookeepernode'
          targetInstanceCount: 3
          hardwareProfile: {
            vmSize: ZookeeperNodeVirtualMachineSize
          }
          osProfile: {
            linuxOperatingSystemProfile: {
              username: sshUserName
              password: sshPassword
            }
          }
          virtualNetworkProfile: {
            id: vNet1_name.id
            subnet: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet1.name, vNet1.subnetName)
          }
        }
      ]
    }
  }
}

resource clusterNode2_defaultStorageAccount_name 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: clusterNode2.defaultStorageAccount.name
  location: location
  sku: {
    name: clusterNode2.defaultStorageAccount.type
  }
  kind: 'Storage'
  properties: {}
}

resource clusterNode2_name 'Microsoft.HDInsight/clusters@2018-06-01-preview' = {
  name: clusterNode2.name
  location: location
  tags: {}
  properties: {
    clusterVersion: '3.6'
    osType: 'Linux'
    clusterDefinition: {
      kind: 'hbase'
      configurations: {
        gateway: {
          'restAuthCredential.isEnabled': true
          'restAuthCredential.username': clusterLoginUserName
          'restAuthCredential.password': clusterLoginPassword
        }
      }
    }
    storageProfile: {
      storageaccounts: [
        {
          name: replace(replace(reference(clusterNode2_defaultStorageAccount_name.id, '2016-01-01').primaryEndpoints.blob, 'https://', ''), '/', '')
          isDefault: true
          container: clusterNode2.name
          key: listKeys(clusterNode2_defaultStorageAccount_name.id, '2016-01-01').keys[0].value
        }
      ]
    }
    computeProfile: {
      roles: [
        {
          name: 'headnode'
          targetInstanceCount: 2
          hardwareProfile: {
            vmSize: HeadNodeVirtualMachineSize
          }
          osProfile: {
            linuxOperatingSystemProfile: {
              username: sshUserName
              password: sshPassword
            }
          }
          virtualNetworkProfile: {
            id: vNet2_name.id
            subnet: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet2.name, vNet2.subnetName)
          }
        }
        {
          name: 'workernode'
          targetInstanceCount: 2
          hardwareProfile: {
            vmSize: WorkerNodeVirtualMachineSize
          }
          osProfile: {
            linuxOperatingSystemProfile: {
              username: sshUserName
              password: sshPassword
            }
          }
          virtualNetworkProfile: {
            id: vNet2_name.id
            subnet: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet2.name, vNet2.subnetName)
          }
        }
        {
          name: 'zookeepernode'
          targetInstanceCount: 3
          hardwareProfile: {
            vmSize: ZookeeperNodeVirtualMachineSize
          }
          osProfile: {
            linuxOperatingSystemProfile: {
              username: sshUserName
              password: sshPassword
            }
          }
          virtualNetworkProfile: {
            id: vNet2_name.id
            subnet: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet2.name, vNet2.subnetName)
          }
        }
      ]
    }
  }
}

output vnet1 object = vNet1_name.properties
output vnet2 object = vNet2_name.properties
output cluster1 object = clusterNode1_name.properties
output cluster2 object = clusterNode2_name.properties