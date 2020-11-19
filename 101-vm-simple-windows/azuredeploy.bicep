param adminUsername string {
  metadata: {
    description: 'Username for the Virtual Machine.'
  }
}
param adminPassword string {
  minLength: 12
  metadata: {
    description: 'Password for the Virtual Machine.'
  }
  secure: true
}
param dnsLabelPrefix string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Virtual Machine.'
  }
  default: toLower('${vmName}-${uniqueString(resourceGroup().id, vmName)}')
}
param publicIpName string {
  metadata: {
    description: 'Name for the Public IP used to access the Virtual Machine.'
  }
  default: 'myPublicIP'
}
param publicIPAllocationMethod string {
  allowed: [
    'Dynamic'
    'Static'
  ]
  metadata: {
    description: 'Allocation method for the Public IP used to access the Virtual Machine.'
  }
  default: 'Dynamic'
}
param publicIpSku string {
  allowed: [
    'Basic'
    'Standard'
  ]
  metadata: {
    description: 'SKU for the Public IP used to access the Virtual Machine.'
  }
  default: 'Basic'
}
param OSVersion string {
  allowed: [
    '2008-R2-SP1'
    '2012-Datacenter'
    '2012-R2-Datacenter'
    '2016-Nano-Server'
    '2016-Datacenter-with-Containers'
    '2016-Datacenter'
    '2019-Datacenter'
    '2019-Datacenter-Core'
    '2019-Datacenter-Core-smalldisk'
    '2019-Datacenter-Core-with-Containers'
    '2019-Datacenter-Core-with-Containers-smalldisk'
    '2019-Datacenter-smalldisk'
    '2019-Datacenter-with-Containers'
    '2019-Datacenter-with-Containers-smalldisk'
  ]
  metadata: {
    description: 'The Windows version for the VM. This will pick a fully patched image of this given Windows version.'
  }
  default: '2019-Datacenter'
}
param vmSize string {
  metadata: {
    description: 'Size of the virtual machine.'
  }
  default: 'Standard_D2_v3'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param vmName string {
  metadata: {
    description: 'Name of the virtual machine.'
  }
  default: 'simple-vm'
}

var storageAccountName = 'bootdiags${uniqueString(resourceGroup().id)}'
var nicName = 'myVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName = 'MyVNET'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var networkSecurityGroupName = 'default-NSG'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource publicIPName_resource 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIpName
  location: location
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: publicIPAllocationMethod
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
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
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-06-01' = {
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

resource nicName_resource 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPName_resource.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPName_resource
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
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          diskSizeGB: 1023
          lun: 0
          createOption: 'Empty'
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
  ]
}

output hostname string = reference(publicIpName).dnsSettings.fqdn