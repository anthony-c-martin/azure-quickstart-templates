@description('Name of the SQL server')
param sqlServerName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The administrator username of the SQL Server.')
param sqlAdministratorLogin string

@description('The administrator password of the SQL Server.')
@secure()
param sqlAdministratorLoginPassword string

@description('Log Analytics workspace name')
param omsWorkspaceName string = 'omsworkspace${uniqueString(resourceGroup().id)}'

@description('Specify the region for your OMS workspace')
param workspaceRegion string

@allowed([
  'free'
  'standalone'
  'pernode'
])
@description('Select the SKU for OMS workspace')
param omsSku string = 'free'

@description('Enable Auditing of Microsoft support operations (DevOps)')
param isMSDevOpsAuditEnabled bool = false

var diagnosticSettingsName = 'SQLSecurityAuditEvents_3d229c42-c7e7-4c97-9a99-ec0d0d8b86c1'

resource omsWorkspaceName_resource 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: omsWorkspaceName
  location: workspaceRegion
  properties: {
    sku: {
      name: omsSku
    }
  }
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

resource sqlServerName_master 'Microsoft.Sql/servers/databases@2017-03-01-preview' = {
  parent: sqlServerName_resource
  location: location
  name: 'master'
  properties: {}
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
      {
        condition: isMSDevOpsAuditEnabled
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

resource sqlServerName_Default 'Microsoft.Sql/servers/devOpsAuditingSettings@2020-08-01-preview' = if (isMSDevOpsAuditEnabled) {
  parent: sqlServerName_resource
  name: 'Default'
  properties: {
    state: 'Enabled'
    isAzureMonitorTargetEnabled: true
  }
}