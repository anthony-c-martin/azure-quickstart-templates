targetScope = 'subscription'
param budgetName string {
  metadata: {
    description: 'Name of the Budget. It should be unique within a resource group.'
  }
  default: 'MyBudget'
}
param amount string {
  metadata: {
    description: 'The total amount of cost or usage to track with the budget'
  }
  default: '1000'
}
param timeGrain string {
  allowed: [
    'Monthly'
    'Quarterly'
    'Annually'
  ]
  metadata: {
    description: 'The time covered by a budget. Tracking of the amount will be reset based on the time grain.'
  }
  default: 'Monthly'
}
param startDate string {
  metadata: {
    description: 'The start date must be first of the month in YYYY-MM-DD format. Future start date should not be more than three months. Past start date should be selected within the timegrain preiod.'
  }
}
param endDate string {
  metadata: {
    description: 'The end date for the budget in YYYY-MM-DD format. If not provided, we default this to 10 years from the start date.'
  }
}
param firstThreshold string {
  metadata: {
    description: 'Threshold value associated with a notification. Notification is sent when the cost exceeded the threshold. It is always percent and has to be between 0 and 1000.'
  }
  default: '90'
}
param secondThreshold string {
  metadata: {
    description: 'Threshold value associated with a notification. Notification is sent when the cost exceeded the threshold. It is always percent and has to be between 0 and 1000.'
  }
  default: '110'
}
param contactRoles array {
  metadata: {
    description: 'The list of contact roles to send the budget notification to when the threshold is exceeded.'
  }
  default: [
    'Owner'
    'Contributor'
    'Reader'
  ]
}
param contactEmails array {
  metadata: {
    description: 'The list of email addresses to send the budget notification to when the threshold is exceeded.'
  }
}
param contactGroups array {
  metadata: {
    description: 'The list of action groups to send the budget notification to when the threshold is exceeded. It accepts array of strings.'
  }
}
param resourceGroupFilterValues array {
  metadata: {
    description: 'The set of values for the first filter'
  }
}
param meterCategoryFilterValues array {
  metadata: {
    description: 'The set of values for the second filter'
  }
}

resource budgetName_res 'Microsoft.Consumption/budgets@2019-10-01' = {
  name: budgetName
  properties: {
    timePeriod: {
      startDate: startDate
      endDate: endDate
    }
    timeGrain: timeGrain
    amount: amount
    category: 'Cost'
    notifications: {
      NotificationForExceededBudget1: {
        enabled: true
        operator: 'GreaterThan'
        threshold: firstThreshold
        contactEmails: contactEmails
        contactRoles: contactRoles
        contactGroups: contactGroups
      }
      NotificationForExceededBudget2: {
        enabled: true
        operator: 'GreaterThan'
        threshold: secondThreshold
        contactEmails: contactEmails
        contactRoles: contactRoles
        contactGroups: contactGroups
      }
    }
    filter: {
      and: [
        {
          dimensions: {
            name: 'ResourceGroupName'
            operator: 'In'
            values: resourceGroupFilterValues
          }
        }
        {
          dimensions: {
            name: 'MeterCategory'
            operator: 'In'
            values: meterCategoryFilterValues
          }
        }
      ]
    }
  }
}