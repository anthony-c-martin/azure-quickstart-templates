param logicAppName string {
  metadata: {
    description: 'The name of the logic app.'
  }
}
param azureBlobAccountName string {
  metadata: {
    description: 'Account name of the Azure Blob storage account.'
  }
}
param azureBlobAccessKey string {
  metadata: {
    description: 'Account key of the Azure Blob storage account.'
  }
  secure: true
}
param azureBlobConnectionName string {
  metadata: {
    description: 'The name of the Azure Blob connection being created.'
  }
}
param ftpServerAddress string {
  metadata: {
    description: 'The address of the FTP server.'
  }
}
param ftpUsername string {
  metadata: {
    description: 'The username for the FTP server.'
  }
}
param ftpPassword string {
  metadata: {
    description: 'The password for the FTP server.'
  }
  secure: true
}
param ftpServerPort int {
  metadata: {
    description: 'The port for the FTP server.'
  }
  default: 21
}
param ftpConnectionName string {
  metadata: {
    description: 'The name of the FTP connection being created.'
  }
}
param ftpFolderPath string {
  metadata: {
    description: 'The path to the FTP folder you want to listen to.'
  }
  default: '/'
}
param blobContainerPath string {
  metadata: {
    description: 'The container/path of the folder you want to add files to.'
  }
  default: '/mycontainer'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var ftpisssl = true
var ftpisBinaryTransportftpisssl = true
var ftpdisableCertificateValidation = true

resource ftpConnectionName_res 'Microsoft.Web/connections@2018-07-01-preview' = {
  location: location
  name: ftpConnectionName
  properties: {
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'ftp')
    }
    displayName: 'ftp'
    parameterValues: {
      serverAddress: ftpServerAddress
      userName: ftpUsername
      password: ftpPassword
      serverPort: ftpServerPort
      isssl: ftpisssl
      isBinaryTransport: ftpisBinaryTransportftpisssl
      disableCertificateValidation: ftpdisableCertificateValidation
    }
  }
}

resource azureBlobConnectionName_res 'Microsoft.Web/connections@2018-07-01-preview' = {
  location: location
  name: azureBlobConnectionName
  properties: {
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azureblob')
    }
    displayName: 'azureblob'
    parameterValues: {
      accountName: azureBlobAccountName
      accessKey: azureBlobAccessKey
    }
  }
}

resource logicAppName_res 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        When_a_file_is_added_or_modified: {
          recurrence: {
            frequency: 'Minute'
            interval: 1
          }
          metadata: {
            '${base64(ftpFolderPath)}': ftpFolderPath
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'ftp\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/datasets/default/triggers/onupdatedfile'
            queries: {
              folderId: base64(ftpFolderPath)
            }
          }
        }
      }
      actions: {
        Create_file: {
          type: 'ApiConnection'
          inputs: {
            body: '@triggerBody()'
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/datasets/default/files'
            queries: {
              folderPath: blobContainerPath
              name: '@{triggerOutputs()[\'headers\'][\'x-ms-file-name\']}'
            }
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          azureblob: {
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azureblob')
            connectionId: azureBlobConnectionName_res.id
          }
          ftp: {
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'ftp')
            connectionId: ftpConnectionName_res.id
          }
        }
      }
    }
  }
}