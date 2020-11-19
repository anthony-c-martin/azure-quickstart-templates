param vmName string {
  metadata: {
    description: 'SQL IaaS VM machine name'
  }
}
param vmSize string {
  metadata: {
    description: 'SQL IaaS VM size. Use Azure VM size name from MSDN'
  }
}
param sqlImageOffer string {
  allowed: [
    'sql2019-ws2019'
    'sql2019-ws2016'
  ]
  metadata: {
    description: 'SQL Server Gallery Image Offer'
  }
  default: 'sql2019-ws2019'
}
param sqlImageSku string {
  allowed: [
    'Enterprise'
    'Standard'
    'Web'
  ]
  metadata: {
    description: 'SQL Server Gallery Image SKU'
  }
  default: 'Enterprise'
}
param sqlImageVersion string {
  metadata: {
    description: 'SQL Server Gallery Image Published Version'
  }
  default: 'latest'
}
param username string {
  metadata: {
    description: 'SQL IaaS VM local administrator username'
  }
}
param password string {
  metadata: {
    description: 'SQL IaaS VM local administrator password'
  }
  secure: true
}
param storageName string {
  metadata: {
    description: 'SQL IaaS VM data and OS disks storage service'
  }
}
param storageType string {
  allowed: [
    'Standard_LRS'
    'Standard_GRS'
    'Standard_ZRS'
  ]
  metadata: {
    description: 'SQL IaaS VM data and OS disks storage type'
  }
  default: 'Standard_LRS'
}
param vnetName string {
  metadata: {
    description: 'SQL IaaS VM virtual network name'
  }
}
param networkAddressSpace string {
  metadata: {
    description: 'SQL IaaS VM virtual network IPv4 address space'
  }
  default: '10.10.0.0/26'
}
param subnetName string {
  metadata: {
    description: 'SQL IaaS VM virtual network subnet name'
  }
}
param subnetAddressPrefix string {
  metadata: {
    description: 'SQL IaaS VM virtual network subnet IPv4 address prefix'
  }
  default: '10.10.0.0/28'
}
param publicDnsName string {
  metadata: {
    description: 'DNS name for the VM'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var vmnic = '${vmName}devnic'
var vmosdisk = '${vmName}osdisk'
var vnetSubNetID = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
var networkSecurityGroupName = '${subnetName}-nsg'

resource storageName_resource 'Microsoft.Storage/storageAccounts@2015-05-01-preview' = {
  name: storageName
  location: location
  properties: {
    accountType: storageType
  }
}

resource publicDnsName_resource 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: publicDnsName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: publicDnsName
    }
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
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

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        networkAddressSpace
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
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

resource vmnic_resource 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: vmnic
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'devipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicDnsName_resource.id
          }
          subnet: {
            id: vnetSubNetID
          }
        }
      }
    ]
  }
  dependsOn: [
    publicDnsName_resource
    vnetName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: username
      adminPassword: password
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftSQLServer'
        offer: sqlImageOffer
        sku: sqlImageSku
        version: sqlImageVersion
      }
      osDisk: {
        name: vmosdisk
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmnic_resource.id
        }
      ]
    }
  }
  dependsOn: [
    storageName_resource
    vmnic_resource
  ]
}