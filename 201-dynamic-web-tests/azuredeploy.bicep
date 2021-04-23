@description('The name of the app insights instance that you wish to create.')
param appName string

@description('The list of web tests to run. See the README for the schema of test descriptor object.')
param tests array

@description('A list of strings representing the email addresses to send alerts to.')
param emails array

@description('Location for all resources.')
param location string = resourceGroup().location

resource appName_resource 'microsoft.insights/components@2015-05-01' = {
  name: appName
  location: location
  tags: {
    AppInsightsApp: 'MyApp'
  }
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'Unknown'
    Name: 'testapp'
    ApplicationId: appName
  }
  kind: 'web'
}

resource tests_0_name 'microsoft.insights/webtests@2015-05-01' = {
  name: tests[0].name
  location: location
  tags: {
    'hidden-link:${appName_resource.id}': 'Resource'
  }
  properties: {
    Name: tests[0].name
    Description: tests[0].description
    Enabled: true
    Frequency: tests[0].frequency_secs
    Timeout: tests[0].timeout_secs
    Kind: 'ping'
    Locations: tests[0].locations
    Configuration: {
      WebTest: '<WebTest Name="${tests[0].name}" Id="${tests[0].guid}"    Enabled="True" CssProjectStructure="" CssIteration="" Timeout="0" WorkItemIds="" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010" Description="" CredentialUserName="" CredentialPassword="" PreAuthenticate="True" Proxy="default" StopOnError="False" RecordedResultFile="" ResultsLocale="">        <Items>        <Request Method="GET" Guid="a5f10126-e4cd-570d-961c-cea43999a200" Version="1.1" Url="${tests[0].url}" ThinkTime="0" Timeout="300" ParseDependentRequests="True" FollowRedirects="True" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="${tests[0].expected}" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" /></Items></WebTest>'
    }
    SyntheticMonitorId: tests[0].name
  }
}

resource tests_0_name_alert 'Microsoft.Insights/alertRules@2015-04-01' = {
  name: '${tests[0].name}alert'
  location: location
  tags: {
    'hidden-link:${appName_resource.id}': 'Resource'
    'hidden-link:${tests_0_name.id}': 'Resource'
  }
  properties: {
    name: tests[0].name
    description: tests[0].description
    isEnabled: true
    condition: {
      '$type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.LocationThresholdRuleCondition, Microsoft.WindowsAzure.Management.Mon.Client'
      'odata.type': 'Microsoft.Azure.Management.Insights.Models.LocationThresholdRuleCondition'
      dataSource: {
        '$type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.RuleMetricDataSource, Microsoft.WindowsAzure.Management.Mon.Client'
        'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleMetricDataSource'
        resourceUri: tests_0_name.id
        metricName: 'GSMT_AvRaW'
      }
      windowSize: 'PT15M'
      failedLocationCount: tests[0].failedLocationCount
    }
    action: {
      '$type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.RuleEmailAction, Microsoft.WindowsAzure.Management.Mon.Client'
      'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleEmailAction'
      sendToServiceOwners: true
      customEmails: emails
    }
  }
}

resource tests_1_name_alert 'Microsoft.Insights/alertRules@2015-04-01' = [for i in range(0, (length(tests) - 1)): {
  name: '${tests[(i + 1)].name}alert'
  location: location
  tags: {
    'hidden-link:${appName_resource.id}': 'Resource'
    'hidden-link:${resourceId('microsoft.insights/webtests/', tests[(i + 1)].name)}': 'Resource'
  }
  properties: {
    name: tests[(i + 1)].name
    description: tests[(i + 1)].description
    isEnabled: true
    condition: {
      '$type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.LocationThresholdRuleCondition, Microsoft.WindowsAzure.Management.Mon.Client'
      'odata.type': 'Microsoft.Azure.Management.Insights.Models.LocationThresholdRuleCondition'
      dataSource: {
        '$type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.RuleMetricDataSource, Microsoft.WindowsAzure.Management.Mon.Client'
        'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleMetricDataSource'
        resourceUri: resourceId('microsoft.insights/webtests/', tests[i].name)
        metricName: 'GSMT_AvRaW'
      }
      windowSize: 'PT15M'
      failedLocationCount: tests[(i + 1)].failedLocationCount
    }
    action: {
      '$type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.RuleEmailAction, Microsoft.WindowsAzure.Management.Mon.Client'
      'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleEmailAction'
      sendToServiceOwners: true
      customEmails: emails
    }
  }
  dependsOn: [
    appName_resource
    'microsoft.insights/alertRules/${tests[i].name}alert'
    tests_1_name
  ]
}]

resource tests_1_name 'microsoft.insights/webtests@2015-05-01' = [for i in range(0, (length(tests) - 1)): {
  name: tests[(i + 1)].name
  location: location
  tags: {
    'hidden-link:${appName_resource.id}': 'Resource'
  }
  properties: {
    Name: tests[(i + 1)].name
    Description: tests[(i + 1)].description
    Enabled: true
    Frequency: tests[(i + 1)].frequency_secs
    Timeout: tests[(i + 1)].timeout_secs
    Kind: 'ping'
    Locations: tests[(i + 1)].locations
    Configuration: {
      WebTest: '<WebTest Name="${tests[(i + 1)].name}" Id="${tests[(i + 1)].guid}"    Enabled="True" CssProjectStructure="" CssIteration="" Timeout="0" WorkItemIds="" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010" Description="" CredentialUserName="" CredentialPassword="" PreAuthenticate="True" Proxy="default" StopOnError="False" RecordedResultFile="" ResultsLocale="">        <Items>        <Request Method="GET" Guid="a5f10126-e4cd-570d-961c-cea43999a200" Version="1.1" Url="${tests[(i + 1)].url}" ThinkTime="0" Timeout="300" ParseDependentRequests="True" FollowRedirects="True" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="${tests[(i + 1)].expected}" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" /></Items></WebTest>'
    }
    SyntheticMonitorId: tests[(i + 1)].name
  }
  dependsOn: [
    appName_resource
    'microsoft.insights/webtests/${tests[i].name}'
  ]
}]