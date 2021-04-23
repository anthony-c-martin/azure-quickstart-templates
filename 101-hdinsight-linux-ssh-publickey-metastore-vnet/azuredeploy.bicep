@description('The name of the cluster to create.')
param clusterName string = 'hdi-${uniqueString(resourceGroup().id)}'

@description('The HDInsight version to deploy.')
param clusterVersion string = '3.6'

@description('The VM size of the head nodes.')
param headNodeSize string = 'Standard_D12_V2'

@description('The VM size of the worker nodes.')
param workerNodeSize string = 'Standard_D13_V2'

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
param existingClusterStorageResourceGroup string

@description('The name of the storage account to use as the cluster\'s default storage.')
param existingClusterStorageAccountName string

@description('The name of the storage container to use.')
param newOrExistingClusterStorageContainerName string

@description('The resource group name where the existing metastore SQL server is located.')
param existingHiveMetastoreServerResourceGroupName string

@description('The fully-qualified domain name (FQDN) of the SQL server to use for the external Hive metastore.')
param existingHiveMetastoreServerName string

@description('The external Hive metastore\'s existing SQL database.')
param existingHiveMetastoreDatabaseName string

@description('The external Hive metastore\'s existing SQL server admin username.')
param existingHiveMetastoreUsername string

@description('The external Hive metastore\'s existing SQL server admin password.')
@secure()
param existingHiveMetastorePassword string

@description('The existing virtual network resource group name.')
param existingVirtualNetworkResourceGroup string

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
        'hive-site': {
          'javax.jdo.option.ConnectionDriverName': 'com.microsoft.sqlserver.jdbc.SQLServerDriver'
          'javax.jdo.option.ConnectionURL': 'jdbc:sqlserver://${reference(resourceId(existingHiveMetastoreServerResourceGroupName, 'Microsoft.Sql/servers', existingHiveMetastoreServerName), '2018-06-01-preview').fullyQualifiedDomainName};database=${existingHiveMetastoreDatabaseName};encrypt=true;trustServerCertificate=true;create=false;loginTimeout=300'
          'javax.jdo.option.ConnectionUserName': existingHiveMetastoreUsername
          'javax.jdo.option.ConnectionPassword': existingHiveMetastorePassword
        }
        'hive-env': {
          hive_database: 'Existing MSSQL Server database with SQL authentication'
          hive_database_name: existingHiveMetastoreDatabaseName
          hive_database_type: 'mssql'
          hive_existing_mssql_server_database: existingHiveMetastoreDatabaseName
          hive_existing_mssql_server_host: reference(resourceId(existingHiveMetastoreServerResourceGroupName, 'Microsoft.Sql/servers', existingHiveMetastoreServerName), '2018-06-01-preview').fullyQualifiedDomainName
          hive_hostname: reference(resourceId(existingHiveMetastoreServerResourceGroupName, 'Microsoft.Sql/servers', existingHiveMetastoreServerName), '2018-06-01-preview').fullyQualifiedDomainName
        }
      }
    }
    storageProfile: {
      storageaccounts: [
        {
          name: replace(replace(concat(reference(resourceId(existingClusterStorageResourceGroup, 'Microsoft.Storage/storageAccounts/', existingClusterStorageAccountName), '2018-02-01').primaryEndpoints.blob), 'https:', ''), '/', '')
          isDefault: true
          container: newOrExistingClusterStorageContainerName
          key: listKeys(resourceId(existingClusterStorageResourceGroup, 'Microsoft.Storage/storageAccounts', existingClusterStorageAccountName), '2018-02-01').keys[0].value
        }
      ]
    }
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
            subnet: '${resourceId(existingVirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks', existingVirtualNetworkName)}/subnets/${existingVirtualNetworkSubnetName}'
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