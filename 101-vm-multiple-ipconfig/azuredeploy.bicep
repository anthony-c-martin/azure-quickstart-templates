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
var nicName_var = 'myNic1'
var vnetName_var = 'myVNet1'
var publicIPAddressName_var = 'myPublicIP'
var publicIPAddressName2_var = 'myPublicIP2'
var vmName_var = 'myVM1'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetName)
var networkSecurityGroupName_var = 'default-NSG'

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource publicIPAddressName2 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName2_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType2
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix1
    }
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName_var
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

resource vnetName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnetName_var
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

resource nicName 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IPConfig-1'
        properties: {
          primary: true
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName.id
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
            id: publicIPAddressName2.id
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
}

resource vmName 'Microsoft.Compute/virtualMachines@2020-06-01' = {
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
          id: nicName.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
}

output hostname string = reference(publicIPAddressName_var).dnsSettings.fqdn