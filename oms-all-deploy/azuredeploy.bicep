param omsRecoveryVaultName string {
  metadata: {
    description: 'Assign a name for the ASR Recovery Vault'
  }
}
param omsRecoveryVaultRegion string {
  allowed: [
    'West US'
    'East US'
    'North Europe'
    'West Europe'
    'Brazil South'
    'East Asia'
    'Southeast Asia'
    'North Central US'
    'South Central US'
    'Japan East'
    'Japan West'
    'Australia East'
    'Australia Southeast'
    'Central US'
    'East US 2'
    'Central India'
    'South India'
  ]
  metadata: {
    description: 'Specify the region for your Recovery Vault'
  }
  default: 'West Europe'
}
param omsWorkspaceName string {
  metadata: {
    description: 'Assign a name for the Log Analytic Workspace Name'
  }
}
param omsWorkspaceRegion string {
  allowed: [
    'Australia Southeast'
    'East US'
    'Japan East'
    'Southeast Asia'
    'UK South'
    'West Central US'
    'West Europe'
    'North Europe'
  ]
  metadata: {
    description: 'Specify the region for your Workspace'
  }
  default: 'West Europe'
}
param omsAutomationAccountName string {
  metadata: {
    description: 'Assign a name for the Automation account'
  }
}
param omsAutomationRegion string {
  allowed: [
    'Japan East'
    'East US 2'
    'West Europe'
    'Southeast Asia'
    'South Central US'
    'North Europe'
    'Canada Central'
    'Australia Southeast'
    'Central India'
    'Japan East'
  ]
  metadata: {
    description: 'Specify the region for your Automation account'
  }
  default: 'West Europe'
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/oms-all-deploy'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated'
  }
  secure: true
  default: ''
}
param azureAdmin string {
  metadata: {
    description: 'Enter your service admin user'
  }
}
param azureAdminPwd string {
  metadata: {
    description: 'Enter the pwd for the service admin user. The pwd is enrypted during runtime and in the Automation assets'
  }
  secure: true
}

var nestedTemplates = {
  omsRecoveryServices: '${artifactsLocation}/nestedtemplates/omsRecoveryServices.json${artifactsLocationSasToken}'
  omsAutomation: '${artifactsLocation}/nestedtemplates/omsAutomation.json${artifactsLocationSasToken}'
  omsWorkspace: '${artifactsLocation}/nestedtemplates/omsWorkspace.json${artifactsLocationSasToken}'
}

module omsWorkspace '<failed to parse [variables(\'nestedTemplates\').omsWorkspace]>' = {
  name: 'omsWorkspace'
  params: {
    omsWorkspaceName: omsWorkspaceName
    omsWorkspaceRegion: omsWorkspaceRegion
  }
  dependsOn: [
    omsRecoveryServices
  ]
}

module omsRecoveryServices '<failed to parse [variables(\'nestedTemplates\').omsRecoveryServices]>' = {
  name: 'omsRecoveryServices'
  params: {
    omsRecoveryVaultName: omsRecoveryVaultName
    omsRecoveryVaultRegion: omsRecoveryVaultRegion
  }
}

module omsAutomation '<failed to parse [variables(\'nestedTemplates\').omsAutomation]>' = {
  name: 'omsAutomation'
  params: {
    omsAutomationAccountName: omsAutomationAccountName
    omsAutomationRegion: omsAutomationRegion
    omsRecoveryVaultName: omsRecoveryVaultName
    omsWorkspaceName: omsWorkspaceName
    azureAdmin: azureAdmin
    azureAdminPwd: azureAdminPwd
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    omsRecoveryServices
    omsWorkspace
  ]
}