param location string {
  metadata: {
    description: 'Location of ressources'
  }
  default: resourceGroup().location
}
param vm_name string {
  metadata: {
    description: 'Local name for the VM can be whatever you want'
  }
}
param adminUsername string {
  metadata: {
    description: 'User name for the Virtual Machine.'
  }
}
param adminPassword string {
  metadata: {
    description: 'Password for the Virtual Machine.'
  }
  secure: true
}
param vmSize string {
  allowed: [
    'Standard_NV6_Promo'
    'Standard_NV12_Promo'
    'Standard_NV24_Promo'
    'Standard_NC6_Promo'
    'Standard_NC12_Promo'
    'Standard_NC24_Promo'
    'Standard_NV6'
    'Standard_NV12'
    'Standard_NV24'
    'Standard_NC6'
    'Standard_NC12'
    'Standard_NC24'
    'Standard_NV6s_v2'
    'Standard_NV12s_v2'
    'Standard_NV24s_v2'
    'Standard_NV12s_v3'
    'Standard_NV24s_v3'
    'Standard_NV48s_v3'
  ]
  metadata: {
    description: 'Desired Size of the VM. Any valid option accepted but if you choose premium storage type you must choose a DS class VM size.'
  }
  default: 'Standard_NV6'
}
param virtualNetwork_name string = 'stream-vnet'
param nic_name string = 'stream-nic'
param publicIPAddress_name string = 'stream-ip'
param dnsprefix string = 'streamvm'
param networkSecurityGroup_name string = 'stream-nsg'
param setupChocolateyScriptFileName string {
  metadata: {
    description: 'PowerShell script name to execute'
  }
  default: 'ChocoInstall.ps1'
}
param artifactsLocation string {
  metadata: {
    description: 'Public uri location of PowerShell Chocolately setup script'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/obs-studio-stream-vm-chocolatey/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.'
  }
  secure: true
  default: ''
}
param chocoPackages string {
  metadata: {
    description: 'List of Chocolatey packages to install separated by a semi-colon eg. linqpad;sysinternals'
  }
  default: 'obs-studio;skype'
}

var vmImagePublisher = 'MicrosoftWindowsDesktop'
var vmImageOffer = 'Windows-10'
var sku = 'rs5-pro'
var scriptFolder = '.'
var setupScriptLocation = uri(artifactsLocation, concat(setupChocolateyScriptFileName, artifactsLocationSasToken))

resource networkSecurityGroup_name_resource 'Microsoft.Network/networkSecurityGroups@2019-07-01' = {
  name: networkSecurityGroup_name
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource virtualNetwork_name_default 'Microsoft.Network/virtualNetworks/subnets@2019-07-01' = {
  name: '${virtualNetwork_name}/default'
  properties: {
    addressPrefix: '10.0.4.0/24'
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  dependsOn: [
    virtualNetwork_name_resource
  ]
}

resource virtualNetwork_name_resource 'Microsoft.Network/virtualNetworks@2019-07-01' = {
  name: virtualNetwork_name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.4.0/24'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.4.0/24'
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
    enableVmProtection: false
  }
}

resource publicIPAddress_name_resource 'Microsoft.Network/publicIPAddresses@2019-07-01' = {
  name: publicIPAddress_name
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Dynamic'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: dnsprefix
    }
  }
}

resource nic_name_resource 'Microsoft.Network/networkInterfaces@2019-07-01' = {
  name: nic_name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: '10.0.4.4'
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddress_name_resource.id
          }
          subnet: {
            id: virtualNetwork_name_default.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    networkSecurityGroup: {
      id: networkSecurityGroup_name_resource.id
    }
  }
  dependsOn: [
    publicIPAddress_name_resource
    virtualNetwork_name_default
    networkSecurityGroup_name_resource
  ]
}

resource vm_name_resource 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vm_name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: vmImagePublisher
        offer: vmImageOffer
        sku: sku
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: '${vm_name}_OsDisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
      }
    }
    osProfile: {
      computerName: vm_name
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic_name_resource.id
        }
      ]
    }
  }
  dependsOn: [
    nic_name_resource
  ]
}

resource vm_name_GPUDrivers 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  name: '${vm_name}/GPUDrivers'
  location: location
  tags: {
    displayName: 'gpu-nvidia-drivers'
  }
  properties: {
    publisher: 'Microsoft.HpcCompute'
    type: 'NvidiaGpuDriverWindows'
    typeHandlerVersion: '1.2'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    vm_name_resource
  ]
}

resource vm_name_SetupChocolatey 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  name: '${vm_name}/SetupChocolatey'
  location: location
  tags: {
    displayName: 'config-choco'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        setupScriptLocation
      ]
      commandToExecute: 'powershell -ExecutionPolicy bypass -File ${scriptFolder}/${setupChocolateyScriptFileName} -chocoPackages ${chocoPackages}'
    }
  }
  dependsOn: [
    vm_name_GPUDrivers
  ]
}