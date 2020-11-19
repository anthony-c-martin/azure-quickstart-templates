param sqlServerName string {
  metadata: {
    description: 'Name of the SQL server'
  }
  default: 'server-${uniqueString(resourceGroup().id, deployment().name)}'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param sqlAdministratorLogin string {
  metadata: {
    description: 'The administrator username of the SQL Server.'
  }
}
param sqlAdministratorLoginPassword string {
  metadata: {
    description: 'The administrator password of the SQL Server.'
  }
  secure: true
}
param eventHubName string {
  metadata: {
    description: 'The name of the event hub.'
  }
  default: 'eventhub'
}
param eventHubNamespaceName string {
  metadata: {
    description: 'The name of the Event Hubs namespace.'
  }
  default: 'namespace${uniqueString(resourceGroup().id)}'
}
param eventhubAuthorizationRuleName string {
  metadata: {
    description: 'Name of Namespace Authorization Rule.'
  }
  default: 'RootManageSharedAccessKey'
}

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
  name: '${eventHubNamespaceName}/${eventHubName}'
  dependsOn: [
    eventHubNamespaceName_resource
  ]
}

resource sqlServerName_resource 'Microsoft.Sql/servers@2015-05-01-preview' = {
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

resource sqlServerName_master 'Microsoft.Sql/servers/databases@2017-03-01-preview' = {
  location: location
  name: '${sqlServerName}/master'
  properties: {}
  dependsOn: [
    sqlServerName_resource
  ]
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
    ]
  }
  dependsOn: [
    sqlServerName_resource
    eventHubNamespaceName_resource
    sqlServerName_master
  ]
}

resource sqlServerName_DefaultAuditingSettings 'Microsoft.Sql/servers/auditingSettings@2017-03-01-preview' = {
  name: '${sqlServerName}/DefaultAuditingSettings'
  properties: {
    State: 'Enabled'
    auditActionsAndGroups: null
    isAzureMonitorTargetEnabled: true
  }
  dependsOn: [
    sqlServerName_resource
  ]
}