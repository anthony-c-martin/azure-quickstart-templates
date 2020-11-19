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
param scheduleRunDays array {
  metadata: {
    description: 'Backup Schedule will run on array of Days like, Monday, Tuesday etc. Applies in Weekly Backup Type only.'
  }
}
param scheduleRunTimes array {
  metadata: {
    description: 'Times in day when backup should be triggered. e.g. 01:00, 13:00. This will be used in LTR too for daily, weekly, monthly and yearly backup.'
  }
}
param timeZone string {
  metadata: {
    description: 'Any Valid timezone, for example:UTC, Pacific Standard Time. Refer: https://msdn.microsoft.com/en-us/library/gg154758.aspx'
  }
}
param weeklyRetentionDurationCount int {
  metadata: {
    description: 'Number of weeks you want to retain the backup'
  }
}
param daysOfTheWeekForMontlyRetention array {
  metadata: {
    description: 'Array of Days for Monthly Retention (Min One or Max all values from scheduleRunDays, but not any other days which are not part of scheduleRunDays)'
  }
}
param weeksOfTheMonthForMonthlyRetention array {
  metadata: {
    description: 'Array of Weeks for Monthly Retention - First, Second, Third, Fourth, Last'
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
param daysOfTheWeekForYearlyRetention array {
  metadata: {
    description: 'Array of Days for Yearly Retention (Min One or Max all values from scheduleRunDays, but not any other days which are not part of scheduleRunDays)'
  }
}
param weeksOfTheMonthForYearlyRetention array {
  metadata: {
    description: 'Array of Weeks for Yearly Retention - First, Second, Third, Fourth, Last'
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

resource vaultName_res 'Microsoft.RecoveryServices/vaults@2016-06-01' = {
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
    instantRpRetentionRangeInDays: 5
    schedulePolicy: {
      scheduleRunFrequency: 'Weekly'
      scheduleRunDays: scheduleRunDays
      scheduleRunTimes: scheduleRunTimes
      schedulePolicyType: 'SimpleSchedulePolicy'
    }
    retentionPolicy: {
      dailySchedule: null
      weeklySchedule: {
        daysOfTheWeek: scheduleRunDays
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: weeklyRetentionDurationCount
          durationType: 'Weeks'
        }
      }
      monthlySchedule: {
        retentionScheduleFormatType: 'Weekly'
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 1
              isLast: false
            }
          ]
        }
        retentionScheduleWeekly: {
          daysOfTheWeek: daysOfTheWeekForMontlyRetention
          weeksOfTheMonth: weeksOfTheMonthForMonthlyRetention
        }
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: monthlyRetentionDurationCount
          durationType: 'Months'
        }
      }
      yearlySchedule: {
        retentionScheduleFormatType: 'Weekly'
        monthsOfYear: monthsOfYear
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 1
              isLast: false
            }
          ]
        }
        retentionScheduleWeekly: {
          daysOfTheWeek: daysOfTheWeekForYearlyRetention
          weeksOfTheMonth: weeksOfTheMonthForYearlyRetention
        }
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
}