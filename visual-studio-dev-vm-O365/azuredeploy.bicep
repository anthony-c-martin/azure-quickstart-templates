@allowed([
  'Premium_LRS'
  'Standard_LRS'
])
@description('Which type of storage you want to use')
param storageType string = 'Premium_LRS'

@description('Local name for the VM can be whatever you want')
param vmName string = 'O365VM'

@description('VM admin user name')
param vmAdminUserName string

@description('VM admin password. The supplied password must be between 8-123 characters long and must satisfy at least 3 of password complexity requirements from the following: 1) Contains an uppercase character 2) Contains a lowercase character 3) Contains a numeric digit 4) Contains a special character.')
@secure()
param vmAdminPassword string

@description('Desired Size of the VM.')
param vmSize string = 'Standard_DS2'

@allowed([
  'VS-2015-Comm-VSU3-AzureSDK-29-Win10-N'
  'VS-2015-Comm-AzureSDK-2.9-W10T-Win10-N'
  'VS-2015-Comm-AzureSDK-2.9-WS2012R2'
  'VS-2015-Comm-VSU3-AzureSDK-291-Win10-N'
  'VS-2015-Comm-VSU3-AzureSDK-291-WS2012R2'
  'VS-2015-Ent-AzureSDK-2.9-WS2012R2'
  'VS-2015-Ent-AzureSDK-29-W10T-Win10-N'
  'VS-2015-Ent-VSU3-AzureSDK-291-Win10-N'
  'VS-2015-Ent-VSU3-AzureSDK-291-WS2012R2'
])
@description('Which version of Visual Studio you would like to deploy')
param vmVisualStudioVersion string = 'VS-2015-Comm-VSU3-AzureSDK-29-Win10-N'

@description('DNS Label for the Public IP. Must be lowercase. It should match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.')
param dnsLabelPrefix string

@allowed([
  'Office2016'
  'Office2013'
])
@description('Which version of Office would you would like to deploy')
param officeVersion string = 'Office2016'

@description('PowerShell script name to execute')
param setupOfficeScriptFileName string = 'DeployO365SilentWithVersion.ps1'

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/visual-studio-dev-vm-O365/scripts/'

@description('Location for all resources.')
param location string = resourceGroup().location

var storageAccountName_var = '${uniqueString(resourceGroup().id)}visstudiovm'
var vnet01Prefix = '10.0.0.0/16'
var vnet01Subnet1Name = 'Subnet-1'
var vnet01Subnet1Prefix = '10.0.0.0/24'
var vmImagePublisher = 'MicrosoftVisualStudio'
var vmImageOffer = 'VisualStudio'
var vmOSDiskName = 'VMOSDisk'
var vmSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', 'Vnet01', vnet01Subnet1Name)
var vmStorageAccountContainerName = 'vhds'
var vmNicName_var = '${vmName}NetworkInterface'
var vmIP01Name_var = 'VMIP01'

resource storageAccountName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageAccountName_var
  location: location
  tags: {
    displayName: 'Storage01'
  }
  properties: {
    accountType: storageType
  }
  dependsOn: []
}

resource VNet01 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: 'VNet01'
  location: location
  tags: {
    displayName: 'VNet01'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet01Prefix
      ]
    }
    subnets: [
      {
        name: vnet01Subnet1Name
        properties: {
          addressPrefix: vnet01Subnet1Prefix
        }
      }
    ]
  }
  dependsOn: []
}

resource vmNicName 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: vmNicName_var
  location: location
  tags: {
    displayName: 'VMNic01'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vmSubnetRef
          }
          publicIPAddress: {
            id: vmIP01Name.id
          }
        }
      }
    ]
  }
  dependsOn: [
    VNet01
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: location
  tags: {
    displayName: 'VM01'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmAdminUserName
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: vmImagePublisher
        offer: vmImageOffer
        sku: vmVisualStudioVersion
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNicName.id
        }
      ]
    }
  }
  dependsOn: [
    storageAccountName
  ]
}

resource vmName_SetupOffice 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  parent: vmName_resource
  name: 'SetupOffice'
  location: location
  tags: {
    displayName: 'SetupOffice'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.8'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        concat(artifactsLocation, setupOfficeScriptFileName)
        'https://raw.githubusercontent.com/officedev/Office-IT-Pro-Deployment-Scripts/master/Office-ProPlus-Deployment/Deploy-OfficeClickToRun/DefaultConfiguration.xml'
        'https://raw.githubusercontent.com/officedev/Office-IT-Pro-Deployment-Scripts/master/Office-ProPlus-Deployment/Deploy-OfficeClickToRun/Office2013Setup.exe'
        'https://raw.githubusercontent.com/officedev/Office-IT-Pro-Deployment-Scripts/master/Office-ProPlus-Deployment/Deploy-OfficeClickToRun/Office2016Setup.exe'
        'https://raw.githubusercontent.com/officedev/Office-IT-Pro-Deployment-Scripts/master/Office-ProPlus-Deployment/Deploy-OfficeClickToRun/Edit-OfficeConfigurationFile.ps1'
        'https://raw.githubusercontent.com/officedev/Office-IT-Pro-Deployment-Scripts/master/Office-ProPlus-Deployment/Deploy-OfficeClickToRun/Generate-ODTConfigurationXML.ps1'
        'https://raw.githubusercontent.com/officedev/Office-IT-Pro-Deployment-Scripts/master/Office-ProPlus-Deployment/Deploy-OfficeClickToRun/Install-OfficeClickToRun.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy bypass -File ${setupOfficeScriptFileName} -OfficeVersion ${officeVersion}'
    }
  }
}

resource vmIP01Name 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: vmIP01Name_var
  location: location
  tags: {
    displayName: 'VMIP01'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
  dependsOn: []
}