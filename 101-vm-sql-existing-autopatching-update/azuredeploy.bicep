@description('Existing SQL Server virtual machine name')
param existingVirtualMachineName string

@allowed([
  'Everyday'
  'Never'
  'Sunday'
  'Monday'
  'Tuesday'
  'Wednesday'
  'Thursday'
  'Friday'
  'Saturday'
])
@description('SQL Server Auto Patching Day of A Week')
param sqlAutopatchingDayOfWeek string = 'Sunday'

@allowed([
  '0'
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
])
@description('SQL Server Auto Patching Starting Hour')
param sqlAutopatchingStartHour string = '2'

@allowed([
  '30'
  '60'
  '90'
  '120'
  '150'
  '180'
])
@description('SQL Server Auto Patching Duration Window in minutes')
param sqlAutopatchingWindowDuration string = '60'

@description('Location for all resources.')
param location string = resourceGroup().location

resource existingVirtualMachineName_SqlIaasExtension 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${existingVirtualMachineName}/SqlIaasExtension'
  location: location
  properties: {
    type: 'SqlIaaSAgent'
    publisher: 'Microsoft.SqlServer.Management'
    typeHandlerVersion: '1.2'
    autoUpgradeMinorVersion: 'true'
    settings: {
      AutoPatchingSettings: {
        PatchCategory: 'WindowsMandatoryUpdates'
        Enable: true
        DayOfWeek: sqlAutopatchingDayOfWeek
        MaintenanceWindowStartingHour: sqlAutopatchingStartHour
        MaintenanceWindowDuration: sqlAutopatchingWindowDuration
      }
    }
  }
}