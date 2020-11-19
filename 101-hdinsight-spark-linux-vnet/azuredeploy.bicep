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
  subnet: resourceId('Microsoft.Network/virtualNetworks/subnets', '${clusterName}-vnet', 'subnet1')
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
    tier: 'Standard'
    clusterDefinition: {
      kind: 'spark'
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
          name: replace(replace(reference(defaultStorageAccount_name.id, '2019-06-01').primaryEndpoints.blob, 'https://', ''), '/', '')
          isDefault: true
          container: clusterName
          key: listKeys(defaultStorageAccount_name.id, '2019-06-01').keys[0].value
        }
      ]
    }
    computeProfile: {
      roles: [
        {
          name: 'headnode'
          targetInstanceCount: 2
          hardwareProfile: {
            vmSize: 'Standard_D12_v2'
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
            vmSize: 'Standard_D13_v2'
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