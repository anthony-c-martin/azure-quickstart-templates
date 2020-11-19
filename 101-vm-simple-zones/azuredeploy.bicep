param vmName string {
  metadata: {
    description: 'The name of you Virtual Machine.'
  }
  default: 'linuxvm'
}
param adminUsername string {
  metadata: {
    description: 'Username for the Virtual Machine.'
  }
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
param dnsLabelPrefix string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Virtual Machine.'
  }
  default: toLower('linuxvm-${uniqueString(resourceGroup().id)}')
}
param ubuntuOSVersion string {
  allowed: [
    '12.04.5-LTS'
    '14.04.5-LTS'
    '16.04.0-LTS'
    '18.04-LTS'
  ]
  metadata: {
    description: 'The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.'
  }
  default: '18.04-LTS'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param VmSize string {
  metadata: {
    description: 'The size of the VM'
  }
  default: 'Standard_B2s'
}
param virtualNetworkName string {
  metadata: {
    description: 'Name of the VNET'
  }
  default: 'vNet'
}
param subnetName string {
  metadata: {
    description: 'Name of the subnet in the virtual network'
  }
  default: 'Subnet'
}
param networkSecurityGroupName string {
  metadata: {
    description: 'Name of the Network Security Group'
  }
  default: 'SecGroupNet'
}
param zone string {
  allowed: [
    '1'
    '2'
    '3'
  ]
  metadata: {
    description: 'Zone number for the virtual machine'
  }
  default: '1'
}

var publicIpAddressName = '${vmName}PublicIP'
var networkInterfaceName = '${vmName}NetInt'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var osDiskType = 'Standard_LRS'
var subnetAddressPrefix = '10.1.0.0/24'
var addressPrefix = '10.1.0.0/16'
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

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'TCP'
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

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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
          addressPrefix: subnetAddressPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

resource publicIpAddressName_resource 'Microsoft.Network/publicIpAddresses@2020-05-01' = {
  name: publicIpAddressName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  zones: [
    zone
  ]
  properties: {
    publicIpAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
    idleTimeoutInMinutes: 4
  }
}

resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIpAddress: {
            id: publicIpAddressName_resource.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroupName_resource.id
    }
  }
  dependsOn: [
    networkSecurityGroupName_resource
    virtualNetworkName_resource
    publicIpAddressName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName
  location: location
  zones: [
    zone
  ]
  properties: {
    hardwareProfile: {
      vmSize: VmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'fromImage'
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
          id: networkInterfaceName_resource.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
  }
  dependsOn: [
    networkInterfaceName_resource
  ]
}

output adminUsername_output string = adminUsername
output hostname string = reference(publicIpAddressName).dnsSettings.fqdn
output sshCommand string = 'ssh ${adminUsername}@${reference(publicIpAddressName).dnsSettings.fqdn}'