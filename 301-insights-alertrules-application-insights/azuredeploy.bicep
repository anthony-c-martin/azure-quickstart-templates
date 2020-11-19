param responseTime int {
  minValue: 1
  maxValue: 10000
  metadata: {
    description: 'Enter response time threshold in seconds.'
  }
  default: 3
}
param workspaceName string {
  metadata: {
    description: 'Name of the workspace where the data will be stored.'
  }
  default: 'myWorkspace'
}
param applicationInsightsName string {
  metadata: {
    description: 'Name of the application insights resource.'
  }
  default: 'myApplicationInsights'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var responseAlertName = 'ResponseTime-${toLower(applicationInsightsName)}'

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
  dependsOn: [
    workspaceName_resource
  ]
}

resource responseAlertName_resource 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: responseAlertName
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
  dependsOn: [
    applicationInsightsName_resource
    emailActionGroup
  ]
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