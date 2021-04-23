@description('Name of the SQL server')
param sqlServerName string = 'server-${uniqueString(resourceGroup().id, deployment().name)}'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The administrator username of the SQL Server.')
param sqlAdministratorLogin string

@description('The administrator password of the SQL Server.')
@secure()
param sqlAdministratorLoginPassword string

@description('The name of the event hub.')
param eventHubName string = 'eventhub'

@description('The name of the Event Hubs namespace.')
param eventHubNamespaceName string = 'namespace${uniqueString(resourceGroup().id)}'

@description('Name of Namespace Authorization Rule.')
param eventhubAuthorizationRuleName string = 'RootManageSharedAccessKey'

@description('Enable Auditing of Microsoft support operations (DevOps)')
param isMSDevopsAuditEnabled bool = false

var diagnosticSettingsName = 'SQLSecurityAuditEvents_3d229c42-c7e7-4c97-9a99-ec0d0d8b86c1'

resource eventHubNamespaceName_resource 'Microsoft.EventHub/namespaces@2018-01-01-preview' = {
  name: eventHubNamespaceName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {}
}

resource eventHubNamespaceName_eventHubName 'Microsoft.EventHub/namespaces/eventhubs@2017-04-01' = {
  parent: eventHubNamespaceName_resource
  name: '${eventHubName}'
}

resource sqlServerName_resource 'Microsoft.Sql/servers@2019-06-01-preview' = {
  location: location
  name: sqlServerName
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    version: '12.0'
  }
  tags: {
    DisplayName: sqlServerName
  }
}

resource sqlServerName_master 'Microsoft.Sql/servers/databases@2019-06-01-preview' = {
  parent: sqlServerName_resource
  location: location
  name: 'master'
  properties: {}
}

resource sqlServerName_master_microsoft_insights_diagnosticSettingsName 'Microsoft.Sql/servers/databases/providers/diagnosticSettings@2017-05-01-preview' = {
  name: '${sqlServerName}/master/microsoft.insights/${diagnosticSettingsName}'
  properties: {
    name: diagnosticSettingsName
    eventHubAuthorizationRuleId: resourceId('Microsoft.EventHub/namespaces/authorizationRules', eventHubNamespaceName, eventhubAuthorizationRuleName)
    eventHubName: eventHubName
    logs: [
      {
        category: 'SQLSecurityAuditEvents'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
      {
        condition: isMSDevopsAuditEnabled
        category: 'DevOpsOperationsAudit'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
    ]
  }
  dependsOn: [
    sqlServerName_resource
    eventHubNamespaceName_resource
    sqlServerName_master
  ]
}

resource sqlServerName_DefaultAuditingSettings 'Microsoft.Sql/servers/auditingSettings@2017-03-01-preview' = {
  parent: sqlServerName_resource
  name: 'DefaultAuditingSettings'
  properties: {
    state: 'Enabled'
    isAzureMonitorTargetEnabled: true
  }
}

resource sqlServerName_Default 'Microsoft.Sql/servers/devOpsAuditingSettings@2020-08-01-preview' = if (isMSDevopsAuditEnabled) {
  parent: sqlServerName_resource
  name: 'Default'
  properties: {
    state: 'Enabled'
    isAzureMonitorTargetEnabled: true
  }
}