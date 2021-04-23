@description('The name to use for the AKS Cluster.')
param aks_cluster_name string = 'sql-server-aks'

@description('The name of the resource group to create the AKS Cluster in.')
param aks_resource_group string = 'sql-server-always-on'

@description('AAD Client ID for Azure account authentication - used to authenticate to Azure using Service Principal for ACI creation to run CNAB operation and also for AKS Cluster.')
@secure()
param azure_client_id string

@description('AAD Client Secret for Azure account authentication - used to authenticate to Azure using Service Principal for ACI creation to run CNAB operation and also for AKS Cluster.')
@secure()
param azure_client_secret string

@description('The name of the action to be performed on the application instance.')
param cnab_action string = 'install'

@description('The name of the application instance.')
param cnab_installation_name string = 'porter-sql-server-always-on'

@description('The file share name in the storage account for the CNAB state to be stored in')
param cnab_state_share_name string = ''

@description('The storage account key for the account for the CNAB state to be stored in, if this is left blank it will be looked up at runtime')
param cnab_state_storage_account_key string = ''

@description('The storage account name for the account for the CNAB state to be stored in, by default this will be in the current resource group and will be created if it does not exist')
param cnab_state_storage_account_name string = 'cnabstate${uniqueString(resourceGroup().id)}'

@description('The resource group name for the storage account for the CNAB state to be stored in, by default this will be in the current resource group, if this is changed to a different resource group the storage account is expected to already exist')
param cnab_state_storage_account_resource_group string = resourceGroup().name

@description('Name for the container group')
param containerGroupName string = 'cg-${uniqueString(resourceGroup().id, newGuid())}'

@description('Name for the container')
param containerName string = 'cn-${uniqueString(resourceGroup().id, newGuid())}'

@allowed([
  'westus'
  'eastus'
  'westeurope'
  'westus2'
  'northeurope'
  'southeastasia'
  'eastus2'
  'centralus'
  'australiaeast'
  'uksouth'
  'southcentralus'
  'centralindia'
  'southindia'
  'northcentralus'
  'eastasia'
  'canadacentral'
  'japaneast'
])
@description('The location in which the resources will be created.')
param location string = resourceGroup().location

@description('The Password for the SQL Server Master Key.')
@secure()
param sql_masterkeypassword string

@description('The Password for the sa user in SQL Server.')
@secure()
param sql_sapassword string

resource cnab_state_storage_account_name_resource 'Microsoft.Storage/storageAccounts@2019-04-01' = if (cnab_state_storage_account_resource_group == resourceGroup().name) {
  name: cnab_state_storage_account_name
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        file: {
          enabled: true
        }
      }
    }
  }
}

resource containerGroupName_resource 'Microsoft.ContainerInstance/containerGroups@2018-10-01' = {
  name: containerGroupName
  location: location
  properties: {
    containers: [
      {
        name: containerName
        properties: {
          image: 'cnabquickstartstest.azurecr.io/simongdavies/run-duffle:latest'
          resources: {
            requests: {
              cpu: '1.0'
              memoryInGb: '1.5'
            }
          }
          environmentVariables: [
            {
              name: 'CNAB_ACTION'
              value: cnab_action
            }
            {
              name: 'CNAB_INSTALLATION_NAME'
              value: cnab_installation_name
            }
            {
              name: 'ACI_LOCATION'
              value: location
            }
            {
              name: 'CNAB_STATE_STORAGE_ACCOUNT_NAME'
              value: cnab_state_storage_account_name
            }
            {
              name: 'CNAB_STATE_STORAGE_ACCOUNT_KEY'
              secureValue: cnab_state_storage_account_key
            }
            {
              name: 'CNAB_STATE_SHARE_NAME'
              value: cnab_state_share_name
            }
            {
              name: 'VERBOSE'
              value: 'false'
            }
            {
              name: 'CNAB_BUNDLE_NAME'
              value: 'porter/sql-server-always-on'
            }
            {
              name: 'AKS_CLUSTER_NAME'
              value: aks_cluster_name
            }
            {
              name: 'AKS_RESOURCE_GROUP'
              value: aks_resource_group
            }
            {
              name: 'LOCATION'
              value: location
            }
            {
              name: 'SQL_MASTERKEYPASSWORD'
              secureValue: sql_masterkeypassword
            }
            {
              name: 'SQL_SAPASSWORD'
              secureValue: sql_sapassword
            }
            {
              name: 'AZURE_CLIENT_ID'
              secureValue: azure_client_id
            }
            {
              name: 'AZURE_CLIENT_SECRET'
              secureValue: azure_client_secret
            }
            {
              name: 'AZURE_SUBSCRIPTION_ID'
              value: subscription().subscriptionId
            }
            {
              name: 'AZURE_TENANT_ID'
              value: subscription().tenantId
            }
          ]
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: 'Never'
  }
  dependsOn: [
    cnab_state_storage_account_name_resource
  ]
}

output CNAB_Package_Action_Logs_Command string = 'az container logs -g ${resourceGroup().name} -n ${containerGroupName}  --container-name ${containerName} --follow'