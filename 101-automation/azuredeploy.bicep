@description('Workspace name')
param workspaceName string

@allowed([
  'pergb2018'
  'Free'
  'Standalone'
  'PerNode'
  'Standard'
  'Premium'
])
@description('Pricing tier: perGB2018 or legacy tiers (Free, Standalone, PerNode, Standard or Premium), which are not available to all customers.')
param sku string = 'pergb2018'

@minValue(7)
@maxValue(730)
@description('Number of days to retain data.')
param dataRetention int = 30

@description('Specifies the location in which to create the workspace.')
param location string = resourceGroup().location

@description('Automation account name')
param automationAccountName string

@description('Specifies the location in which to create the Automation account.')
param automationAccountLocation string
param sampleGraphicalRunbookName string = 'AzureAutomationTutorial'
param sampleGraphicalRunbookDescription string = 'An example runbook that gets all the Resource Manager resources by using the Run As account (service principal).'
param samplePowerShellRunbookName string = 'AzureAutomationTutorialScript'
param samplePowerShellRunbookDescription string = 'An example runbook that gets all the Resource Manager resources by using the Run As account (service principal).'
param samplePython2RunbookName string = 'AzureAutomationTutorialPython2'
param samplePython2RunbookDescription string = 'An example runbook that gets all the Resource Manager resources by using the Run As account (service principal).'

@description('URI to artifacts location')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-automation/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated')
@secure()
param artifactsLocationSasToken string = ''

resource workspaceName_resource 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: dataRetention
    features: {
      searchVersion: 1
      legacy: 0
    }
  }
}

resource automationAccountName_resource 'Microsoft.Automation/automationAccounts@2020-01-13-preview' = {
  name: automationAccountName
  location: automationAccountLocation
  properties: {
    sku: {
      name: 'Basic'
    }
  }
  dependsOn: [
    workspaceName_resource
  ]
}

resource automationAccountName_sampleGraphicalRunbookName 'Microsoft.Automation/automationAccounts/runbooks@2018-06-30' = {
  parent: automationAccountName_resource
  name: '${sampleGraphicalRunbookName}'
  location: automationAccountLocation
  properties: {
    runbookType: 'GraphPowerShell'
    logProgress: 'false'
    logVerbose: 'false'
    description: sampleGraphicalRunbookDescription
    publishContentLink: {
      uri: uri(artifactsLocation, 'scripts/AzureAutomationTutorial.graphrunbook${artifactsLocationSasToken}')
      version: '1.0.0.0'
    }
  }
}

resource automationAccountName_samplePowerShellRunbookName 'Microsoft.Automation/automationAccounts/runbooks@2018-06-30' = {
  parent: automationAccountName_resource
  name: '${samplePowerShellRunbookName}'
  location: automationAccountLocation
  properties: {
    runbookType: 'PowerShell'
    logProgress: 'false'
    logVerbose: 'false'
    description: samplePowerShellRunbookDescription
    publishContentLink: {
      uri: uri(artifactsLocation, 'scripts/AzureAutomationTutorial.ps1${artifactsLocationSasToken}')
      version: '1.0.0.0'
    }
  }
}

resource automationAccountName_samplePython2RunbookName 'Microsoft.Automation/automationAccounts/runbooks@2018-06-30' = {
  parent: automationAccountName_resource
  name: '${samplePython2RunbookName}'
  location: automationAccountLocation
  properties: {
    runbookType: 'Python2'
    logProgress: 'false'
    logVerbose: 'false'
    description: samplePython2RunbookDescription
    publishContentLink: {
      uri: uri(artifactsLocation, 'scripts/AzureAutomationTutorialPython2.py${artifactsLocationSasToken}')
      version: '1.0.0.0'
    }
  }
}

resource workspaceName_Automation 'Microsoft.OperationalInsights/workspaces/linkedServices@2020-08-01' = {
  parent: workspaceName_resource
  name: 'Automation'
  location: location
  properties: {
    resourceId: automationAccountName_resource.id
  }
}