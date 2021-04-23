@description('The name of the Kafka cluster to create. This must be a unique name.')
param clusterName string = uniqueString(resourceGroup().id)

@description('Cluster Login Name')
param clusterLoginUserName string

@minLength(10)
@description('The password must be at least 10 characters in length and must contain at least one digit, one upper case letter, one lower case letter, and one non-alphanumeric character except (single-quote, double-quote, backslash, right-bracket, full-stop). Also, the password must not contain 3 consecutive characters from the cluster username or SSH username.')
@secure()
param clusterLoginPassword string

@description('These credentials can be used to remotely access the cluster.')
param sshUserName string

@minLength(6)
@maxLength(72)
@description('SSH password must be 6-72 characters long and must contain at least one digit, one upper case letter, and one lower case letter.  It must not contain any 3 consecutive characters from the cluster login name.')
@secure()
param sshPassword string

@description('The base URI where artifacts required by this template are located.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-hdinsight-kafka-with-edge-schema-registry/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

@description('A script action you can run on the empty node to install or configure additional software.')
param installScriptActionFolder string = 'scripts'

@description('A script action you can run on the empty node to install or configure additional software.')
param installScriptAction string = 'NodeSetup.sh'

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'Standard_A4_v2'
  'Standard_A8_v2'
  'Standard_D2_v2'
  'Standard_D3_v2'
  'Standard_D4_v2'
  'Standard_D5_v2'
  'Standard_D12_v2'
  'Standard_D13_v2'
  'Standard_E4_v3'
  'Standard_E8_v3'
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
])
@description('This is the Zookeepernode Azure Virtual Machine size, and will affect the cost. If you don\'t know, just leave the default value.')
param ZookeeperNodeVirtualMachineSize string = 'Standard_D3_v2'

var clStgAcnt_var = '${clusterName}store'
var storageAccountType = 'Standard_LRS'
var applicationName = 'schema-registry'

resource clStgAcnt 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: clStgAcnt_var
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {}
}

resource clusterName_resource 'Microsoft.HDInsight/clusters@2018-06-01-preview' = {
  name: clusterName
  location: location
  properties: {
    clusterVersion: '3.6'
    osType: 'Linux'
    clusterDefinition: {
      kind: 'KAFKA'
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
          name: replace(replace(reference(clStgAcnt.id, '2019-06-01').primaryEndpoints.blob, 'https://', ''), '/', '')
          isDefault: true
          container: clusterName
          key: listKeys(clStgAcnt.id, '2019-06-01').keys[0].value
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
        }
        {
          name: 'workernode'
          targetInstanceCount: 4
          hardwareProfile: {
            vmSize: WorkerNodeVirtualMachineSize
          }
          dataDisksGroups: [
            {
              disksPerNode: 2
            }
          ]
          osProfile: {
            linuxOperatingSystemProfile: {
              username: sshUserName
              password: sshPassword
            }
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
        }
      ]
    }
  }
}

resource clusterName_applicationName 'Microsoft.HDInsight/clusters/applications@2018-06-01-preview' = {
  parent: clusterName_resource
  name: '${applicationName}'
  properties: {
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
        name: 'schemaregistry-${uniqueString(applicationName)}'
        uri: '${artifactsLocation}${installScriptActionFolder}/${installScriptAction}${artifactsLocationSasToken}'
        roles: [
          'edgenode'
        ]
      }
    ]
    sshEndpoints: [
      {
        location: '${applicationName}.${clusterName}-ssh.azurehdinsight.net'
        destinationPort: 22
        publicPort: 22
      }
    ]
    applicationType: 'CustomApplication'
  }
}