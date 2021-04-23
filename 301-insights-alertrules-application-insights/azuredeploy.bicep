@minValue(1)
@maxValue(10000)
@description('Enter response time threshold in seconds.')
param responseTime int = 3

@description('Name of the workspace where the data will be stored.')
param workspaceName string = 'myWorkspace'

@description('Name of the application insights resource.')
param applicationInsightsName string = 'myApplicationInsights'

@description('Location for all resources.')
param location string = resourceGroup().location

var responseAlertName_var = 'ResponseTime-${toLower(applicationInsightsName)}'

resource workspaceName_resource 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'Free'
    }
  }
}

resource applicationInsightsName_resource 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspaceName_resource.id
  }
}

resource responseAlertName 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: responseAlertName_var
  location: 'global'
  properties: {
    description: 'response time alert'
    severity: 0
    enabled: true
    scopes: [
      applicationInsightsName_resource.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: '1st criterion'
          metricName: 'requests/duration'
          operator: 'GreaterThan'
          threshold: responseTime
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: emailActionGroup.id
      }
    ]
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
        name: 'Example'
        emailAddress: 'example@test.com'
        useCommonAlertSchema: true
      }
    ]
  }
}