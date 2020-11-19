param workspaceName string {
  metadata: {
    description: 'Workspace name'
  }
}
param sku string {
  allowed: [
    'pergb2018'
    'Free'
    'Standalone'
    'PerNode'
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'Pricing tier: perGB2018 or legacy tiers (Free, Standalone, PerNode, Standard or Premium), which are not available to all customers.'
  }
  default: 'pergb2018'
}
param dataRetention int {
  minValue: 7
  maxValue: 730
  metadata: {
    description: 'Number of days to retain data.'
  }
  default: 30
}
param location string {
  metadata: {
    description: 'Specifies the location in which to create the workspace.'
  }
  default: resourceGroup().location
}
param automationAccountName string {
  metadata: {
    description: 'Automation account name'
  }
}
param automationAccountLocation string {
  metadata: {
    description: 'Specifies the location in which to create the Automation account.'
  }
}
param sampleGraphicalRunbookName string = 'AzureAutomationTutorial'
param sampleGraphicalRunbookDescription string = 'An example runbook that gets all the Resource Manager resources by using the Run As account (service principal).'
param samplePowerShellRunbookName string = 'AzureAutomationTutorialScript'
param samplePowerShellRunbookDescription string = 'An example runbook that gets all the Resource Manager resources by using the Run As account (service principal).'
param samplePython2RunbookName string = 'AzureAutomationTutorialPython2'
param samplePython2RunbookDescription string = 'An example runbook that gets all the Resource Manager resources by using the Run As account (service principal).'
param artifactsLocation string {
  metadata: {
    description: 'URI to artifacts location'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-automation/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated'
  }
  secure: true
  default: ''
}

resource workspaceName_res 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
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

resource automationAccountName_res 'Microsoft.Automation/automationAccounts@2020-01-13-preview' = {
  name: automationAccountName
  location: automationAccountLocation
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource automationAccountName_sampleGraphicalRunbookName 'Microsoft.Automation/automationAccounts/runbooks@2018-06-30' = {
  name: '${automationAccountName}/${sampleGraphicalRunbookName}'
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
  name: '${automationAccountName}/${samplePowerShellRunbookName}'
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
  name: '${automationAccountName}/${samplePython2RunbookName}'
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
  name: '${workspaceName}/Automation'
  location: location
  properties: {
    resourceId: automationAccountName_res.id
  }
}