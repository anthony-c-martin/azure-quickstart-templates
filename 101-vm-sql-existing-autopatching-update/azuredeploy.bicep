param existingVirtualMachineName string {
  metadata: {
    description: 'Existing SQL Server virtual machine name'
  }
}
param sqlAutopatchingDayOfWeek string {
  allowed: [
    'Everyday'
    'Never'
    'Sunday'
    'Monday'
    'Tuesday'
    'Wednesday'
    'Thursday'
    'Friday'
    'Saturday'
  ]
  metadata: {
    description: 'SQL Server Auto Patching Day of A Week'
  }
  default: 'Sunday'
}
param sqlAutopatchingStartHour string {
  allowed: [
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
  ]
  metadata: {
    description: 'SQL Server Auto Patching Starting Hour'
  }
  default: '2'
}
param sqlAutopatchingWindowDuration string {
  allowed: [
    '30'
    '60'
    '90'
    '120'
    '150'
    '180'
  ]
  metadata: {
    description: 'SQL Server Auto Patching Duration Window in minutes'
  }
  default: '60'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

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