param sqlServerName string {
  metadata: {
    description: 'Name of the SQL server'
  }
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
param omsWorkspaceName string {
  metadata: {
    description: 'Log Analytics workspace name'
  }
  default: 'omsworkspace${uniqueString(resourceGroup().id)}'
}
param workspaceRegion string {
  allowed: [
    'Southeast Asia'
    'Australia Southeast'
    'West Europe'
    'East US'
  ]
  metadata: {
    description: 'Specify the region for your OMS workspace'
  }
  default: 'East US'
}
param omsSku string {
  allowed: [
    'free'
    'standalone'
    'pernode'
  ]
  metadata: {
    description: 'Select the SKU for OMS workspace'
  }
  default: 'free'
}

var diagnosticSettingsName = 'SQLSecurityAuditEvents_3d229c42-c7e7-4c97-9a99-ec0d0d8b86c1'

resource omsWorkspaceName_resource 'Microsoft.OperationalInsights/workspaces@2017-04-26-preview' = {
  name: omsWorkspaceName
  location: workspaceRegion
  properties: {
    sku: {
      name: omsSku
    }
  }
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
    workspaceId: omsWorkspaceName_resource.id
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
    omsWorkspaceName_resource
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