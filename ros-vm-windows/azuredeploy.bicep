@description('Location for all resources.')
param location string = resourceGroup().location

@maxLength(8)
@description('Specifies a name for generating resource names.')
param projectName string

@allowed([
  'Standard_D2_v2'
  'Standard_D2_v3'
  'Standard_NV6'
  'Standard_NV12'
  'Standard_NV24'
])
@description('The virtual machine size.')
param virtualMachineSize string = 'Standard_D2_v2'

@allowed([
  'Windows10'
  'VisualStudio2019'
])
@description('The virutal machine image base.')
param vmImage string = 'Windows10'

@description('User name for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@secure()
param adminPassword string

@allowed([
  'None'
  'AzurePipelines'
  'GitHubRunner'
])
@description('The continuous integration provider to register.')
param pipelineProvider string = 'None'

@description('The Visual Studio Team Services account name, that is, the first part of your VSTSAccount.visualstudio.com')
param vstsAccount string = ''

@description('The personal access token to connect to VSTS')
@secure()
param vstsPersonalAccessToken string = ''

@description('The Visual Studio Team Services build agent pool for this build agent to join. Use \'Default\' if you don\'t have a separate pool.')
param vstsPoolName string = 'Default'

@description('Enable autologon to run the build agent in interactive mode that can sustain machine reboots.<br>Set this to true if the agents will be used to run UI tests.')
param enableAutologon bool = false

@description('The github account and repo alias.')
param githubRepo string = ''

@description('The personal access token to connect to GitHub.')
@secure()
param githubPersonalAccessToken string = ''

@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/ros-vm-windows/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

var location_var = location
var networkInterfaceName_var = '${projectName}-nic'
var networkSecurityGroupName_var = '${projectName}-nsg'
var virtualNetworkName_var = '${projectName}-vnet'
var publicIpAddressName_var = '${projectName}-ip'
var virtualMachineName_var = '${projectName}-vm'
var diagnosticsStorageAccountName_var = '${uniqueString(resourceGroup().id)}diag'
var nsgId = networkSecurityGroupName.id
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, 'default')
var networkSecurityGroupRules = [
  {
    name: 'AllowRDP'
    properties: {
      priority: 300
      protocol: 'TCP'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '3389'
    }
  }
  {
    name: 'AllowPSRemoting'
    properties: {
      priority: 301
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '5986'
    }
  }
]
var diagnosticsStorageAccountType = 'Standard_LRS'
var diagnosticsStorageAccountKind = 'Storage'
var addressPrefixes = [
  '10.0.0.0/24'
]
var subnets = [
  {
    name: 'default'
    properties: {
      addressPrefix: '10.0.0.0/24'
    }
  }
]
var publicIpAddressType = 'Dynamic'
var publicIpAddressSku = 'Basic'
var vmImageReferences = {
  VisualStudio2019: {
    publisher: 'MicrosoftVisualStudio'
    offer: 'visualstudio2019latest'
    sku: 'vs-2019-comm-latest-ws2019'
    version: 'latest'
  }
  Windows10: {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'Windows-10'
    sku: 'rs5-enterprise'
    version: 'latest'
  }
}
var osDiskType = 'StandardSSD_LRS'
var rosScriptFileUri = uri(artifactsLocation, 'InstallROS.ps1${artifactsLocationSasToken}')
var vstsScriptFileUri = uri(artifactsLocation, 'InstallVstsAgent.ps1${artifactsLocationSasToken}')
var githubScriptFileUri = uri(artifactsLocation, 'InstallGitHubAgent.ps1${artifactsLocationSasToken}')
var nvidiaGpuDriverWindowsUri = uri(artifactsLocation, 'nestedtemplates/nvidiaGpuDriverWindows.json${artifactsLocationSasToken}')
var extensionUrl = uri(artifactsLocation, 'nestedtemplates/customScriptExtension.json${artifactsLocationSasToken}')
var vstsParameters = '-vstsAccount ${vstsAccount} -personalAccessToken ${vstsPersonalAccessToken} -AgentName ${projectName}-vsts -PoolName ${vstsPoolName} -runAsAutoLogon ${enableAutologon} -vmAdminUserName ${adminUsername} -vmAdminPassword ${adminPassword}'
var githubParameters = '-GitHubRepo ${githubRepo} -GitHubPAT ${githubPersonalAccessToken} -AgentName ${projectName}-github'

