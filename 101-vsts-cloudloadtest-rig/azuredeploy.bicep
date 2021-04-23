@description('Please enter the Azure DevOps Services account name. If you access your Azure DevOps Services account using \'https://dev.azure.com/yourAccountName\' or \'https://yourAccountName.visualstudio.com\', enter yourAccountName.')
param azureDevOpsServicesAccount string

@description('Personal Access Token (PAT) for the Azure DevOps Services account. You should select the scope as \'Load test (read and write)\'. Please refer \'https://www.visualstudio.com/en-us/get-started/setup/use-personal-access-tokens-to-authenticate\' for more details.')
@secure()
param personalAccessToken string

@description('Number of load generating agent machines to provision')
param agentCount int = 1

@description('LoadTest Agent Group Name (can be empty and will default to resource groupname)')
param agentGroupName string = ''

@allowed([
  'Dynamic'
  'Static'
])
@description('Type of public IP allocation method')
param publicIPAddressType string = 'Dynamic'

@description('Username for the virtual machine.')
param adminUsername string

@description('Password for the virtual machine.')
@secure()
param adminPassword string

@description('Location for all resources.')
param location string = resourceGroup().location

var sizeOfDiskInGB = '100'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var addressPrefix = '10.0.0.0/16'
var sequenceVersion = uniqueString(resourceGroup().id)
var uniqueStringValue = substring(sequenceVersion, 3, 7)
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var storageAccountType = 'Standard_LRS'
var vmName = 'vm${uniqueStringValue}'
var vmSize = 'Standard_D4_v2'
var storageAccountName_var = 'storage${uniqueStringValue}'
var virtualNetworkName_var = 'clttemplatelocalagentvnet'
var publicIPAddressName = 'publicip${uniqueStringValue}'
var publicIPAddressType_var = publicIPAddressType
var nicName = 'nic${uniqueStringValue}'
var windowsOSVersion = '2012-R2-Datacenter'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var defaultAgentGroupName = resourceGroup().name
var networkSecurityGroupName_var = 'default-NSG'

resource storageAccountName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageAccountName_var
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource publicIPAddressName_i 'Microsoft.Network/publicIPAddresses@2015-06-15' = [for i in range(0, agentCount): {
  name: '${publicIPAddressName}i${i}'
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType_var
  }
}]

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: virtualNetworkName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource nicName_i 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, agentCount): {
  name: '${nicName}i${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', '${publicIPAddressName}i${i}')
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    'Microsoft.Network/publicIPAddresses/${publicIPAddressName}i${i}'
    virtualNetworkName
  ]
}]

resource vmName_i 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, agentCount): {
  name: '${vmName}i${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${vmName}i${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          diskSizeGB: sizeOfDiskInGB
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${nicName}i${i}')
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'http://${storageAccountName_var}.blob.core.windows.net'
      }
    }
  }
  dependsOn: [
    'Microsoft.Network/networkInterfaces/${nicName}i${i}'
    storageAccountName
  ]
}]

resource vmName_i_DefaultStartupScript 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for i in range(0, agentCount): if (empty(replace(agentGroupName, ' ', ''))) {
  name: '${vmName}i${i}/DefaultStartupScript'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    forceUpdateTag: sequenceVersion
    typeHandlerVersion: '1.8'
    autoUpgradeMinorVersion: false
    settings: {
      fileUris: [
        'https://elsprodch2su1.blob.core.windows.net/ets-containerfor-loadagentresources/bootstrap/ManageVSTSCloudLoadAgent.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File .\\bootstrap\\ManageVSTSCloudLoadAgent.ps1 -TeamServicesAccountName ${azureDevOpsServicesAccount} -PATToken ${personalAccessToken} -AgentGroupName ${defaultAgentGroupName} -ConfigureAgent'
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${vmName}i${i}'
  ]
}]

resource vmName_i_StartupScript 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for i in range(0, agentCount): if (length(replace(agentGroupName, ' ', '')) > 0) {
  name: '${vmName}i${i}/StartupScript'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    forceUpdateTag: sequenceVersion
    typeHandlerVersion: '1.8'
    autoUpgradeMinorVersion: false
    settings: {
      fileUris: [
        'https://elsprodch2su1.blob.core.windows.net/ets-containerfor-loadagentresources/bootstrap/ManageVSTSCloudLoadAgent.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File .\\bootstrap\\ManageVSTSCloudLoadAgent.ps1 -TeamServicesAccountName ${azureDevOpsServicesAccount} -PATToken ${personalAccessToken} -AgentGroupName ${agentGroupName} -ConfigureAgent'
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${vmName}i${i}'
  ]
}]