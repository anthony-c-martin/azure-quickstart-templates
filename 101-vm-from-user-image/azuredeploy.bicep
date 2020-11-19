param location string {
  metadata: {
    description: 'Location for the VM, only certain regions support zones during preview.'
  }
  default: resourceGroup().location
}
param adminUsername string {
  metadata: {
    description: 'Username for the Virtual Machine.'
  }
}
param dnsLabelPrefix string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Virtual Machine.'
  }
  default: 'vm${uniqueString(resourceGroup().id)}'
}
param authenticationType string {
  allowed: [
    'sshPublicKey'
    'password'
  ]
  metadata: {
    description: 'Type of authentication to use on the Virtual Machine. SSH key is recommended.'
  }
  default: 'password'
}
param adminPasswordOrKey string {
  metadata: {
    description: 'SSH Key or password for the Virtual Machine. SSH key is recommended.'
  }
  secure: true
}
param osType string {
  allowed: [
    'Windows'
    'Linux'
  ]
  metadata: {
    description: 'This is the OS that your VM will be running'
  }
}
param osDiskVhdUri string {
  metadata: {
    description: 'Uri of the your user image'
  }
}
param vmSize string {
  metadata: {
    description: 'Size of the VM, this sample uses a Gen 2 VM, see: https://docs.microsoft.com/en-us/azure/virtual-machines/windows/generation-2#generation-2-vm-sizes'
  }
  default: 'Standard_D2s_v3'
}
param vmName string {
  metadata: {
    description: 'Name of the VM'
  }
  default: 'vmFromImage'
}

var storageAccountName = 'diags${uniqueString(resourceGroup().id)}'
var imageName = '${osType}-image'
var nicName = 'myVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressName = 'myPublicIP'
var virtualNetworkName = 'MyVNET'
var networkSecurityGroupName = 'nsgAllowRemoting'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
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

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource imageName_resource 'Microsoft.Compute/images@2019-12-01' = {
  name: imageName
  location: location
  properties: {
    storageProfile: {
      osDisk: {
        osType: osType
        osState: 'Generalized'
        blobUri: osDiskVhdUri
        storageAccountType: 'Standard_LRS'
      }
    }
    hyperVGeneration: 'V2'
  }
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-03-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2020-03-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'RemoteConnection'
        properties: {
          description: 'Allow RDP/SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: ((osType == 'Windows') ? 3389 : 22)
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-03-01' = {
  name: virtualNetworkName
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
        }
      }
    ]
  }
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2020-03-01' = {
  name: nicName
  location: location
  properties: {
    networkSecurityGroup: {
      id: networkSecurityGroupName_resource.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName_resource.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
    virtualNetworkName_resource
    networkSecurityGroupName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        id: imageName_resource.id
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName_resource.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccountName_resource.properties.primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    storageAccountName_resource
    nicName_resource
    imageName_resource
  ]
}

output hostname string = reference(publicIPAddressName).dnsSettings.fqdn