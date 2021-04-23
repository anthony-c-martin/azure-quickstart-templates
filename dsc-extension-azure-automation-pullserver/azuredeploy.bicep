@description('Name of the existing VM to apply the DSC configuration to')
param vmName string

@description('URL for the DSC configuration package. NOTE: Can be a Github url(raw) to the zip file (this is the default value)')
param modulesUrl string = 'https://github.com/Azure/azure-quickstart-templates/raw/master/dsc-extension-azure-automation-pullserver/UpdateLCMforAAPull.zip'

@description('DSC configuration function to call. Should contain filename and function in format fileName.ps1\\configurationfunction')
param configurationFunction string = 'UpdateLCMforAAPull.ps1\\ConfigureLCMforAAPull'

@description('Registration key to use to onboard to the Azure Automation DSC pull/reporting server')
@secure()
param registrationKey string

@description('Registration url of the Azure Automation DSC pull/reporting server')
param registrationUrl string

@description('The name of the node configuration, on the Azure Automation DSC pull server, that this node will be configured as')
param nodeConfigurationName string

@allowed([
  'ApplyOnly'
  'ApplyAndMonitor'
  'ApplyAndAutoCorrect'
])
@description('DSC agent (LCM) configuration mode setting. ApplyOnly, ApplyAndMonitor, or ApplyAndAutoCorrect')
param configurationMode string = 'ApplyAndMonitor'

@description('DSC agent (LCM) configuration mode frequency setting, in minutes')
param configurationModeFrequencyMins int = 15

@description('DSC agent (LCM) refresh frequency setting, in minutes')
param refreshFrequencyMins int = 30

@description('DSC agent (LCM) rebootNodeIfNeeded setting')
param rebootNodeIfNeeded bool = true

@allowed([
  'ContinueConfiguration'
  'StopConfiguration'
])
@description('DSC agent (LCM) actionAfterReboot setting. ContinueConfiguration or StopConfiguration')
param actionAfterReboot string = 'ContinueConfiguration'

@description('DSC agent (LCM) allowModuleOverwrite setting')
param allowModuleOverwrite bool = false

@description('The current datetime, as a string, to force the request to go through ARM even if all fields are the same as last ARM deployment of this template; example in parameters file is in MM/dd/yyyy H:mm:ss tt format')
param timestamp string

@description('Location for all resources.')
param location string = resourceGroup().location

resource vmName_Microsoft_Powershell_DSC 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName}/Microsoft.Powershell.DSC'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      Items: {
        registrationKeyPrivate: registrationKey
      }
    }
    settings: {
      ModulesUrl: modulesUrl
      SasToken: ''
      ConfigurationFunction: configurationFunction
      Properties: [
        {
          Name: 'RegistrationKey'
          Value: {
            UserName: 'PLACEHOLDER_DONOTUSE'
            Password: 'PrivateSettingsRef:registrationKeyPrivate'
          }
          TypeName: 'System.Management.Automation.PSCredential'
        }
        {
          Name: 'RegistrationUrl'
          Value: registrationUrl
          TypeName: 'System.String'
        }
        {
          Name: 'NodeConfigurationName'
          Value: nodeConfigurationName
          TypeName: 'System.String'
        }
        {
          Name: 'ConfigurationMode'
          Value: configurationMode
          TypeName: 'System.String'
        }
        {
          Name: 'ConfigurationModeFrequencyMins'
          Value: configurationModeFrequencyMins
          TypeName: 'System.Int32'
        }
        {
          Name: 'RefreshFrequencyMins'
          Value: refreshFrequencyMins
          TypeName: 'System.Int32'
        }
        {
          Name: 'RebootNodeIfNeeded'
          Value: rebootNodeIfNeeded
          TypeName: 'System.Boolean'
        }
        {
          Name: 'ActionAfterReboot'
          Value: actionAfterReboot
          TypeName: 'System.String'
        }
        {
          Name: 'AllowModuleOverwrite'
          Value: allowModuleOverwrite
          TypeName: 'System.Boolean'
        }
        {
          Name: 'Timestamp'
          Value: timestamp
          TypeName: 'System.String'
        }
      ]
    }
  }
}