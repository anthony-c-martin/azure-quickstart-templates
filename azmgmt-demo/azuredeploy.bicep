@description('Provide a prefix for the Azure mgmt. services that will be created')
param azMgmtPrefix string

@maxValue(10)
@description('Specify the number of VMs to create')
param instanceCount int = 2

@description('Assing a prefix for the VMs you will create')
param vmNamePrefix string = 'az1demo'

@allowed([
  'WinSrv'
  'Linux'
])
@description('Select the OS type to deploy.')
param platform string = 'WinSrv'

@description('Assign a username to the VMs. Default will be \'azureadmin\'.')
param username string = 'azureadmin'

@description('Specify pwd if platform is WinSrv, or ssh if Linux.')
@secure()
param pwdOrSsh string

@description('Specify the name of an existing Resource Group where the VMs will be deployed.')
param vmResourceGroup string

var nestedTemplates = {
  omsRecoveryServices: uri(deployment().properties.templateLink.uri, 'nestedtemplates/omsRecoveryServices.json')
  omsAutomation: uri(deployment().properties.templateLink.uri, 'nestedtemplates/omsAutomation.json')
  omsWorkspace: uri(deployment().properties.templateLink.uri, 'nestedtemplates/omsWorkspace.json')
  managedVMs: uri(deployment().properties.templateLink.uri, 'nestedtemplates/managedVms.json')
  asrRunbooks: uri(deployment().properties.templateLink.uri, 'nestedtemplates/asrRunbooks.json')
  dscConfigs: uri(deployment().properties.templateLink.uri, 'nestedtemplates/dscConfigs.json')
  mgmtDashboards: uri(deployment().properties.templateLink.uri, 'nestedtemplates/mgmtDashboards.json')
}
var resourceNames = {
  omsWorkspace: concat(azMgmtPrefix, uniqueString(resourceGroup().name, '-oms'))
  azureAutomation: concat(azMgmtPrefix, uniqueString(resourceGroup().name, '-auto'))
  azureRecoveryServices: concat(azMgmtPrefix, uniqueString(resourceGroup().name, '-recovery'))
}
var azMgmtLocationMap = {
  eastasia: 'southeastasia'
  southeastasia: 'southeastasia'
  centralus: 'westcentralus'
  eastus: 'eastus'
  eastus2: 'eastus'
  westus: 'westcentralus'
  northcentralus: 'westcentralus'
  southcentralus: 'westcentralus'
  northeurope: 'westeurope'
  westeurope: 'westeurope'
  japanwest: 'southeastasia'
  japaneast: 'southeastasia'
  brazilsouth: 'eastus'
  australiaeast: 'australiasoutheast'
  australiasoutheast: 'australiasoutheast'
  southindia: 'southeastasia'
  centralindia: 'southeastasia'
  westindia: 'southeastasia'
  canadacentral: 'eastus'
  canadaeast: 'eastus'
  uksouth: 'westeurope'
  ukwest: 'westeurope'
  westcentralus: 'westcentralus'
  westus2: 'westcentralus'
  koreacentral: 'southeastasia'
  koreasouth: 'southeastasia'
  eastus2euap: 'eastus'
}
var azMgmtLocation = azMgmtLocationMap[resourceGroup().location]
var azAutoLocationMap = {
  eastasia: 'southeastasia'
  southeastasia: 'southeastasia'
  centralus: 'westcentralus'
  eastus: 'eastus2'
  eastus2: 'eastus2'
  westus: 'westcentralus'
  northcentralus: 'westcentralus'
  southcentralus: 'southcentralus'
  northeurope: 'westeurope'
  westeurope: 'westeurope'
  japanwest: 'southeastasia'
  japaneast: 'southeastasia'
  brazilsouth: 'eastus2'
  australiaeast: 'australiasoutheast'
  australiasoutheast: 'australiasoutheast'
  southindia: 'southeastasia'
  centralindia: 'southeastasia'
  westindia: 'southeastasia'
  canadacentral: 'eastus2'
  canadaeast: 'eastus2'
  uksouth: 'westeurope'
  ukwest: 'westeurope'
  westcentralus: 'westcentralus'
  westus2: 'westcentralus'
  koreacentral: 'southeastasia'
  koreasouth: 'southeastasia'
  eastus2euap: 'eastus2'
}
var azAutoLocation = azAutoLocationMap[resourceGroup().location]

module omsWorkspace '?' /*TODO: replace with correct path to [variables('nestedTemplates').omsWorkspace]*/ = {
  name: 'omsWorkspace'
  params: {
    omsWorkspaceName: resourceNames.omsWorkspace
    omsWorkspaceRegion: azMgmtLocation
  }
  dependsOn: []
}

module omsRecoveryServices '?' /*TODO: replace with correct path to [variables('nestedTemplates').omsRecoveryServices]*/ = {
  name: 'omsRecoveryServices'
  params: {
    omsRecoveryVaultName: resourceNames.azureRecoveryServices
    omsRecoveryVaultRegion: azMgmtLocation
  }
  dependsOn: []
}

module omsAutomation '?' /*TODO: replace with correct path to [variables('nestedTemplates').omsAutomation]*/ = {
  name: 'omsAutomation'
  params: {
    omsAutomationAccountName: resourceNames.azureAutomation
    omsAutomationRegion: azAutoLocation
    omsRecoveryVaultName: resourceNames.azureRecoveryServices
    omsWorkspaceName: resourceNames.omsWorkspace
  }
  dependsOn: [
    omsRecoveryServices
    omsWorkspace
  ]
}

module asrRunbooks '?' /*TODO: replace with correct path to [variables('nestedTemplates').asrRunbooks]*/ = {
  name: 'asrRunbooks'
  params: {
    automationAccountName: resourceNames.azureAutomation
    automationRegion: azAutoLocation
  }
  dependsOn: [
    omsAutomation
  ]
}

module dscConfigs '?' /*TODO: replace with correct path to [variables('nestedTemplates').dscConfigs]*/ = {
  name: 'dscConfigs'
  params: {
    omsAutomationAccountName: resourceNames.azureAutomation
    omsAutomationRegion: azAutoLocation
    omsWorkspaceName: resourceNames.omsWorkspace
  }
  dependsOn: [
    omsAutomation
  ]
}

module deployVMs '?' /*TODO: replace with correct path to [variables('nestedTemplates').managedVMs]*/ = {
  name: 'deployVMs'
  scope: resourceGroup(vmResourceGroup)
  params: {
    instanceCount: instanceCount
    vmNamePrefix: vmNamePrefix
    platform: platform
    userName: username
    pwdOrSsh: pwdOrSsh
    omsRecoveryVaultName: resourceNames.azureRecoveryServices
    omsRecoveryVaultRegion: azMgmtLocation
    omsResourceGroup: resourceGroup().name
    omsWorkspaceName: resourceNames.omsWorkspace
    automationAccountName: resourceNames.azureAutomation
  }
  dependsOn: [
    omsWorkspace
    omsRecoveryServices
    dscConfigs
  ]
}

module mgmtDashboards '?' /*TODO: replace with correct path to [variables('nestedTemplates').mgmtDashboards]*/ = {
  name: 'mgmtDashboards'
  params: {
    omsWorkspaceName: resourceNames.omsWorkspace
    omsRecoveryVaultName: resourceNames.azureRecoveryServices
    omsAutomationAccountName: resourceNames.azureAutomation
    vmResourceGroup: vmResourceGroup
  }
  dependsOn: [
    omsAutomation
    omsWorkspace
    omsRecoveryServices
  ]
}