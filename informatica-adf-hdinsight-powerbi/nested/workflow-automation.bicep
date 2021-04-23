param automationAccountName string

@allowed([
  'Free'
  'Basic'
])
param sku string = 'Basic'
param runbookName string
param credential1Name string = 'Azure_RM_Account_Credentials'
param cred1Username string = 'ash@sysgaininc.onmicrosoft.com'
param cred1Password string = 'Sysgain#@'

@description('Generate a Job ID (GUID) from https://www.guidgenerator.com/ ')
param jobIdWorkflow string = '24b18f62-aa2c-4528-ac10-1e3602eb4053'

@allowed([
  'Japan East'
  'North Europe'
  'South Central US'
  'West Europe'
  'Southeast Asia'
  'East US 2'
])
@description('Automation Service Location')
param location string = 'East US 2'
param runbookUrl string = 'https://raw.githubusercontent.com/sysgain/informatica-p2p/master/runbooks/info-restapi-workflow.ps1'

@description('Tag Values')
param tag object = {
  key1: 'key'
  value1: 'value'
}
param ip string
param sysgain_ms_email string
param sysgain_ms_password string

@description('The same email id used for user_email')
param informatica_user_name string
param informatica_user_password string
param informatica_csa_vmname string
param client_id string
param adfStorageAccName string
param adfStorageAccKey string
param informaticaTags object
param quickstartTags object

resource automationAccountName_resource 'Microsoft.Automation/automationAccounts@2015-01-01-preview' = {
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
  parent: automationAccountName_resource
  name: '${runbookName}'
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
      uri: runbookUrl
      version: '1.0.0.0'
    }
  }
}

resource automationAccountName_credential1Name 'Microsoft.Automation/automationAccounts/credentials@2015-01-01-preview' = {
  parent: automationAccountName_resource
  name: '${credential1Name}'
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
}

resource automationAccountName_jobIdWorkflow 'Microsoft.Automation/automationAccounts/jobs@2015-10-31' = {
  parent: automationAccountName_resource
  name: '${jobIdWorkflow}'
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
      ip: ip
      sysgain_ms_email: sysgain_ms_email
      sysgain_ms_password: sysgain_ms_password
      informatica_user_name: informatica_user_name
      informatica_user_password: informatica_user_password
      client_id: client_id
      informatica_csa_vmname: informatica_csa_vmname
      adfStorageAccName: adfStorageAccName
      adfStorageAccKey: adfStorageAccKey
    }
  }
  dependsOn: [
    automationAccountName_runbookName
    automationAccountName_credential1Name
  ]
}