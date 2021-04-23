@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Premium_LRS'
])
@description('Storage Account type')
param storageAccountType string = 'Standard_LRS'

@minLength(1)
@description('Virtual Machine user name')
param vmAdminUserName string

@description('Virtual Machine password')
@secure()
param vmAdminPassword string

@minLength(1)
@description('Public IP dns name')
param dnsNameForPublicIP string

@description('Location for all resources.')
param location string = resourceGroup().location

var vmName_var = 'zca-vm'
var vnetPrefix = '10.0.0.0/16'
var vnetSubnet1Name = 'Subnet-1'
var vnetSubnet1Prefix = '10.0.0.0/24'
var vnetSubnet2Name = 'Subnet-2'
var vnetSubnet2Prefix = '10.0.1.0/24'
var vmOSDiskName = 'vmOSDisk'
var vmVmSize = 'Standard_DS3_v2'
var vmSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet', vnetSubnet1Name)
var vmStorageAccountContainerName = 'vhds'
var vmNicName_var = '${vmName_var}NetworkInterface'
var pipName_var = 'pip'
var nsgName_var = 'zca-nsg'
var newStorageAccountName_var = 'zerto${uniqueString(resourceGroup().id)}'

module pid_84d2edc4_86bd_439c_8373_e9f04e0f5ad2 './nested_pid_84d2edc4_86bd_439c_8373_e9f04e0f5ad2.bicep' = {
  name: 'pid-84d2edc4-86bd-439c-8373-e9f04e0f5ad2'
  params: {}
}

resource newStorageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: newStorageAccountName_var
  location: location
  sku: {
    name: storageAccountType
  }
  tags: {
    displayName: 'storageAccount'
  }
  kind: 'Storage'
  dependsOn: []
}

resource vnet 'Microsoft.Network/virtualNetworks@2016-03-30' = {
  name: 'vnet'
  location: location
  tags: {
    displayName: 'vnet'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetPrefix
      ]
    }
    subnets: [
      {
        name: vnetSubnet1Name
        properties: {
          addressPrefix: vnetSubnet1Prefix
        }
      }
      {
        name: vnetSubnet2Name
        properties: {
          addressPrefix: vnetSubnet2Prefix
        }
      }
    ]
  }
  dependsOn: []
}

resource vmNicName 'Microsoft.Network/networkInterfaces@2016-03-30' = {
  name: vmNicName_var
  location: location
  tags: {
    displayName: 'vmNic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vmSubnetRef
          }
          publicIPAddress: {
            id: pipName.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgName.id
    }
  }
  dependsOn: [
    vnet
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName_var
  location: location
  tags: {
    displayName: 'vm'
  }
  plan: {
    name: 'zerto60ga'
    publisher: 'zerto'
    product: 'zerto-cloud-appliance-50'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmVmSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: vmAdminUserName
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'zerto'
        offer: 'zerto-cloud-appliance-50'
        sku: 'zerto60ga'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNicName.id
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccountName
  ]
}

resource pipName 'Microsoft.Network/publicIPAddresses@2016-03-30' = {
  name: pipName_var
  location: location
  tags: {
    displayName: 'pip'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
  }
  dependsOn: []
}

resource nsgName 'Microsoft.Network/networkSecurityGroups@2017-06-01' = {
  name: nsgName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowRDP'
        etag: 'W/"ec1cdead-18a3-4ae4-b0fa-1d58260ead30"'
        properties: {
          provisioningState: 'Succeeded'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}