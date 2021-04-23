@minLength(1)
@description('Name for the Action group.')
param actionGroupName string = 'autoscaleActionGroup'

@minLength(1)
@maxLength(12)
@description('Short name for the Action group.')
param actionGroupShortName string = 'autoscaleAG'

@description('Email address.')
param emailAddress string

@minLength(1)
@description('Name for the Activity log alert.')
param activityLogAlertName string = 'autoscaleFailedAlert'

resource actionGroupName_resource 'Microsoft.Insights/actionGroups@2017-04-01' = {
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

resource activityLogAlertName_resource 'Microsoft.Insights/activityLogAlerts@2017-04-01' = {
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
        {
          field: 'Status'
          equals: 'Failed'
        }
      ]
    }
    actions: {
      actionGroups: [
        {
          actionGroupId: actionGroupName_resource.id
        }
      ]
    }
  }
}