param actionGroupName string {
  minLength: 1
  metadata: {
    description: 'Name for the Action group.'
  }
  default: 'autoscaleActionGroup'
}
param actionGroupShortName string {
  minLength: 1
  maxLength: 12
  metadata: {
    description: 'Short name for the Action group.'
  }
  default: 'autoscaleAG'
}
param emailAddress string {
  metadata: {
    description: 'Email address.'
  }
}
param activityLogAlertName string {
  minLength: 1
  metadata: {
    description: 'Name for the Activity log alert.'
  }
  default: 'autoscaleAlert'
}

resource actionGroupName_res 'Microsoft.Insights/actionGroups@2017-04-01' = {
  name: actionGroupName
  location: 'Global'
  properties: {
    groupShortName: actionGroupShortName
    enabled: true
    smsReceivers: []
    emailReceivers: [
      {
        name: 'emailReceiver'
        emailAddress: emailAddress
      }
    ]
    webhookReceivers: []
  }
}

resource activityLogAlertName_res 'Microsoft.Insights/activityLogAlerts@2017-04-01' = {
  name: activityLogAlertName
  location: 'Global'
  properties: {
    enabled: true
    scopes: [
      subscription().id
    ]
    condition: {
      allOf: [
        {
          field: 'Category'
          equals: 'Autoscale'
        }
      ]
    }
    actions: {
      actionGroups: [
        {
          actionGroupId: actionGroupName_res.id
        }
      ]
    }
  }
}