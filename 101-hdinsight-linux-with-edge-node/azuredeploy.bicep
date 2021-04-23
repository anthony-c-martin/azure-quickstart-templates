@description('The name of the HDInsight cluster to be created. The cluster name must be globally unique.')
param clusterName string

@description('These credentials can be used to submit jobs to the cluster and to log into cluster dashboards.')
param clusterLoginUserName string = 'admin'

@description('The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter.')
@secure()
param clusterLoginPassword string

@description('These credentials can be used to remotely access the cluster.')
param sshUserName string = 'sshuser'

@description('The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter.')
@secure()
param sshPassword string

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-hdinsight-linux-with-edge-node'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('A script action you can run on the empty node to install or configure additiona software.')
param installScriptActionFolder string = 'scripts'

@description('A script action you can run on the empty node to install or configure additiona software.')
param installScriptAction string = 'EmptyNodeSetup.sh'

@description('Location for all resources.')
param location string = resourceGroup().location

var clusterStorageAccountName_var = '${clusterName}store'
var storageAccountType = 'Standard_LRS'
var applicationName = 'new-edgenode'

resource clusterStorageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: clusterStorageAccountName_var
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {}
}

resource clusterName_resource 'Microsoft.HDInsight/clusters@2015-03-01-preview' = {
  name: clusterName
  location: location
  tags: {}
  properties: {
    clusterVersion: '3.6'
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
          name: replace(replace(reference(clusterStorageAccountName.id, '2016-01-01').primaryEndpoints.blob, 'https://', ''), '/', '')
          isDefault: true
          container: clusterName
          key: listKeys(clusterStorageAccountName.id, '2016-01-01').keys[0].value
        }
      ]
    }
    computeProfile: {
      roles: [
        {
          name: 'headnode'
          targetInstanceCount: 2
          hardwareProfile: {
            vmSize: 'Standard_D3_v2'
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
          targetInstanceCount: 2
          hardwareProfile: {
            vmSize: 'Standard_D3_v2'
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
}

resource clusterName_applicationName 'Microsoft.HDInsight/clusters/applications@2015-03-01-preview' = {
  parent: clusterName_resource
  name: '${applicationName}'
  properties: {
    marketplaceIdentifier: 'EmptyNode'
    computeProfile: {
      roles: [
        {
          name: 'edgenode'
          targetInstanceCount: 1
          hardwareProfile: {
            vmSize: 'Standard_D3_v2'
          }
        }
      ]
    }
    installScriptActions: [
      {
        name: 'emptynode-${uniqueString(applicationName)}'
        uri: '${artifactsLocation}/${installScriptActionFolder}/${installScriptAction}${artifactsLocationSasToken}'
        roles: [
          'edgenode'
        ]
      }
    ]
    uninstallScriptActions: []
    httpsEndpoints: []
    applicationType: 'CustomApplication'
  }
}

output storage object = clusterStorageAccountName.properties
output cluster object = clusterName_resource.properties
output application object = clusterName_applicationName.properties