param clusterName string {
  metadata: {
    description: 'The name of the cluster to create.'
  }
  default: 'hdi-${uniqueString(resourceGroup().id)}'
}
param clusterVersion string {
  metadata: {
    description: 'The HDInsight version to deploy.'
  }
  default: '4.0'
}
param headNodeSize string {
  metadata: {
    description: 'The VM size of the head nodes.'
  }
  default: 'Standard_D12_v2'
}
param workerNodeSize string {
  metadata: {
    description: 'The VM size of the worker nodes.'
  }
  default: 'Standard_D13_v2'
}
param workerNodeCount int {
  metadata: {
    description: 'The number of worker nodes in the cluster.'
  }
  default: 4
}
param clusterLoginUserName string {
  metadata: {
    description: 'These credentials can be used to submit jobs to the cluster and to log into cluster dashboards.'
  }
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
}
param sshPassword string {
  metadata: {
    description: 'The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter.'
  }
  secure: true
}
param existingClusterStorageResourceGroup string {
  metadata: {
    description: 'The resource group name of the storage account to use as the cluster\'s default storage.'
  }
  default: resourceGroup().name
}
param existingClusterStorageAccountName string {
  metadata: {
    description: 'The name of the storage account to use as the cluster\'s default storage.'
  }
}
param newOrExistingClusterStorageContainerName string {
  metadata: {
    description: 'The name of the storage container to use.'
  }
}
param existingVirtualNetworkResourceGroup string {
  metadata: {
    description: 'The existing virtual network resource group name.'
  }
  default: resourceGroup().name
}
param existingVirtualNetworkName string {
  metadata: {
    description: 'The existing virtual network name.'
  }
}
param existingVirtualNetworkSubnetName string {
  metadata: {
    description: 'The existing virtual network subnet name.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource clusterName_resource 'Microsoft.HDInsight/clusters@2018-06-01-preview' = {
  name: clusterName
  location: location
  properties: {
    clusterVersion: clusterVersion
    osType: 'Linux'
    clusterDefinition: {
      kind: 'hadoop'
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
          name: replace(replace(reference(resourceId(existingClusterStorageResourceGroup, 'Microsoft.Storage/storageAccounts/', existingClusterStorageAccountName), '2019-06-01').primaryEndpoints.blob, 'https:', ''), '/', '')
          isDefault: true
          container: newOrExistingClusterStorageContainerName
          key: listKeys(resourceId(existingClusterStorageResourceGroup, 'Microsoft.Storage/storageAccounts', existingClusterStorageAccountName), '2019-06-01').keys[0].value
        }
      ]
    }
    minSupportedTlsVersion: '1.2'
    computeProfile: {
      roles: [
        {
          name: 'headnode'
          targetInstanceCount: 2
          hardwareProfile: {
            vmSize: headNodeSize
          }
          osProfile: {
            linuxOperatingSystemProfile: {
              username: sshUserName
              password: sshPassword
            }
          }
          virtualNetworkProfile: {
            id: resourceId(existingVirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks', existingVirtualNetworkName)
            subnet: resourceId(existingVirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', existingVirtualNetworkName, existingVirtualNetworkSubnetName)
          }
        }
        {
          name: 'workernode'
          targetInstanceCount: workerNodeCount
          hardwareProfile: {
            vmSize: workerNodeSize
          }
          osProfile: {
            linuxOperatingSystemProfile: {
              username: sshUserName
              password: sshPassword
            }
          }
          virtualNetworkProfile: {
            id: resourceId(existingVirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks', existingVirtualNetworkName)
            subnet: resourceId(existingVirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', existingVirtualNetworkName, existingVirtualNetworkSubnetName)
          }
        }
      ]
    }
  }
}

output cluster object = clusterName_resource.properties