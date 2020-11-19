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
param dnsLabelPrefix string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Virtual Machine.'
  }
  default: 'ddvm-${uniqueString(resourceGroup().id)}'
}
param OSVersion string {
  allowed: [
    '2019-Datacenter'
    '2016-Datacenter'
    '2016-Datacenter-Server-Core'
    '2016-Datacenter-Server-Core-smalldisk'
    '2016-Datacenter-smalldisk'
    '2016-Datacenter-with-Containers'
    '2016-Nano-Server'
  ]
  metadata: {
    description: 'The Windows version for the VM. This will pick a fully patched image of this given Windows version.'
  }
  default: '2019-Datacenter'
}
param numberOfDataDisks int {
  minValue: 0
  maxValue: 16
  metadata: {
    description: 'The number of dataDisks to be returned in the output array.'
  }
  default: 16
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param vmSize string {
  metadata: {
    description: 'description'
  }
  default: 'Standard_DS4_v2'
}

var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var nicName = 'myVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressName = 'myPublicIP'
var publicIPAddressType = 'Dynamic'
var vmName = 'VMDataDisks'
var virtualNetworkName = 'MyVNET'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
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

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName
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
      copy: [
        {
          name: 'dataDisks'
          count: numberOfDataDisks
          input: {
            diskSizeGB: 1023
            lun: copyIndex('dataDisks')
            createOption: 'Empty'
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    nicName_resource
  ]
}

output hostname string = reference(publicIPAddressName).dnsSettings.fqdn