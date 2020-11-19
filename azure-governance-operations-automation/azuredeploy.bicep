param skuName string {
  allowed: [
    'F1'
    'D1'
    'B1'
    'B2'
    'B3'
    'S1'
    'S2'
    'S3'
    'P1'
    'P2'
    'P3'
    'P4'
  ]
  metadata: {
    description: 'Describes plan\'s pricing tier and instance size. Check details at https://azure.microsoft.com/en-us/pricing/details/app-service/'
  }
  default: 'F1'
}
param skuCapacity int {
  minValue: 1
  metadata: {
    description: 'Describes plan\'s instance count'
  }
  default: 1
}
param sqlAdministratorLogin string {
  metadata: {
    description: 'The account name to use for the database server administrator.'
  }
  default: 'cloudwiseuser'
}
param sqlAdministratorLoginPassword string {
  metadata: {
    description: 'The password to use for the database server administrator.'
  }
  secure: true
}
param omsWorkspaceName string {
  metadata: {
    description: 'Provide the OMS Workspace Name.'
  }
  default: 'CloudWiseOMSWorkspace'
}
param automationAccountName string {
  metadata: {
    description: 'Provide the name of an existing Automation Account with SPN.'
  }
}
param automationRegion string {
  allowed: [
    'Japan East'
    'East US 2'
    'Southeast Asia'
    'South Central US'
    'West Europe'
  ]
  metadata: {
    description: 'Location of the existing Automation Account.'
  }
  default: 'East US 2'
}
param omsRegion string {
  allowed: [
    'Australia Southeast'
    'East US'
    'Southeast Asia'
    'West Europe'
  ]
  metadata: {
    description: 'Location of the OMS regions.'
  }
  default: 'East US'
}
param artifactsLocation string {
  metadata: {
    description: 'Publicly accessible location of all deployment artifacts.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/azure-governance-operations-automation'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'Reserved for deploying using Visual Studio. Please keep it as an empty string'
  }
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var packageURI = 'https://msignite2016stg.blob.core.windows.net/cloudwise/package.zip'
var hostingPlanName_var = 'CloudWiseHostingplan-${uniqueString(resourceGroup().id)}'
var webSiteName_var = 'CloudWise${uniqueString(resourceGroup().id)}'
var sqlserverName_var = 'sqlcloudwise${uniqueString(resourceGroup().id)}'
var sqlDatabaseName = 'cloudwisedb'
var sqlCollation = 'SQL_Latin1_General_CP1_CI_AS'
var sqlMaxSizeBytes = '1073741824'
var sqlEdition = 'Basic'
var sqlRequestedServiceObjectiveName = 'Basic'
var insightsName_var = '${webSiteName_var}insights'
var omsWorkspaceName_var = concat(omsWorkspaceName, uniqueString(resourceGroup().id, deployment().name))
var OMSWebAppsRunBookAndDashboardTemplateFolder = 'nested/AutomationRunbooksOMSDashboard'
var OMSWebAppsRunBookAndDashboardTemplateFileName = 'OMSAutomationRunbooksDashboard.json'
var OMSCommonTemplateFolder = 'nested/OMSCommon'
var OMSCommonTemplateFileName = 'OMSCommon.json'
var quickstartTags = {
  type: 'object'
  name: 'azure-governance-operations-automation'
}

resource sqlserverName 'Microsoft.Sql/servers@2014-04-01-preview' = {
  name: sqlserverName_var
  location: location
  tags: {
    displayName: 'SqlServer'
    quickstartName: quickstartTags.name
  }
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
  }
}

resource sqlserverName_sqlDatabaseName 'Microsoft.Sql/servers/databases@2014-04-01-preview' = {
  name: '${sqlserverName_var}/${sqlDatabaseName}'
  location: location
  properties: {
    edition: sqlEdition
    collation: sqlCollation
    maxSizeBytes: sqlMaxSizeBytes
    requestedServiceObjectiveName: sqlRequestedServiceObjectiveName
  }
  dependsOn: [
    sqlserverName
  ]
}

resource hostingPlanName 'Microsoft.Web/serverfarms@2015-08-01' = {
  name: hostingPlanName_var
  location: location
  tags: {
    displayName: 'HostingPlan'
    quickstartName: quickstartTags.name
  }
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {
    name: hostingPlanName_var
  }
}

