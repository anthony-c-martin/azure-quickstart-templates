@description('Name of alert')
param alertName string

@allowed([
  'Active'
  'InProgress'
  'Resolved'
])
@description('Description of alert')
param status string = ''

@description('Email address where the alerts are sent.')
param emailAddress string = 'email@example.com'

@description('Email address where the alerts are sent.')
param emailName string = 'Example'

resource alertName_resource 'Microsoft.Insights/activityLogAlerts@2017-04-01' = {
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