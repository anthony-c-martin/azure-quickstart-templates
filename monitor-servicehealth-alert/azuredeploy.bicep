@minLength(1)
@description('Name for the Action group.')
param actionGroupName string = 'serviceHealthActionGroup'

@minLength(1)
@maxLength(12)
@description('Short name for the Action group.')
param actionGroupShortName string = 'serviceAG'

@description('Email address.')
param emailAddress string

@minLength(1)
@description('Name for the Activity log alert.')
param activityLogAlertName string = 'serviceHealthAlert'

resource actionGroupName_resource 'Microsoft.Insights/actionGroups@2019-06-01' = {
  name: actionGroupName
  location: 'Global'
  properties: {
    groupShortName: actionGroupShortName
    enabled: true
    emailReceivers: [
      {
        name: 'emailReceiver'
        emailAddress: emailAddress
      }
    ]
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
          field: 'category'
          equals: 'ServiceHealth'
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