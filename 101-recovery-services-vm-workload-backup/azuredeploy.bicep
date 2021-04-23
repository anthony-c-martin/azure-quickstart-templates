@description('Name of the Vault')
param vaultName string = 'SqlBackupDemoVault'

@description('Resource group of Compute VM containing the workload')
param vmResourceGroup string = resourceGroup().name

@description('Name of the Compute VM containing the workload')
param vmName string = 'sqlvmbackupdemo'

@description('Backup Policy Name')
param policyName string

@description('Name of database server instance')
param databaseInstanceName string

@description('Name of protectable data source i.e. Database Name')
param databaseName string

@description('Conditional parameter for New or Existing Vault')
param isNewVault bool = false

@description('Conditional parameter for New or Existing Backup Policy')
param isNewPolicy bool = false

@allowed([
  'SQLDataBase'
])
@description('Workload type which is installed in VM and Pre-Registration Steps are performed')
param workloadType string = 'SQLDataBase'

@allowed([
  'AzureVmWorkloadSQLDatabaseProtectedItem'
])
@description('Protected Item (Database) type')
param protectedItemType string = 'AzureVmWorkloadSQLDatabaseProtectedItem'

@description('Location for all resources.')
param location string = resourceGroup().location

var skuName = 'RS0'
var skuTier = 'Standard'
var backupFabric = 'Azure'
var containerType = 'VMAppContainer'
var backupManagementType = 'AzureWorkload'

resource vaultName_resource 'Microsoft.RecoveryServices/vaults@2018-01-10' = if (isNewVault) {
  name: vaultName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {}
}

resource vaultName_backupFabric_containerType_compute_vmResourceGroup_vmName 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers@2018-01-10' = {
  name: '${vaultName}/${backupFabric}/${containerType};compute;${vmResourceGroup};${vmName}'
  properties: {
    containerType: containerType
    backupManagementType: backupManagementType
    workloadType: workloadType
    friendlyName: vmName
    sourceResourceId: resourceId(vmResourceGroup, 'Microsoft.Compute/virtualMachines', vmName)
  }
  dependsOn: [
    vaultName_resource
  ]
}

resource vaultName_policyName 'Microsoft.RecoveryServices/vaults/backupPolicies@2018-01-10' = if (isNewPolicy) {
  parent: vaultName_resource
  name: '${policyName}'
  properties: {
    backupManagementType: backupManagementType
    workloadType: workloadType
    settings: {
      timeZone: 'UTC'
      issqlcompression: false
      isCompression: false
    }
    subProtectionPolicy: [
      {
        policyType: 'Full'
        schedulePolicy: {
          schedulePolicyType: 'SimpleSchedulePolicy'
          scheduleRunFrequency: 'Daily'
          scheduleRunTimes: [
            '3/24/2019 4:00:00 PM'
          ]
          scheduleWeeklyFrequency: 0
        }
        retentionPolicy: {
          retentionPolicyType: 'LongTermRetentionPolicy'
          dailySchedule: {
            retentionTimes: [
              '3/24/2019 4:00:00 PM'
            ]
            retentionDuration: {
              count: 30
              durationType: 'Days'
            }
          }
        }
      }
      {
        policyType: 'Log'
        schedulePolicy: {
          schedulePolicyType: 'LogSchedulePolicy'
          scheduleFrequencyInMins: 60
        }
        retentionPolicy: {
          retentionPolicyType: 'SimpleRetentionPolicy'
          retentionDuration: {
            count: 30
            durationType: 'Days'
          }
        }
      }
    ]
  }
}

resource vaultName_backupFabric_containerType_compute_vmResourceGroup_vmName_workloadType_databaseInstanceName_databaseName 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2018-01-10' = {
  parent: vaultName_backupFabric_containerType_compute_vmResourceGroup_vmName
  name: '${workloadType};${databaseInstanceName};${databaseName}'
  properties: {
    backupManagementType: backupManagementType
    workloadType: workloadType
    protectedItemType: protectedItemType
    friendlyName: databaseName
    policyId: vaultName_policyName.id
  }
  dependsOn: [
    vaultName_resource
  ]
}