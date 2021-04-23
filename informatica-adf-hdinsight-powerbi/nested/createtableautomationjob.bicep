@description('Unique GUID')
param jobId string

@description('Ex- inforp2ptest.database.windows.net')
param sqlDWServerName string = 'testdwserver234.database.windows.net'

@description('SQL Datawarehouse Database Name')
param sqlDWDBName string = 'testdwdb234'

@description('Sql Data Warehouse User Name')
param sqlDWDBAdminName string = 'sysgain'

@description('Sql Data Warehouse Password')
@secure()
param sqlDWAdminPassword string = 'Sysga1n4205!'

@description('Name of the automation account. It should be unique')
param accountName string

@description('Name for credentials')
param credentialName string

@description('Name of the runbook')
param runbookName string = 'createtable'
param location string = 'South Central US'
param scriptUri string
param runbookDescription string = 'Create a Database Table in User provided Datawarehouse'
param sku string = 'Basic'
param informaticaTags object
param quickstartTags object

resource accountName_resource 'Microsoft.Automation/automationAccounts@2015-01-01-preview' = {
  name: accountName
  location: location
  tags: {
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
  properties: {
    sku: {
      name: sku
    }
  }
}

resource accountName_runbookName 'Microsoft.Automation/automationAccounts/runbooks@2015-01-01-preview' = {
  parent: accountName_resource
  name: '${runbookName}'
  location: location
  tags: {
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
  properties: {
    runbookType: 'Script'
    logProgress: false
    logVerbose: false
    description: runbookDescription
    publishContentLink: {
      uri: scriptUri
      version: '1.0.0.0'
    }
  }
}

resource accountName_credentialName 'Microsoft.Automation/automationAccounts/credentials@2015-01-01-preview' = {
  parent: accountName_resource
  name: '${credentialName}'
  location: location
  tags: {
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
  properties: {
    userName: sqlDWDBAdminName
    password: sqlDWAdminPassword
  }
}

resource accountName_jobId 'Microsoft.Automation/automationAccounts/jobs@2015-10-31' = {
  parent: accountName_resource
  name: '${jobId}'
  location: location
  tags: {
    key: 'value'
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
  properties: {
    runbook: {
      name: runbookName
    }
    parameters: {
      credentialName: credentialName
      ServerName: '${sqlDWServerName}.database.windows.net'
      DatabaseName: sqlDWDBName
      DBUsername: sqlDWDBAdminName
      DBPassword: sqlDWAdminPassword
    }
  }
  dependsOn: [
    accountName_credentialName
    accountName_runbookName
  ]
}