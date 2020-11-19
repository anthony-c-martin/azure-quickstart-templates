param adminUsername string {
  metadata: {
    description: 'Admin username'
  }
}
param adminPassword string {
  metadata: {
    description: 'Admin password'
  }
  secure: true
}
param dnsLabelPrefix string {
  metadata: {
    description: 'DNS for PublicIPAddressName1'
  }
}
param dnsLabelPrefix1 string {
  metadata: {
    description: 'DNS for PublicIPAddressName2'
  }
}
param OSVersion string {
  allowed: [
    '2012-Datacenter'
    '2012-R2-Datacenter'
    '2016-Nano-Server'
    '2016-Datacenter-with-Containers'
    '2016-Datacenter'
    '18.04-LTS'
    '7.2'
  ]
  metadata: {
    description: 'The Windows/Linux version for the VM. This will pick a fully patched image of this given Windows/Linux version.'
  }
}
param imagePublisher string {
  allowed: [
    'Canonical'
    'MicrosoftWindowsServer'
    'RedHat'
  ]
  metadata: {
    description: 'The Windows/Linux image publisher for the selected VM. '
  }
}
param imageOffer string {
  allowed: [
    'UbuntuServer'
    'RHEL'
    'WindowsServer'
  ]
  metadata: {
    description: 'The Windows/Linux image for the selected VM. '
  }
}
param vmSize string {
  metadata: {
    description: 'description'
  }
  default: 'Standard_A1_v2'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var addressPrefix = '10.0.0.0/16'
var subnetName = 'mySubnet'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressType = 'Static'
var publicIPAddressType2 = 'Static'
var nicName = 'myNic1'
var vnetName = 'myVNet1'
var publicIPAddressName = 'myPublicIP'
var publicIPAddressName2 = 'myPublicIP2'
var vmName = 'myVM1'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
var networkSecurityGroupName = 'default-NSG'

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource publicIPAddressName2_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName2
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType2
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix1
    }
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-22'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnetName
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
            id: networkSecurityGroupName_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    networkSecurityGroupName_resource
  ]
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IPConfig-1'
        properties: {
          primary: true
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName_resource.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
      {
        name: 'IPConfig-2'
        properties: {
          privateIPAddress: '10.0.0.5'
          privateIPAllocationMethod: 'Static'
          publicIPAddress: {
            id: publicIPAddressName2_resource.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
      {
        name: 'IPConfig-3'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
    vnetName_resource
    publicIPAddressName2_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName_resource.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
  dependsOn: [
    nicName_resource
  ]
}

output hostname string = reference(publicIPAddressName).dnsSettings.fqdn