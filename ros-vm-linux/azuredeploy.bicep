@description('Location for all resources.')
param location string = resourceGroup().location

@maxLength(8)
@description('Specifies a name for generating resource names.')
param projectName string

@description('Username for the Virtual Machine.')
param adminUsername string

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('The virtual machine size.')
param virtualMachineSize string = 'Standard_D2_v2'

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

@description('The github account and repo alias.')
param githubRepo string = ''

@description('The personal access token to connect to GitHub.')
@secure()
param githubPersonalAccessToken string = ''

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/ros-vm-linux/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var location_var = location
var networkInterfaceName_var = '${projectName}-nic'
var networkSecurityGroupName_var = '${projectName}-nsg'
var virtualNetworkName_var = '${projectName}-vnet'
var publicIpAddressName_var = '${projectName}-ip'
var virtualMachineName_var = '${projectName}-vm'
var ciAgentName = '${projectName}-agent'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, 'default')
var ubuntuOSVersion = '18.04-LTS'
var osDiskType = 'StandardSSD_LRS'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}
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
var nvidiaGpuDriverLinuxUri = uri(artifactsLocation, 'nestedtemplates/nvidiaGpuDriverLinux.json${artifactsLocationSasToken}')
var extensionUrl = uri(artifactsLocation, 'nestedtemplates/customScriptExtension.json${artifactsLocationSasToken}')
var vstsScriptFileUri = uri(artifactsLocation, 'scripts/install-vsts.sh${artifactsLocationSasToken}')
var rosScriptFileUri = uri(artifactsLocation, 'scripts/install-ros.sh${artifactsLocationSasToken}')
var vstsParameters = '${ciAgentName} ${vstsAccount} ${vstsPersonalAccessToken} ${vstsPoolName}'
var githubScriptFileUri = uri(artifactsLocation, 'scripts/install-github.sh${artifactsLocationSasToken}')
var githubParameters = '${ciAgentName} ${githubRepo} ${githubPersonalAccessToken} ${adminUsername}'

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
      id: networkSecurityGroupName.id
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
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
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
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: 'ros-vm-${uniqueString(resourceGroup().id)}'
    }
  }
  sku: {
    name: 'Basic'
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
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: ubuntuOSVersion
        version: 'latest'
      }
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
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
  }
}

module nvidia_gpu_driver_linux '?' /*TODO: replace with correct path to [variables('nvidiaGpuDriverLinuxUri')]*/ = if (contains(virtualMachineSize, 'Standard_NV')) {
  name: 'nvidia-gpu-driver-linux'
  params: {
    vmName: virtualMachineName_var
    location: location_var
  }
  dependsOn: [
    virtualMachineName_ROSInstall
  ]
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
    commandToExecute: 'bash install-ros.sh'
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
    commandToExecute: 'bash install-vsts.sh ${vstsParameters}'
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
    commandToExecute: 'bash install-github.sh ${githubParameters}'
  }
  dependsOn: [
    virtualMachineName_ROSInstall
  ]
}

output adminUsername string = adminUsername
output hostname string = reference(publicIpAddressName_var).dnsSettings.fqdn
output sshCommand string = 'ssh ${adminUsername}@${reference(publicIpAddressName_var).dnsSettings.fqdn}'