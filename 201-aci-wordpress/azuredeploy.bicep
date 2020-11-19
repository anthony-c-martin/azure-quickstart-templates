param storageAccountType string {
  allowed: [
    'Standard_LRS'
    'Standard_GRS'
    'Standard_ZRS'
  ]
  metadata: {
    description: 'Storage Account type'
  }
  default: 'Standard_LRS'
}
param storageAccountName string {
  metadata: {
    description: 'Storage Account Name'
  }
  default: uniqueString(resourceGroup().id)
}
param siteName string {
  metadata: {
    description: 'WordPress Site Name'
  }
  default: uniqueString(resourceGroup().id)
}
param mysqlPassword string {
  metadata: {
    description: 'MySQL database password'
  }
  secure: true
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var cpuCores = '0.5'
var memoryInGb = '0.7'
var wordpressContainerGroupName = 'wordpress-containerinstance'
var wordpressShareName = 'wordpress-share'
var mysqlShareName = 'mysql-share'
var scriptName = 'createFileShare'
var identityName = 'scratch'
var roleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
var roleDefinitionName = guid(identityName, roleDefinitionId, resourceGroup().id)

resource identityName_resource 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName
  location: location
}

resource roleDefinitionName_resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: roleDefinitionName
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: reference(identityName).principalId
    scope: resourceGroup().id
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    identityName_resource
  ]
}

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  dependsOn: [
    roleDefinitionName_resource
  ]
}

resource scriptName_wordpressShareName 'Microsoft.Resources/deploymentScripts@2019-10-01-preview' = {
  name: '${scriptName}-${wordpressShareName}'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'userAssigned'
    userAssignedIdentities: {
      '${identityName_resource.id}': {}
    }
  }
  properties: {
    forceUpdateTag: '1'
    azPowerShellVersion: '3.0'
    arguments: ' -storageAccountName ${storageAccountName} -fileShareName ${wordpressShareName} -resourceGroupName ${resourceGroup().name}'
    scriptContent: '\r\n                param(\r\n                    [string] $storageAccountName,\r\n                    [string] $fileShareName,\r\n                    [string] $resourceGroupName\r\n                )\r\n                Get-AzStorageAccount -StorageAccountName $storageAccountName -ResourceGroupName $resourceGroupName | New-AzStorageShare -Name $fileShareName\r\n                '
    timeout: 'PT5M'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
  dependsOn: [
    storageAccountName_resource
  ]
}

resource scriptName_mysqlShareName 'Microsoft.Resources/deploymentScripts@2019-10-01-preview' = {
  name: '${scriptName}-${mysqlShareName}'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'userAssigned'
    userAssignedIdentities: {
      '${identityName_resource.id}': {}
    }
  }
  properties: {
    forceUpdateTag: '1'
    azPowerShellVersion: '3.0'
    arguments: ' -storageAccountName ${storageAccountName} -fileShareName ${mysqlShareName} -resourceGroupName ${resourceGroup().name}'
    scriptContent: '\r\n                param(\r\n                    [string] $storageAccountName,\r\n                    [string] $fileShareName,\r\n                    [string] $resourceGroupName\r\n                )\r\n                Get-AzStorageAccount -StorageAccountName $storageAccountName -ResourceGroupName $resourceGroupName | New-AzStorageShare -Name $fileShareName\r\n                '
    timeout: 'PT5M'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
  dependsOn: [
    storageAccountName_resource
  ]
}

resource wordpresscontainerGroupName_resource 'Microsoft.ContainerInstance/containerGroups@2019-12-01' = {
  name: wordpressContainerGroupName
  location: location
  properties: {
    containers: [
      {
        name: 'wordpress'
        properties: {
          image: 'wordpress:4.9-apache'
          ports: [
            {
              protocol: 'Tcp'
              port: 80
            }
          ]
          environmentVariables: [
            {
              name: 'WORDPRESS_DB_HOST'
              value: '127.0.0.1:3306'
            }
            {
              name: 'WORDPRESS_DB_PASSWORD'
              value: mysqlPassword
            }
          ]
          volumeMounts: [
            {
              mountPath: '/var/www/html'
              name: 'wordpressfile'
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGb: memoryInGb
            }
          }
        }
      }
      {
        name: 'mysql'
        properties: {
          image: 'mysql:5.6'
          ports: [
            {
              protocol: 'Tcp'
              port: 3306
            }
          ]
          environmentVariables: [
            {
              name: 'MYSQL_ROOT_PASSWORD'
              value: mysqlPassword
            }
          ]
          volumeMounts: [
            {
              mountPath: '/var/lib/mysql'
              name: 'mysqlfile'
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGb: memoryInGb
            }
          }
        }
      }
    ]
    volumes: [
      {
        azureFile: {
          shareName: wordpressShareName
          storageAccountKey: listKeys(storageAccountName, '2019-06-01').keys[0].value
          storageAccountName: storageAccountName
        }
        name: 'wordpressfile'
      }
      {
        azureFile: {
          shareName: mysqlShareName
          storageAccountKey: listKeys(storageAccountName, '2019-06-01').keys[0].value
          storageAccountName: storageAccountName
        }
        name: 'mysqlfile'
      }
    ]
    ipAddress: {
      ports: [
        {
          protocol: 'Tcp'
          port: 80
        }
      ]
      type: 'Public'
      dnsNameLabel: siteName
    }
    osType: 'Linux'
  }
  dependsOn: [
    scriptName_wordpressShareName
    scriptName_mysqlShareName
  ]
}

output siteFQDN string = wordpresscontainerGroupName_resource.properties.ipAddress.fqdn