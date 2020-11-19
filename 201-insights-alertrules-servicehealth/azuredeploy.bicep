param alertName string {
  metadata: {
    description: 'Name of alert'
  }
}
param status string {
  allowed: [
    'Active'
    'InProgress'
    'Resolved'
  ]
  metadata: {
    description: 'Description of alert'
  }
  default: ''
}
param emailAddress string {
  metadata: {
    description: 'Email address where the alerts are sent.'
  }
  default: 'email@example.com'
}
param emailName string {
  metadata: {
    description: 'Email address where the alerts are sent.'
  }
  default: 'Example'
}

resource alertName_res 'Microsoft.Insights/activityLogAlerts@2017-04-01' = {
  name: alertName
  location: 'global'
  properties: {
    enabled: true
    scopes: [
      subscription().id
    ]
    condition: {
      allOf: [
        {
          field: 'category'
          equals: 'ResourceHealth'
        }
        {
          field: 'status'
          equals: status
        }
      ]
    }
    actions: {
      actionGroups: [
        {
          actionGroupId: emailActionGroup.id
        }
      ]
    }
  }
}

resource emailActionGroup 'microsoft.insights/actionGroups@2019-06-01' = {
  name: 'emailActionGroup'
  location: 'global'
  properties: {
    groupShortName: 'string'
    enabled: true
    emailReceivers: [
      {
        name: emailName
        emailAddress: emailAddress
        useCommonAlertSchema: true
      }
    ]
  }
}