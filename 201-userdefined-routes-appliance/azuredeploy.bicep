@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@secure()
param adminPassword string

@description('Unique DNS Prefix for the Public IP used to access the Virtual Machine.')
param uniqueDnsPrefixForVM string

@description('VM Name Prefix for the Virtual Machine.')
param vmNamePrefix string = 'Dynamic'

@allowed([
  'Dynamic'
  'Static'
])
@description('Type of public IP address')
param publicIPAddressType string = 'Dynamic'

@allowed([
  '2008-R2-SP1'
  '2012-Datacenter'
  '2012-R2-Datacenter'
])
@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version. Allowed values: 2008-R2-SP1, 2012-Datacenter, 2012-R2-Datacenter.')
param windowsOSVersion string = '2012-R2-Datacenter'

@description('Location for all resources.')
param location string = resourceGroup().location

var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var vmSize = 'Standard_A2'
var VNetName_var = 'Contoso_Network'
var Subnet1Name = 'FrontendSubnet'
var Subnet2Name = 'NVASubnet'
var Subnet3Name = 'BackendSubnet'
var vnetID = VNetName.id
var subnet1Ref = '${vnetID}/subnets/${Subnet1Name}'
var subnet2Ref = '${vnetID}/subnets/${Subnet2Name}'
var subnet3Ref = '${vnetID}/subnets/${Subnet3Name}'
var VNetAddressPrefix = '10.1.0.0/16'
var Subnet1Prefix = '10.1.0.0/24'
var Subnet2Prefix = '10.1.1.0/24'
var Subnet3Prefix = '10.1.2.0/24'
var routeTableName_var = 'BasicNVA'
var NvmPrivateIPAddress = '10.1.1.4'
var nsgname = 'DefaultNSG'
var scaleNumber = 3
var apiVer = '2015-06-15'

resource uniqueDnsPrefixForVM_resource 'Microsoft.Network/publicIPAddresses@2015-06-15' = [for i in range(0, scaleNumber): {
  name: concat(uniqueDnsPrefixForVM, i)
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: concat(uniqueDnsPrefixForVM, i)
    }
  }
}]

resource DefaultNSG 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: 'DefaultNSG'
  location: location
  properties: {
    securityRules: [
      {
        name: 'rdp_rule'
        properties: {
          description: 'Allow RDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource routeTableName 'Microsoft.Network/routeTables@2015-06-15' = {
  name: routeTableName_var
  location: location
  properties: {
    routes: [
      {
        name: 'VirtualApplianceRouteToSubnet3'
        properties: {
          addressPrefix: Subnet3Prefix
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: NvmPrivateIPAddress
        }
      }
    ]
  }
}

resource VNetName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: VNetName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        VNetAddressPrefix
      ]
    }
    subnets: [
      {
        name: Subnet1Name
        properties: {
          addressPrefix: Subnet1Prefix
          networkSecurityGroup: {
            id: resourceId('Microsoft.Network/networkSecurityGroups', nsgname)
          }
          routeTable: {
            id: routeTableName.id
          }
        }
      }
      {
        name: Subnet2Name
        properties: {
          addressPrefix: Subnet2Prefix
          networkSecurityGroup: {
            id: resourceId('Microsoft.Network/networkSecurityGroups', nsgname)
          }
        }
      }
      {
        name: Subnet3Name
        properties: {
          addressPrefix: Subnet3Prefix
          networkSecurityGroup: {
            id: resourceId('Microsoft.Network/networkSecurityGroups', nsgname)
          }
        }
      }
    ]
  }
  dependsOn: [
    'Microsoft.Network/networkSecurityGroups/${nsgname}'
  ]
}

resource Nic0 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: 'Nic0'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', '${uniqueDnsPrefixForVM}0')
          }
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
  dependsOn: [
    'Microsoft.Network/publicIPAddresses/${uniqueDnsPrefixForVM}0'
  ]
}

resource Nic1 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: 'Nic1'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: NvmPrivateIPAddress
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', '${uniqueDnsPrefixForVM}1')
          }
          subnet: {
            id: subnet2Ref
          }
        }
      }
    ]
    enableIPForwarding: true
  }
  dependsOn: [
    'Microsoft.Network/publicIPAddresses/${uniqueDnsPrefixForVM}1'
  ]
}

resource Nic2 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: 'Nic2'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', '${uniqueDnsPrefixForVM}2')
          }
          subnet: {
            id: subnet3Ref
          }
        }
      }
    ]
  }
  dependsOn: [
    'Microsoft.Network/publicIPAddresses/${uniqueDnsPrefixForVM}2'
  ]
}

resource vmNamePrefix_resource 'Microsoft.Compute/virtualMachines@2016-04-30-preview' = [for i in range(0, scaleNumber): {
  name: concat(vmNamePrefix, i)
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(vmNamePrefix, i)
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
          id: resourceId('Microsoft.Network/networkInterfaces', 'Nic${i}')
        }
      ]
    }
  }
  dependsOn: [
    Nic0
    Nic1
    Nic2
  ]
}]