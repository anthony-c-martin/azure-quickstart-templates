@description('The name of the underlying Application Insights resource.')
param appName string

@description('The url you wish to test.')
param pingURL string = 'https://www.microsoft.com'

@description('The text you would like to find.')
param pingText string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The id of the underlying Application Insights resource.')
param appInsightsResource string

@description('The location for the webtest.')
param webtestLocations string

var pingTestName_var = 'PingTest-${toLower(appName)}'
var pingAlertRuleName_var = 'PingAlert-${toLower(appName)}-${subscription().subscriptionId}'

resource pingTestName 'Microsoft.Insights/webtests@2015-05-01' = {
  name: pingTestName_var
  location: location
  tags: {
    'hidden-link:${appInsightsResource}': 'Resource'
  }
  properties: {
    Name: pingTestName_var
    Description: 'Basic ping test'
    Enabled: true
    Frequency: 300
    Timeout: 120
    Kind: 'ping'
    RetryEnabled: true
    Locations: [
      {
        Id: webtestLocations
      }
    ]
    Configuration: {
      WebTest: '<WebTest   Name="${pingTestName_var}"   Enabled="True"         CssProjectStructure=""    CssIteration=""  Timeout="120"  WorkItemIds=""         xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010"         Description=""  CredentialUserName=""  CredentialPassword=""         PreAuthenticate="True"  Proxy="default"  StopOnError="False"         RecordedResultFile=""  ResultsLocale="">  <Items>  <Request Method="GET"    Version="1.1"  Url="${pingURL}" ThinkTime="0"  Timeout="300" ParseDependentRequests="True"         FollowRedirects="True" RecordResult="True" Cache="False"         ResponseTimeGoal="0"  Encoding="utf-8"  ExpectedHttpStatusCode="200"         ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" />        </Items>  <ValidationRules> <ValidationRule  Classname="Microsoft.VisualStudio.TestTools.WebTesting.Rules.ValidationRuleFindText, Microsoft.VisualStudio.QualityTools.WebTestFramework, Version=10.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a" DisplayName="Find Text"         Description="Verifies the existence of the specified text in the response."         Level="High"  ExecutionOrder="BeforeDependents">  <RuleParameters>        <RuleParameter Name="FindText" Value="${pingText}" />  <RuleParameter Name="IgnoreCase" Value="False" />  <RuleParameter Name="UseRegularExpression" Value="False" />  <RuleParameter Name="PassIfTextFound" Value="True" />  </RuleParameters> </ValidationRule>  </ValidationRules>  </WebTest>'
    }
    SyntheticMonitorId: pingTestName_var
  }
}

resource pingAlertRuleName 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: pingAlertRuleName_var
  location: 'global'
  tags: {
    'hidden-link:${appInsightsResource}': 'Resource'
    'hidden-link:${pingTestName.id}': 'Resource'
  }
  properties: {
    description: 'Alert for web test'
    severity: 1
    enabled: true
    scopes: [
      pingTestName.id
      appInsightsResource
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.WebtestLocationAvailabilityCriteria'
      webTestId: pingTestName.id
      componentId: appInsightsResource
      failedLocationCount: 2
    }
  }
}