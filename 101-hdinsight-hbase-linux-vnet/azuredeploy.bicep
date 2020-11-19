param clusterName string {
  metadata: {
    description: 'The name of the HDInsight cluster to create.'
  }
}
param clusterLoginUserName string {
  metadata: {
    description: 'These credentials can be used to submit jobs to the cluster and to log into cluster dashboards.'
  }
  default: 'admin'
}
param clusterLoginPassword string {
  metadata: {
    description: 'The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter.'
  }
  secure: true
}
param sshUserName string {
  metadata: {
    description: 'These credentials can be used to remotely access the cluster.'
  }
  default: 'sshuser'
}
param sshPassword string {
  metadata: {
    description: 'The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter.'
  }
  secure: true
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param HeadNodeVirtualMachineSize string {
  allowed: [
    'Standard_A4_v2'
    'Standard_A8_v2'
    'Standard_D1_v2'
    'Standard_D2_v2'
    'Standard_D3_v2'
    'Standard_D4_v2'
    'Standard_D5_v2'
    'Standard_D12_v2'
    'Standard_D13_v2'
  ]
  metadata: {
    description: 'This is the headnode Azure Virtual Machine size, and will affect the cost. If you don\'t know, just leave the default value.'
  }
  default: 'Standard_D3_v2'
}
param WorkerNodeVirtualMachineSize string {
  allowed: [
    'Standard_A4_v2'
    'Standard_A8_v2'
    'Standard_D1_v2'
    'Standard_D2_v2'
    'Standard_D3_v2'
    'Standard_D4_v2'
    'Standard_D5_v2'
    'Standard_D12_v2'
    'Standard_D13_v2'
  ]
  metadata: {
    description: 'This is the worerdnode Azure Virtual Machine size, and will affect the cost. If you don\'t know, just leave the default value.'
  }
  default: 'Standard_D3_v2'
}
param ZookeeperNodeVirtualMachineSize string {
  allowed: [
    'Standard_A4_v2'
    'Standard_A8_v2'
    'Standard_D1_v2'
    'Standard_D2_v2'
    'Standard_D3_v2'
    'Standard_D4_v2'
    'Standard_D5_v2'
    'Standard_D12_v2'
    'Standard_D13_v2'
  ]
  metadata: {
    description: 'This is the Zookeepernode Azure Virtual Machine size, and will affect the cost. If you don\'t know, just leave the default value.'
  }
  default: 'Standard_D3_v2'
}

var defaultStorageAccount = {
  name: uniqueString(resourceGroup().id)
  type: 'Standard_LRS'
}
var vNet_var = {
  name: '${clusterName}-vnet'
  addressSpacePrefix: '10.0.0.0/16'
  subnetName: 'subnet1'
  subnetPrefix: '10.0.0.0/24'
  id: resourceId('Microsoft.Network/virtualNetworks', '${clusterName}-vnet')
  subnet: '${resourceId('Microsoft.Network/virtualNetworks', '${clusterName}-vnet')}/subnets/subnet1'
}

resource vNet_name 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vNet_var.name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNet_var.addressSpacePrefix
      ]
    }
    subnets: [
      {
        name: vNet_var.subnetName
        properties: {
          addressPrefix: vNet_var.subnetPrefix
        }
      }
    ]
  }
}

resource defaultStorageAccount_name 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: defaultStorageAccount.name
  location: location
  sku: {
    name: defaultStorageAccount.type
  }
  kind: 'StorageV2'
  properties: {}
}

resource clusterName_res 'Microsoft.HDInsight/clusters@2018-06-01-preview' = {
  name: clusterName
  location: location
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
          name: replace(replace(reference(defaultStorageAccount_name.id, '2016-01-01').primaryEndpoints.blob, 'https://', ''), '/', '')
          isDefault: true
          container: clusterName
          key: listKeys(defaultStorageAccount_name.id, '2016-01-01').keys[0].value
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
            id: vNet_var.id
            subnet: vNet_var.subnet
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
            id: vNet_var.id
            subnet: vNet_var.subnet
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
            id: vNet_var.id
            subnet: vNet_var.subnet
          }
        }
      ]
    }
  }
}

output vnet object = vNet_name.properties
output cluster object = clusterName_res.properties