param clusterType string {
  allowed: [
    'hadoop'
    'hbase'
    'storm'
    'spark'
  ]
  metadata: {
    description: 'The type of the HDInsight cluster to create.'
  }
}
param clusterName string {
  metadata: {
    description: 'The name of the HDInsight cluster to create.'
  }
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
param clusterStorageAccountName string {
  metadata: {
    description: 'The name of the Azure storage account to be created and be used as the cluster\'s primary storage.'
  }
}
param adlStoreName string {
  metadata: {
    description: 'The name of the Azure Data Lake Store account to be created and connected to the cluster.'
  }
}
param aadTenantId string {
  metadata: {
    description: 'The tenant ID (guid) of the Azure Active Directory (AAD) tenant where the service principal resides.'
  }
}
param servicePrincipalObjectId string {
  metadata: {
    description: 'The AAD object ID (guid) of the service principal that represents the HDInsight cluster. The service principal will be given permissions on the root folder of the Data Lake Store account.'
  }
}
param servicePrincipalApplicationId string {
  metadata: {
    description: 'The AAD application ID (guid) of the service principal that represents the HDInsight cluster. The service principal will be given permissions on the root folder of the Data Lake Store account.'
  }
}
param servicePrincipalCertificateContents string {
  metadata: {
    description: 'The base-64-encoded contents of the PFX certificate file that can be used to authenticate as the service principal that represents the HDInsight cluster.'
  }
  secure: true
}
param servicePrincipalCertificatePassword string {
  metadata: {
    description: 'The password securing the PFX certificate file that can be used to authenticate as the service principal that represents the HDInsight cluster.'
  }
  secure: true
}
param clusterWorkerNodeCount int {
  metadata: {
    description: 'The number of nodes in the HDInsight cluster.'
  }
  default: 4
}

var defaultApiVersion = '2015-06-15'

resource adlStoreName_resource 'Microsoft.DataLakeStore/accounts@2015-10-01-preview' = {
  name: adlStoreName
  location: 'East US 2'
  tags: {}
  properties: {
    initialUser: servicePrincipalObjectId
  }
  dependsOn: []
}

resource clusterStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: clusterStorageAccountName
  location: 'East US 2'
  tags: {}
  properties: {
    accountType: 'Standard_LRS'
  }
  dependsOn: []
}

resource clusterName_resource 'Microsoft.HDInsight/clusters@2015-03-01-preview' = {
  name: clusterName
  location: 'East US 2'
  tags: {}
  properties: {
    clusterVersion: '3.2'
    osType: 'Linux'
    clusterDefinition: {
      kind: clusterType
      configurations: {
        gateway: {
          'restAuthCredential.isEnabled': true
          'restAuthCredential.username': clusterLoginUserName
          'restAuthCredential.password': clusterLoginPassword
        }
        clusterIdentity: {
          'clusterIdentity.applicationId': servicePrincipalApplicationId
          'clusterIdentity.certificate': servicePrincipalCertificateContents
          'clusterIdentity.certificatePassword': servicePrincipalCertificatePassword
          'clusterIdentity.aadTenantId': 'https://login.windows.net/${aadTenantId}'
          'clusterIdentity.resourceUri': 'https://management.core.windows.net/'
        }
      }
    }
    storageProfile: {
      storageaccounts: [
        {
          name: '${clusterStorageAccountName}.blob.core.windows.net'
          isDefault: true
          container: clusterName
          key: listKeys(clusterStorageAccountName_resource.id, defaultApiVersion).key1
        }
      ]
    }
    computeProfile: {
      roles: [
        {
          name: 'headnode'
          targetInstanceCount: 2
          hardwareProfile: {
            vmSize: 'Standard_D3'
          }
          osProfile: {
            linuxOperatingSystemProfile: {
              username: sshUserName
              password: sshPassword
            }
          }
        }
        {
          name: 'workernode'
          targetInstanceCount: clusterWorkerNodeCount
          hardwareProfile: {
            vmSize: 'Standard_D3'
          }
          osProfile: {
            linuxOperatingSystemProfile: {
              username: sshUserName
              password: sshPassword
            }
          }
        }
      ]
    }
  }
  dependsOn: [
    adlStoreName_resource
    clusterStorageAccountName_resource
  ]
}

output adlStoreAccount object = adlStoreName_resource.properties
output storageAccount object = clusterStorageAccountName_resource.properties
output cluster object = clusterName_resource.properties