param automationAccountName string
param sku string {
  allowed: [
    'Free'
    'Basic'
  ]
  default: 'Free'
}
param runbookName string
param credential1Name string = 'Azure_RM_Account_Credentials'
param cred1Username string = 'ash@sysgaininc.onmicrosoft.com'
param cred1Password string = 'Sysgain#@'
param jobIdCont string {
  metadata: {
    description: 'Generate a Job ID (GUID) from https://www.guidgenerator.com/online-guid-generator.aspx '
  }
}
param location string {
  allowed: [
    'Japan East'
    'North Europe'
    'South Central US'
    'West Europe'
    'Southeast Asia'
    'East US 2'
  ]
  metadata: {
    description: 'Automation Service Location'
  }
  default: 'East US 2'
}
param scriptUri string
param tag object {
  metadata: {
    description: 'Tag Values'
  }
  default: {
    key1: 'key'
    value1: 'value'
  }
}
param adfStorageAccKey string
param adfStorageAccName string
param informaticaTags object
param quickstartTags object

resource automationAccountName_res 'Microsoft.Automation/automationAccounts@2015-01-01-preview' = {
  name: automationAccountName
  location: location
  tags: {
    '${tag.key1}': tag.value1
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
  properties: {
    sku: {
      name: sku
    }
  }
}

resource automationAccountName_runbookName 'Microsoft.Automation/automationAccounts/runbooks@2015-01-01-preview' = {
  name: '${automationAccountName}/${runbookName}'
  location: location
  tags: {
    '${tag.key1}': tag.value1
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
  properties: {
    runbookType: 'Script'
    logProgress: false
    logVerbose: false
    description: null
    publishContentLink: {
      uri: scriptUri
      version: '1.0.0.0'
    }
  }
  dependsOn: [
    automationAccountName_res
  ]
}

resource automationAccountName_credential1Name 'Microsoft.Automation/automationAccounts/credentials@2015-01-01-preview' = {
  name: '${automationAccountName}/${credential1Name}'
  location: location
  tags: {
    '${tag.key1}': tag.value1
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
  properties: {
    userName: cred1Username
    password: cred1Password
  }
  dependsOn: [
    automationAccountName_res
  ]
}

resource automationAccountName_jobIdCont 'Microsoft.Automation/automationAccounts/jobs@2015-10-31' = {
  name: '${automationAccountName}/${jobIdCont}'
  location: location
  tags: {
    '${tag.key1}': tag.value1
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
  properties: {
    runbook: {
      name: runbookName
    }
    parameters: {
      adfStorageAccName: adfStorageAccName
      adfStorageAccKey: adfStorageAccKey
    }
  }
  dependsOn: [
    automationAccountName_res
    automationAccountName_runbookName
    automationAccountName_credential1Name
  ]
}