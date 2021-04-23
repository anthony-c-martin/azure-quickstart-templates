@description('Existing SQL Server virtual machine name')
param existingVirtualMachineName string

@allowed([
  '1'
  '2'
  '3'
  '4'
  '5'
  '6'
  '7'
  '8'
  '9'
  '10'
  '11'
  '12'
  '13'
  '14'
  '15'
  '16'
  '17'
  '18'
  '19'
  '20'
  '21'
  '22'
  '23'
  '24'
  '25'
  '26'
  '27'
  '28'
  '29'
  '30'
])
@description('SQL Server Auto Backup Retention Period')
param sqlAutobackupRetentionPeriod string = '2'

@description('SQL Server Auto Backup Storage Account Name')
param sqlAutobackupStorageAccountName string

@description('SQL Server Auto Backup Encryption Password')
param sqlAutobackupEncryptionPassword string

@description('Location for all resources.')
param location string = resourceGroup().location

resource existingVirtualMachineName_SqlIaasExtension 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${existingVirtualMachineName}/SqlIaasExtension'
  location: location
  properties: {
    type: 'SqlIaaSAgent'
    publisher: 'Microsoft.SqlServer.Management'
    typeHandlerVersion: '1.2'
    autoUpgradeMinorVersion: true
    settings: {
      AutoBackupSettings: {
        Enable: true
        RetentionPeriod: sqlAutobackupRetentionPeriod
        EnableEncryption: true
      }
    }
    protectedSettings: {
      StorageUrl: reference(resourceId('Microsoft.Storage/storageAccounts', sqlAutobackupStorageAccountName), '2015-06-15').primaryEndpoints.blob
      StorageAccessKey: listKeys(resourceId('Microsoft.Storage/storageAccounts', sqlAutobackupStorageAccountName), '2015-06-15').key1
      Password: sqlAutobackupEncryptionPassword
    }
  }
}