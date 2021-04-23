@description('VM admin user name')
param adminUsername string

@description('VM admin password')
@secure()
param adminPassword string

@description('Name of the virtual network')
param vnetName string = 'VNet1'

@description('Address prefix for the virtual network')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Name of the first subnet in the VNet')
param subnet1Name string = 'subnet1'

@description('Address prefix for subnet1')
param subnet1Prefix string = '10.0.1.0/24'

@description('Name of the second subnet in the VNet')
param subnet2Name string = 'subnet2'

@description('Address prefix for subnet2')
param subnet2Prefix string = '10.0.2.0/24'

@description('Size of VM')
param vmSize string = 'Standard_A1'

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Premium_LRS'
])
@description('Geo-replication type of Storage account')
param storageAccountType string = 'Standard_LRS'

@description('Location for all resources.')
param location string = resourceGroup().location

var storageAccountName_var = uniqueString(resourceGroup().id)
var publicIpAddressName_var = 'pip'
var vmName_var = 'testvm'
var subnetId = [
  resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnet1Name)
  resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnet2Name)
]
var networkSecurityGroupName_var = 'default-NSG'

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

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2017-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'subnet1'
        properties: {
          addressPrefix: subnet1Prefix
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
      {
        name: 'subnet2'
        properties: {
          addressPrefix: subnet2Prefix
        }
      }
    ]
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2017-09-01' = [for i in range(0, 2): {
  name: concat(publicIpAddressName_var, i)
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}]

resource nic 'Microsoft.Network/networkInterfaces@2016-10-01' = [for i in range(0, 2): {
  name: 'nic${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId[i]
          }
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', concat(publicIpAddressName_var, i))
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetName_resource
    publicIPAddressName
  ]
}]

resource storageAccountName 'Microsoft.Storage/storageAccounts@2017-06-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {
    networkAcls: {
      bypass: 'None'
      virtualNetworkRules: [
        {
          id: subnetId[0]
          action: 'Allow'
        }
      ]
      defaultAction: 'Deny'
    }
  }
  dependsOn: [
    vnetName_resource
  ]
}

resource as1 'Microsoft.Compute/availabilitySets@2017-03-30' = {
  name: 'as1'
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 2
  }
}

resource vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, 2): {
  name: concat(vmName_var, i)
  location: location
  properties: {
    availabilitySet: {
      id: as1.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(vmName_var, i)
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2016-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'nic${i}')
        }
      ]
    }
  }
  dependsOn: [
    storageAccountName
    nic
    as1
  ]
}]