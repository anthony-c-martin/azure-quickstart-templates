param projectName string {
  maxLength: 8
  metadata: {
    description: 'Specifies a name for generating resource names.'
  }
}
param location string {
  metadata: {
    description: 'Specifies the location for all resources.'
  }
  default: resourceGroup().location
}
param adminUsername string {
  metadata: {
    description: 'Specifies the administrator username for the Virtual Machine.'
  }
}
param adminPassword string {
  metadata: {
    description: 'Specifies the administrator password for the Virtual Machine.'
  }
  secure: true
}
param dnsLabelPrefix string {
  metadata: {
    description: 'Specifies the unique DNS Name for the Public IP used to access the Virtual Machine.'
  }
}
param vmSize string {
  metadata: {
    description: 'Virtual machine size.'
  }
  default: 'Standard_A2'
}
param windowsOSVersion string {
  allowed: [
    '2008-R2-SP1'
    '2012-Datacenter'
    '2012-R2-Datacenter'
    '2016-Nano-Server'
    '2016-Datacenter-with-Containers'
    '2016-Datacenter'
  ]
  metadata: {
    description: 'Specifies the Windows version for the VM. This will pick a fully patched image of this given Windows version. Allowed values: 2008-R2-SP1, 2012-Datacenter, 2012-R2-Datacenter, 2016-Nano-Server, 2016-Datacenter-with-Containers, 2016-Datacenter.'
  }
  default: '2016-Datacenter'
}

var storageAccountName = '${projectName}store'
var networkInterfaceName = '${projectName}-nic'
var vNetAddressPrefix = '10.0.0.0/16'
var vNetSubnetName = 'default'
var vNetSubnetAddressPrefix = '10.0.0.0/24'
var publicIPAddressName = '${projectName}-ip'
var vmName = '${projectName}-vm'
var vNetName = '${projectName}-vnet'
var vaultName = '${projectName}-vault'
var backupFabric = 'Azure'
var backupPolicyName = 'DefaultPolicy'
var protectionContainer = 'iaasvmcontainer;iaasvmcontainerv2;${resourceGroup().name};${vmName}'
var protectedItem = 'vm;iaasvmcontainerv2;${resourceGroup().name};${vmName}'
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

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
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
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vNetName_resource 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNetAddressPrefix
      ]
    }
    subnets: [
      {
        name: vNetSubnetName
        properties: {
          addressPrefix: vNetSubnetAddressPrefix
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

resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: networkInterfaceName
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
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNetName, vNetSubnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
    vNetName_resource
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
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
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
          id: networkInterfaceName_resource.id
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
    networkInterfaceName_resource
  ]
}

resource vaultName_resource 'Microsoft.RecoveryServices/vaults@2020-02-02' = {
  name: vaultName
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {}
}

resource vaultName_backupFabric_protectionContainer_protectedItem 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2020-02-02' = {
  name: '${vaultName}/${backupFabric}/${protectionContainer}/${protectedItem}'
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: resourceId('Microsoft.RecoveryServices/vaults/backupPolicies', vaultName, backupPolicyName)
    sourceResourceId: vmName_resource.id
  }
  dependsOn: [
    vmName_resource
    vaultName_resource
  ]
}