@description('Index to create multiple DCs. Index == 0 means it will be a new domain and a PDCE will be created')
param indx int = 0
param vmNamePrefix string = 'DC-'

@description('Admin username')
param adminUsername string = 'zeAdmin'

@description('Admin password')
@secure()
param adminPassword string

@description('The FQDN of the AD Domain created ')
param domainName string = 'contoso.com'

@description('The location of resources such as templates and DSC modules that the script is dependent. Includes the last forward slash')
param assetLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/301-subnet-driven-deployment/'

@description('Computer Name')
param computerName string = 'dc'

@description('Location for all resources.')
param location string = resourceGroup().location

var adConfigurationFunction = 'CreateADC.ps1\\CreateADC_${dscFiletocall}'
var adModulesURL = '${assetLocation}CreateADC.ps1.zip'
var dscFiletocall = ((indx + 2) % (indx + 1))
var vmName = concat(vmNamePrefix, computerName, indx)

resource vmName_CreateDC_indx 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName}/CreateDC${indx}'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: true
    settings: {
      wmfVersion: '4.0'
      ModulesUrl: adModulesURL
      ConfigurationFunction: adConfigurationFunction
      Properties: {
        DomainName: domainName
        AdminCreds: {
          UserName: adminUsername
          Password: 'PrivateSettingsRef:AdminPassword'
        }
      }
    }
    protectedSettings: {
      Items: {
        AdminPassword: adminPassword
      }
    }
  }
}