@description('The name of the cluster to create.')
param clusterName string = 'hdi-${uniqueString(resourceGroup().id)}'

@description('The HDInsight version to deploy.')
param clusterVersion string = '4.0'

@description('The VM size of the head nodes.')
param headNodeSize string = 'Standard_D12_v2'

@description('The VM size of the worker nodes.')
param workerNodeSize string = 'Standard_D13_v2'

@description('The number of worker nodes in the cluster.')
param workerNodeCount int = 4

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

@description('The resource group name of the storage account to use as the cluster\'s default storage.')
param existingClusterStorageResourceGroup string = resourceGroup().name

@description('The name of the storage account to use as the cluster\'s default storage.')
param existingClusterStorageAccountName string

@description('The name of the storage container to use.')
param newOrExistingClusterStorageContainerName string

@description('The existing virtual network resource group name.')
param existingVirtualNetworkResourceGroup string = resourceGroup().name

@description('The existing virtual network name.')
param existingVirtualNetworkName string

@description('The existing virtual network subnet name.')
param existingVirtualNetworkSubnetName string

@description('Location for all resources.')
param location string = resourceGroup().location

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