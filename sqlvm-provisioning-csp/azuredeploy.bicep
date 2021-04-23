@description('SQL IaaS VM machine name')
param vmName string

@description('SQL IaaS VM size. Use Azure VM size name from MSDN')
param vmSize string

@allowed([
  'sql2019-ws2019'
  'sql2019-ws2016'
])
@description('SQL Server Gallery Image Offer')
param sqlImageOffer string = 'sql2019-ws2019'

@allowed([
  'Enterprise'
  'Standard'
  'Web'
])
@description('SQL Server Gallery Image SKU')
param sqlImageSku string = 'Enterprise'

@description('SQL Server Gallery Image Published Version')
param sqlImageVersion string = 'latest'

@description('SQL IaaS VM local administrator username')
param username string

@description('SQL IaaS VM local administrator password')
@secure()
param password string

@description('SQL IaaS VM data and OS disks storage service')
param storageName string

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
])
@description('SQL IaaS VM data and OS disks storage type')
param storageType string = 'Standard_LRS'

@description('SQL IaaS VM virtual network name')
param vnetName string

@description('SQL IaaS VM virtual network IPv4 address space')
param networkAddressSpace string = '10.10.0.0/26'

@description('SQL IaaS VM virtual network subnet name')
param subnetName string

@description('SQL IaaS VM virtual network subnet IPv4 address prefix')
param subnetAddressPrefix string = '10.10.0.0/28'

@description('DNS name for the VM')
param publicDnsName string

@description('Location for all resources.')
param location string = resourceGroup().location

var vmnic_var = '${vmName}devnic'
var vmosdisk = '${vmName}osdisk'
var vnetSubNetID = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
var networkSecurityGroupName_var = '${subnetName}-nsg'

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
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource vmnic 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: vmnic_var
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
          id: vmnic.id
        }
      ]
    }
  }
  dependsOn: [
    storageName_resource
  ]
}