resource webSiteName 'Microsoft.Web/sites@2015-08-01' = {
  name: webSiteName_var
  location: location
  tags: {
    'hidden-related:${hostingPlanName.id}': 'empty'
    displayName: 'Website'
    quickstartName: quickstartTags.name
  }
  properties: {
    name: webSiteName_var
    serverFarmId: hostingPlanName.id
  }
  dependsOn: [
    hostingPlanName_var
  ]
}

resource webSiteName_web 'Microsoft.Web/sites/config@2015-08-01' = {
  name: '${webSiteName_var}/web'
  tags: {
    displayName: 'WebAppConfig'
    quickstartName: quickstartTags.name
  }
  properties: {
    netFrameworkVersion: 'v4.6'
  }
  dependsOn: [
    webSiteName
    webSiteName_MSDeploy
  ]
}

resource webSiteName_connectionstrings 'Microsoft.Web/sites/config@2015-08-01' = {
  name: '${webSiteName_var}/connectionstrings'
  properties: {
    DefaultConnection: {
      value: 'Data Source=tcp:${reference('Microsoft.Sql/servers/${sqlserverName_var}').fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabaseName};User Id=${sqlAdministratorLogin}@${sqlserverName_var};Password=${sqlAdministratorLoginPassword};MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
      type: 'SQLServer'
    }
    SQLCONNSTR_DefaultConnection: {
      value: 'Data Source=tcp:${reference('Microsoft.Sql/servers/${sqlserverName_var}').fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabaseName};User Id=${sqlAdministratorLogin}@${sqlserverName_var};Password=${sqlAdministratorLoginPassword};MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
      type: 'SQLServer'
    }
  }
  dependsOn: [
    webSiteName
    webSiteName_MSDeploy
  ]
}

resource webSiteName_MSDeploy 'Microsoft.Web/sites/extensions@2015-08-01' = {
  name: '${webSiteName_var}/MSDeploy'
  location: location
  tags: {
    displayName: 'WebAppMSDeploy'
    quickstartName: quickstartTags.name
  }
  properties: {
    packageUri: packageURI
  }
  dependsOn: [
    webSiteName
  ]
}

resource hostingPlanName_name 'Microsoft.Insights/autoscalesettings@2014-04-01' = {
  name: '${hostingPlanName_var}-${resourceGroup().name}'
  location: location
  tags: {
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName_var}': 'Resource'
    displayName: '${insightsName_var} AutoScale'
    quickstartName: quickstartTags.name
  }
  properties: {
    name: '${hostingPlanName_var}-${resourceGroup().name}'
    profiles: [
      {
        name: 'Default'
        capacity: {
          minimum: 1
          maximum: 2
          default: 1
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: '${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName_var}'
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 80
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: 1
              cooldown: 'PT10M'
            }
          }
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: '${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName_var}'
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT1H'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 60
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: 1
              cooldown: 'PT1H'
            }
          }
        ]
      }
    ]
    enabled: false
    targetResourceUri: '${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName_var}'
  }
  dependsOn: [
    hostingPlanName
  ]
}

resource CPUHigh_hostingPlanName 'Microsoft.Insights/alertrules@2014-04-01' = {
  name: 'CPUHigh ${hostingPlanName_var}'
  location: location
  tags: {
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName_var}': 'Resource'
    displayName: 'CPUHigh${insightsName_var}'
    quickstartName: quickstartTags.name
  }
  properties: {
    name: 'CPUHigh ${hostingPlanName_var}'
    description: 'The average CPU is high across all the instances of ${hostingPlanName_var}'
    isEnabled: false
    condition: {
      'odata.type': 'Microsoft.Azure.Management.Insights.Models.ThresholdRuleCondition'
      dataSource: {
        'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleMetricDataSource'
        resourceUri: '${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName_var}'
        metricName: 'CpuPercentage'
      }
      operator: 'GreaterThan'
      threshold: 90
      windowSize: 'PT15M'
    }
    action: {
      'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleEmailAction'
      sendToServiceOwners: true
      customEmails: []
    }
  }
  dependsOn: [
    hostingPlanName
  ]
}

resource LongHttpQueue_hostingPlanName 'Microsoft.Insights/alertrules@2014-04-01' = {
  name: 'LongHttpQueue ${hostingPlanName_var}'
  location: location
  tags: {
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName_var}': 'Resource'
    displayName: 'LongHttpQueue${insightsName_var}'
    quickstartName: quickstartTags.name
  }
  properties: {
    name: 'LongHttpQueue ${hostingPlanName_var}'
    description: 'The HTTP queue for the instances of ${hostingPlanName_var} has a large number of pending requests.'
    isEnabled: false
    condition: {
      'odata.type': 'Microsoft.Azure.Management.Insights.Models.ThresholdRuleCondition'
      dataSource: {
        'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleMetricDataSource'
        resourceUri: '${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName_var}'
        metricName: 'HttpQueueLength'
      }
      operator: 'GreaterThan'
      threshold: 100
      windowSize: 'PT5M'
    }
    action: {
      'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleEmailAction'
      sendToServiceOwners: true
      customEmails: []
    }
  }
  dependsOn: [
    hostingPlanName
  ]
}

