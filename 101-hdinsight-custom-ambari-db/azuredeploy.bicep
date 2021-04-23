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

@description('The name of the resource group where the existing SQL server is to use for the new external metastore SQL db.')
param existingSQLServerResourceGroup string = resourceGroup().name

@description('The name of the existing SQL server to use for the new external metastore SQL db.')
param existingSQLServerName string

@description('The external Hive metastore\'s existing SQL server admin username.')
param existingSQLServerUsername string

@description('The external Hive metastore\'s existing SQL server admin password.')
@secure()
param existingSQLServerPassword string

@description('The name of the new SQL db to create to serve as the external metastores.')
param newMetastoreDBName string = 'metastoredb${uniqueString(resourceGroup().id)}'

@description('The existing virtual network resource group name.')
param existingVirtualNetworkResourceGroup string = resourceGroup().name

@description('The existing virtual network name.')
param existingVirtualNetworkName string

@description('The existing virtual network subnet name.')
param existingVirtualNetworkSubnetName string

@description('Location for all resources.')
param location string = resourceGroup().location

var sqldbname = '${existingSQLServerName}/${newMetastoreDBName}'

module sqlDbDeployment './nested_sqlDbDeployment.bicep' = {
  name: 'sqlDbDeployment'
  scope: resourceGroup(existingSQLServerResourceGroup)
  params: {
    variables_sqldbname: sqldbname
    location: location
  }
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
        'hive-site': {
          'javax.jdo.option.ConnectionDriverName': 'com.microsoft.sqlserver.jdbc.SQLServerDriver'
          'javax.jdo.option.ConnectionURL': 'jdbc:sqlserver://${reference(resourceId(existingSQLServerResourceGroup, 'Microsoft.Sql/servers', existingSQLServerName), '2018-06-01-preview').fullyQualifiedDomainName};database=${newMetastoreDBName};encrypt=true;trustServerCertificate=true;create=false;loginTimeout=300'
          'javax.jdo.option.ConnectionUserName': existingSQLServerUsername
          'javax.jdo.option.ConnectionPassword': existingSQLServerPassword
        }
        'hive-env': {
          hive_database: 'Existing MSSQL Server database with SQL authentication'
          hive_database_name: newMetastoreDBName
          hive_database_type: 'mssql'
          hive_existing_mssql_server_database: newMetastoreDBName
          hive_existing_mssql_server_host: reference(resourceId(existingSQLServerResourceGroup, 'Microsoft.Sql/servers', existingSQLServerName), '2018-06-01-preview').fullyQualifiedDomainName
          hive_hostname: reference(resourceId(existingSQLServerResourceGroup, 'Microsoft.Sql/servers', existingSQLServerName), '2018-06-01-preview').fullyQualifiedDomainName
        }
        'ambari-conf': {
          'database-server': reference(resourceId(existingSQLServerResourceGroup, 'Microsoft.Sql/servers', existingSQLServerName), '2018-06-01-preview').fullyQualifiedDomainName
          'database-name': newMetastoreDBName
          'database-user-name': existingSQLServerUsername
          'database-user-password': existingSQLServerPassword
        }
      }
    }
    storageProfile: {
      storageaccounts: [
        {
          name: replace(replace(reference(resourceId(existingClusterStorageResourceGroup, 'Microsoft.Storage/storageAccounts/', existingClusterStorageAccountName), '2018-02-01').primaryEndpoints.blob, 'https:', ''), '/', '')
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
  dependsOn: [
    sqlDbDeployment
  ]
}

output cluster object = clusterName_resource.properties