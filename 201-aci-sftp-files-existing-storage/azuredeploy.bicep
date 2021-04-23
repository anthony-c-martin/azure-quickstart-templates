@description('Resource group for existing storage account')
param existingStorageAccountResourceGroupName string

@description('Name of existing storage account')
param existingStorageAccountName string

@description('Name of existing file share to be mounted')
param existingFileShareName string

@description('Username to use for SFTP access')
param sftpUser string

@description('Password to use for SFTP access')
@secure()
param sftpPassword string

@description('Primary location for resources')
param location string = resourceGroup().location

var sftpContainerName = 'sftp'
var sftpContainerGroupName_var = 'sftp-group'
var sftpContainerImage = 'atmoz/sftp:latest'
var sftpEnvVariable = '${sftpUser}:${sftpPassword}:1001'
var storageAccountId = resourceId(existingStorageAccountResourceGroupName, 'Microsoft.Storage/storageAccounts', existingStorageAccountName)

module pid_18f281fe_d1e1_502c_8b87_d945383dc75b './nested_pid_18f281fe_d1e1_502c_8b87_d945383dc75b.bicep' = {
  name: 'pid-18f281fe-d1e1-502c-8b87-d945383dc75b'
  params: {}
}

resource sftpContainerGroupName 'Microsoft.ContainerInstance/containerGroups@2019-12-01' = {
  name: sftpContainerGroupName_var
  location: location
  properties: {
    containers: [
      {
        name: sftpContainerName
        properties: {
          image: sftpContainerImage
          environmentVariables: [
            {
              name: 'SFTP_USERS'
              value: sftpEnvVariable
            }
          ]
          resources: {
            requests: {
              cpu: 2
              memoryInGB: 1
            }
          }
          ports: [
            {
              port: 22
            }
          ]
          volumeMounts: [
            {
              mountPath: '/home/${sftpUser}/upload'
              name: 'sftpvolume'
              readOnly: false
            }
          ]
        }
      }
    ]
    osType: 'Linux'
    ipAddress: {
      type: 'Public'
      ports: [
        {
          protocol: 'TCP'
          port: 22
        }
      ]
    }
    restartPolicy: 'OnFailure'
    volumes: [
      {
        name: 'sftpvolume'
        azureFile: {
          readOnly: false
          shareName: existingFileShareName
          storageAccountName: existingStorageAccountName
          storageAccountKey: listKeys(storageAccountId, '2018-02-01').keys[0].value
        }
      }
    ]
  }
}

output containerIPv4Address string = sftpContainerGroupName.properties.ipAddress.ip