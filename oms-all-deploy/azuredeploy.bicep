@description('Assign a name for the ASR Recovery Vault')
param omsRecoveryVaultName string

@allowed([
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
])
@description('Specify the region for your Recovery Vault')
param omsRecoveryVaultRegion string = 'West Europe'

@description('Assign a name for the Log Analytic Workspace Name')
param omsWorkspaceName string

@allowed([
  'Australia Southeast'
  'East US'
  'Japan East'
  'Southeast Asia'
  'UK South'
  'West Central US'
  'West Europe'
  'North Europe'
])
@description('Specify the region for your Workspace')
param omsWorkspaceRegion string = 'West Europe'

@description('Assign a name for the Automation account')
param omsAutomationAccountName string

@allowed([
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
])
@description('Specify the region for your Automation account')
param omsAutomationRegion string = 'West Europe'

@description('The base URI where artifacts required by this template are located')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/oms-all-deploy'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated')
@secure()
param artifactsLocationSasToken string = ''

@description('Enter your service admin user')
param azureAdmin string

@description('Enter the pwd for the service admin user. The pwd is enrypted during runtime and in the Automation assets')
@secure()
param azureAdminPwd string

var nestedTemplates = {
  omsRecoveryServices: '${artifactsLocation}/nestedtemplates/omsRecoveryServices.json${artifactsLocationSasToken}'
  omsAutomation: '${artifactsLocation}/nestedtemplates/omsAutomation.json${artifactsLocationSasToken}'
  omsWorkspace: '${artifactsLocation}/nestedtemplates/omsWorkspace.json${artifactsLocationSasToken}'
}

module omsWorkspace '?' /*TODO: replace with correct path to [variables('nestedTemplates').omsWorkspace]*/ = {
  name: 'omsWorkspace'
  params: {
    omsWorkspaceName: omsWorkspaceName
    omsWorkspaceRegion: omsWorkspaceRegion
  }
  dependsOn: [
    omsRecoveryServices
  ]
}

module omsRecoveryServices '?' /*TODO: replace with correct path to [variables('nestedTemplates').omsRecoveryServices]*/ = {
  name: 'omsRecoveryServices'
  params: {
    omsRecoveryVaultName: omsRecoveryVaultName
    omsRecoveryVaultRegion: omsRecoveryVaultRegion
  }
}

module omsAutomation '?' /*TODO: replace with correct path to [variables('nestedTemplates').omsAutomation]*/ = {
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