resource networkInterfaceName 'Microsoft.Network/networkInterfaces@2018-10-01' = {
  name: networkInterfaceName_var
  location: location_var
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpAddressName.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-02-01' = {
  name: networkSecurityGroupName_var
  location: location_var
  properties: {
    securityRules: networkSecurityGroupRules
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2019-04-01' = {
  name: virtualNetworkName_var
  location: location_var
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: subnets
  }
}

resource publicIpAddressName 'Microsoft.Network/publicIpAddresses@2019-02-01' = {
  name: publicIpAddressName_var
  location: location_var
  properties: {
    publicIPAllocationMethod: publicIpAddressType
  }
  sku: {
    name: publicIpAddressSku
  }
}

resource virtualMachineName 'Microsoft.Compute/virtualMachines@2019-03-01' = {
  name: virtualMachineName_var
  location: location_var
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: vmImageReferences[vmImage]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName.id
        }
      ]
    }
    osProfile: {
      computerName: virtualMachineName_var
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
    licenseType: 'Windows_Client'
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(diagnosticsStorageAccountName.id, '2019-04-01').primaryEndpoints.blob
      }
    }
  }
}

resource diagnosticsStorageAccountName 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: diagnosticsStorageAccountName_var
  location: location_var
  properties: {}
  kind: diagnosticsStorageAccountKind
  sku: {
    name: diagnosticsStorageAccountType
  }
}

module virtualMachineName_ROSInstall '?' /*TODO: replace with correct path to [variables('extensionUrl')]*/ = {
  name: '${virtualMachineName_var}-ROSInstall'
  params: {
    location: location_var
    extensionName: 'cse'
    vmName: virtualMachineName_var
    fileUris: [
      rosScriptFileUri
    ]
    commandToExecute: 'powershell -ExecutionPolicy Unrestricted -file InstallROS.ps1'
  }
  dependsOn: [
    virtualMachineName
  ]
}

module virtualMachineName_VSTSAgentInstall '?' /*TODO: replace with correct path to [variables('extensionUrl')]*/ = if (contains(pipelineProvider, 'AzurePipelines')) {
  name: '${virtualMachineName_var}-VSTSAgentInstall'
  params: {
    location: location_var
    extensionName: 'cse'
    vmName: virtualMachineName_var
    fileUris: [
      vstsScriptFileUri
    ]
    commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -Command "& {./InstallVstsAgent.ps1 ${vstsParameters}}"'
  }
  dependsOn: [
    virtualMachineName_ROSInstall
  ]
}

module virtualMachineName_GitHubAgentInstall '?' /*TODO: replace with correct path to [variables('extensionUrl')]*/ = if (contains(pipelineProvider, 'GitHubRunner')) {
  name: '${virtualMachineName_var}-GitHubAgentInstall'
  params: {
    location: location_var
    extensionName: 'cse'
    vmName: virtualMachineName_var
    fileUris: [
      githubScriptFileUri
    ]
    commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -Command "& {./InstallGitHubAgent.ps1 ${githubParameters}}"'
  }
  dependsOn: [
    virtualMachineName_ROSInstall
  ]
}

module nvidia_gpu_driver_windows '?' /*TODO: replace with correct path to [variables('nvidiaGpuDriverWindowsUri')]*/ = if (contains(virtualMachineSize, 'Standard_NV')) {
  name: 'nvidia-gpu-driver-windows'
  params: {
    vmName: virtualMachineName_var
    location: location_var
  }
  dependsOn: [
    virtualMachineName_ROSInstall
  ]
}

output adminUsername string = adminUsername