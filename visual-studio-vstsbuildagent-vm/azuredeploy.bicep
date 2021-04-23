@allowed([
  'Premium_LRS'
  'Standard_LRS'
])
@description('Which type of storage you want to use')
param storageType string = 'Premium_LRS'

@description('Local name for the VM can be whatever you want')
param vmName string

@description('VM admin user name')
param vmAdminUserName string

@description('VM admin password. The supplied password must be between 8-123 characters long and must satisfy at least 3 of password complexity requirements from the following: 1) Contains an uppercase character 2) Contains a lowercase character 3) Contains a numeric digit 4) Contains a special character.')
@secure()
param vmAdminPassword string

@description('Desired Size of the VM. Any valid option accepted but if you choose premium storage type you must choose a DS class VM size.')
param vmSize string = 'Standard_DS2'

@allowed([
  'VS-2015-Comm-VSU3-AzureSDK-29-WS2012R2'
  'VS-2015-Comm-VSU3-AzureSDK-291-WS2012R2'
  'VS-2015-Ent-VSU3-AzureSDK-29-WS2012R2'
  'VS-2017-Comm-Latest-Preview-WS2016'
  'VS-2017-Comm-Latest-WS2016'
  'VS-2017-Comm-WS2016'
  'VS-2017-Ent-Latest-Preview-WS2016'
  'VS-2017-Ent-Latest-WS2016'
  'VS-2017-Ent-WS2016'
])
@description('Which version of Visual Studio you would like to deploy')
param vmVisualStudioVersion string = 'VS-2017-Comm-WS2016'

@description('Globally unique name for per region for the public IP address. For instance, myVMuniqueIP.westus.cloudapp.azure.com. It must conform to the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$.')
param vmIPPublicDnsName string

@description('The Visual Studio Team Services account name, that is, the first part of your VSTSAccount.visualstudio.com')
param vstsAccount string

@description('The personal access token to connect to VSTS')
@secure()
param personalAccessToken string

@description('The Visual Studio Team Services build agent pool for this build agent to join. Use \'Default\' if you don\'t have a separate pool.')
param poolName string = 'Default'

@description('Enable autologon to run the build agent in interactive mode that can sustain machine reboots.<br>Set this to true if the agents will be used to run UI tests.')
param enableAutologon bool = false

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/azure/azure-quickstart-templates/master/visual-studio-vstsbuildagent-vm/'

@description('Location for all resources.')
param location string = resourceGroup().location

var storageAccountName_var = '${uniqueString(resourceGroup().id)}storage'
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

resource storageAccountName 'Microsoft.Storage/storageAccounts@2015-05-01-preview' = {
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

resource VNet01 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
  name: 'VNet01'
  location: location
  tags: {
    displayName: 'Vnet01'
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

resource vmNicName 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
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

resource vmName_CustomScript 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  parent: vmName_resource
  name: 'CustomScript'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.4'
    settings: {
      fileUris: [
        '${artifactsLocation}/InstallVSTSAgent.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -Command .\\InstallVSTSAgent.ps1 -vstsAccount ${vstsAccount} -personalAccessToken ${personalAccessToken} -AgentName ${vmName} -PoolName ${poolName} -runAsAutoLogon ${enableAutologon} -vmAdminUserName ${vmAdminUserName} -vmAdminPassword ${vmAdminPassword}'
    }
  }
}

resource vmIP01Name 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: vmIP01Name_var
  location: location
  tags: {
    displayName: 'VMIP01'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: vmIPPublicDnsName
    }
  }
  dependsOn: []
}