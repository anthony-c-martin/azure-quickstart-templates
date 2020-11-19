param jobId string {
  metadata: {
    description: 'Unique GUID'
  }
}
param sqlDWServerName string {
  metadata: {
    description: 'Ex- inforp2ptest.database.windows.net'
  }
  default: 'testdwserver234.database.windows.net'
}
param sqlDWDBName string {
  metadata: {
    description: 'SQL Datawarehouse Database Name'
  }
  default: 'testdwdb234'
}
param sqlDWDBAdminName string {
  metadata: {
    description: 'Sql Data Warehouse User Name'
  }
  default: 'sysgain'
}
param sqlDWAdminPassword string {
  metadata: {
    description: 'Sql Data Warehouse Password'
  }
  secure: true
  default: 'Sysga1n4205!'
}
param accountName string {
  metadata: {
    description: 'Name of the automation account. It should be unique'
  }
}
param credentialName string {
  metadata: {
    description: 'Name for credentials'
  }
}
param runbookName string {
  metadata: {
    description: 'Name of the runbook'
  }
  default: 'createtable'
}
param location string = 'South Central US'
param scriptUri string
param runbookDescription string = 'Create a Database Table in User provided Datawarehouse'
param sku string = 'Basic'
param informaticaTags object
param quickstartTags object

resource accountName_res 'Microsoft.Automation/automationAccounts@2015-01-01-preview' = {
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
  name: '${accountName}/${runbookName}'
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
  name: '${accountName}/${credentialName}'
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
  name: '${accountName}/${jobId}'
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
}