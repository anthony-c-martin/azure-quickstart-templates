param vaultName string {
  metadata: {
    description: 'Name of the Recovery Services Vault'
  }
}
param policyName string {
  metadata: {
    description: 'Name of the Backup Policy'
  }
}
param scheduleRunTimes array {
  metadata: {
    description: 'Times in day when backup should be triggered. e.g. 01:00 or 13:00. Must be an array, however for IaaS VMs only one value is valid. This will be used in LTR too for daily, weekly, monthly and yearly backup.'
  }
}
param timeZone string {
  metadata: {
    description: 'Any Valid timezone, for example:UTC, Pacific Standard Time. Refer: https://msdn.microsoft.com/en-us/library/gg154758.aspx'
  }
}
param instantRpRetentionRangeInDays int {
  allowed: [
    1
    2
    3
    4
    5
  ]
  metadata: {
    description: 'Number of days Instant Recovery Point should be retained'
  }
  default: 2
}
param dailyRetentionDurationCount int {
  metadata: {
    description: 'Number of days you want to retain the backup'
  }
}
param daysOfTheWeek array {
  metadata: {
    description: 'Backup will run on array of Days like, Monday, Tuesday etc. Applies in Weekly retention only.'
  }
}
param weeklyRetentionDurationCount int {
  metadata: {
    description: 'Number of weeks you want to retain the backup'
  }
}
param monthlyRetentionDurationCount int {
  metadata: {
    description: 'Number of months you want to retain the backup'
  }
}
param monthsOfYear array {
  metadata: {
    description: 'Array of Months for Yearly Retention'
  }
}
param yearlyRetentionDurationCount int {
  metadata: {
    description: 'Number of years you want to retain the backup'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource vaultName_resource 'Microsoft.RecoveryServices/vaults@2015-11-10' = {
  name: vaultName
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {}
}

resource vaultName_policyName 'Microsoft.RecoveryServices/vaults/backupPolicies@2016-06-01' = {
  name: '${vaultName}/${policyName}'
  location: location
  properties: {
    backupManagementType: 'AzureIaasVM'
    instantRpRetentionRangeInDays: instantRpRetentionRangeInDays
    schedulePolicy: {
      scheduleRunFrequency: 'Daily'
      scheduleRunDays: null
      scheduleRunTimes: scheduleRunTimes
      schedulePolicyType: 'SimpleSchedulePolicy'
    }
    retentionPolicy: {
      dailySchedule: {
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: dailyRetentionDurationCount
          durationType: 'Days'
        }
      }
      weeklySchedule: {
        daysOfTheWeek: daysOfTheWeek
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: weeklyRetentionDurationCount
          durationType: 'Weeks'
        }
      }
      monthlySchedule: {
        retentionScheduleFormatType: 'Daily'
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 1
              isLast: false
            }
          ]
        }
        retentionScheduleWeekly: null
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: monthlyRetentionDurationCount
          durationType: 'Months'
        }
      }
      yearlySchedule: {
        retentionScheduleFormatType: 'Daily'
        monthsOfYear: monthsOfYear
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 1
              isLast: false
            }
          ]
        }
        retentionScheduleWeekly: null
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: yearlyRetentionDurationCount
          durationType: 'Years'
        }
      }
      retentionPolicyType: 'LongTermRetentionPolicy'
    }
    timeZone: timeZone
  }
  dependsOn: [
    vaultName_resource
  ]
}