resource ServerErrors_insightsName 'Microsoft.Insights/alertrules@2014-04-01' = {
  name: 'ServerErrors ${insightsName_var}'
  location: location
  tags: {
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/sites/${webSiteName_var}': 'Resource'
    displayName: 'ServerErrors ${insightsName_var}'
    quickstartName: quickstartTags.name
  }
  properties: {
    name: 'ServerErrors ${webSiteName_var}'
    description: '${webSiteName_var} has some server errors, status code 5xx.'
    isEnabled: false
    condition: {
      'odata.type': 'Microsoft.Azure.Management.Insights.Models.ThresholdRuleCondition'
      dataSource: {
        'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleMetricDataSource'
        resourceUri: '${resourceGroup().id}/providers/Microsoft.Web/sites/${webSiteName_var}'
        metricName: 'Http5xx'
      }
      operator: 'GreaterThan'
      threshold: 0
      windowSize: 'PT5M'
    }
    action: {
      'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleEmailAction'
      sendToServiceOwners: true
      customEmails: []
    }
  }
  dependsOn: [
    webSiteName
  ]
}

resource ForbiddenRequests_insightsName 'Microsoft.Insights/alertrules@2014-04-01' = {
  name: 'ForbiddenRequests ${insightsName_var}'
  location: location
  tags: {
    displayName: 'ForbiddenRequests${insightsName_var}'
    quickstartName: quickstartTags.name
  }
  properties: {
    name: 'ForbiddenRequests ${webSiteName_var}'
    description: '${webSiteName_var} has some requests that are forbidden, status code 403.'
    isEnabled: false
    condition: {
      'odata.type': 'Microsoft.Azure.Management.Insights.Models.ThresholdRuleCondition'
      dataSource: {
        'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleMetricDataSource'
        resourceUri: '${resourceGroup().id}/providers/Microsoft.Web/sites/${webSiteName_var}'
        metricName: 'Http403'
      }
      operator: 'GreaterThan'
      threshold: 0
      windowSize: 'PT5M'
    }
    action: {
      'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleEmailAction'
      sendToServiceOwners: true
      customEmails: []
    }
  }
  dependsOn: [
    webSiteName
  ]
}

resource insightsName 'Microsoft.Insights/components@2014-04-01' = {
  name: insightsName_var
  location: 'East US'
  tags: {
    displayName: 'Component${insightsName_var}'
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/sites/${webSiteName_var}': 'Resource'
    quickstartName: quickstartTags.name
  }
  properties: {
    applicationId: webSiteName_var
  }
  dependsOn: [
    webSiteName
  ]
}

module omsWorkspace '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/', variables('OMSCommonTemplateFolder'), '/', variables('OMSCommonTemplateFileName'), parameters('_artifactsLocationSasToken'))]*/ = {
  name: 'omsWorkspace'
  params: {
    workspaceName: omsWorkspaceName_var
    location: omsRegion
    serviceTier: 'Free'
    quickstartTags: quickstartTags
  }
  dependsOn: []
}

module OMSAutomationRunBooksAndDashboard '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/', variables('OMSWebAppsRunBookAndDashboardTemplateFolder'), '/', variables('OMSWebAppsRunBookAndDashboardTemplateFileName'), parameters('_artifactsLocationSasToken'))]*/ = {
  name: 'OMSAutomationRunBooksAndDashboard'
  params: {
    omsId: reference('omsWorkspace').outputs.workspaceIdOutput.value
    omsKey: reference('omsWorkspace').outputs.sharedKeyOutput.value
    omsWorkspaceName: omsWorkspaceName_var
    automationAccountName: automationAccountName
    automationRegion: automationRegion
    omsworkspaceRegion: omsRegion
    '_artifactsLocation': '${artifactsLocation}/${OMSWebAppsRunBookAndDashboardTemplateFolder}'
    '_artifactsLocationSasToken': artifactsLocationSasToken
    quickstartTags: quickstartTags
  }
  dependsOn: [
    omsWorkspace
  ]
}