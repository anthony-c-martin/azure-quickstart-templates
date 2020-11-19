param adminUsername string {
  metadata: {
    description: 'Username for the Virtual Machine.'
  }
}
param adminPassword string {
  metadata: {
    description: 'Password for the Virtual Machine.'
  }
  secure: true
}
param dnsLabelPrefix string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Virtual Machine.'
  }
}
param windowsOSVersion string {
  allowed: [
    '2008-R2-SP1'
    '2012-Datacenter'
    '2012-R2-Datacenter'
  ]
  metadata: {
    description: 'The Windows version for the VM. This will pick a fully patched image of this given Windows version. Allowed values: 2008-R2-SP1, 2012-Datacenter, 2012-R2-Datacenter.'
  }
  default: '2012-R2-Datacenter'
}
param vmName string {
  metadata: {
    description: 'The name for the VM.'
  }
  default: 'MyVM'
}
param nicName string {
  metadata: {
    description: 'The name for the VM\'s NIC.'
  }
  default: 'myVMNic'
}
param virtualNetworkName string {
  metadata: {
    description: 'The name for the VM\'s VNET.'
  }
  default: 'MyVNET'
}
param publicIPAddressName string {
  metadata: {
    description: 'The name for the VM\'s public IP.'
  }
  default: 'myPublicIP'
}
param subnetName string {
  metadata: {
    description: 'The name for the VM\'s Subnet.'
  }
  default: 'Subnet'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var nicName_var = nicName
var addressPrefix = '10.0.0.0/16'
var subnetName_var = subnetName
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressName_var = publicIPAddressName
var publicIPAddressType = 'Dynamic'
var vmName_var = vmName
var vmSize = 'Standard_A2'
var virtualNetworkName_var = virtualNetworkName
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName_var)
var apiVersion = '2015-06-15'
var hostDNSNameScriptArgument = '*.${location}.cloudapp.azure.com'
var networkSecurityGroupName_var = 'default-NSG'

resource publicIPAddressName_res 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

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

resource virtualNetworkName_res 'Microsoft.Network/virtualNetworks@2015-06-15' = {
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
        name: subnetName_var
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

resource nicName_res 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName_res.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
}

resource vmName_res 'Microsoft.Compute/virtualMachines@2016-04-30-preview' = {
  name: vmName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
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
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName_res.id
        }
      ]
    }
  }
}

resource vmName_WinRMCustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@[variables(\'apiVersion\')]' = {
  name: '${vmName_var}/WinRMCustomScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.4'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-winrm-windows/ConfigureWinRM.ps1'
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-winrm-windows/makecert.exe'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -file ConfigureWinRM.ps1 ${hostDNSNameScriptArgument}'
    }
  }
}