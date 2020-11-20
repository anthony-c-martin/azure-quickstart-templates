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

var storageAccountName_var = '${projectName}store'
var networkInterfaceName_var = '${projectName}-nic'
var vNetAddressPrefix = '10.0.0.0/16'
var vNetSubnetName = 'default'
var vNetSubnetAddressPrefix = '10.0.0.0/24'
var publicIPAddressName_var = '${projectName}-ip'
var vmName_var = '${projectName}-vm'
var vNetName_var = '${projectName}-vnet'
var vaultName_var = '${projectName}-vault'
var backupFabric = 'Azure'
var backupPolicyName = 'DefaultPolicy'
var protectionContainer = 'iaasvmcontainer;iaasvmcontainerv2;${resourceGroup().name};${vmName_var}'
var protectedItem = 'vm;iaasvmcontainerv2;${resourceGroup().name};${vmName_var}'
var networkSecurityGroupName_var = 'default-NSG'

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
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

resource vNetName 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vNetName_var
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
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource networkInterfaceName 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: networkInterfaceName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNetName_var, vNetSubnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    vNetName
  ]
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
          id: networkInterfaceName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccountName.properties.primaryEndpoints.blob
      }
    }
  }
}

resource vaultName 'Microsoft.RecoveryServices/vaults@2020-02-02' = {
  name: vaultName_var
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {}
}

resource vaultName_backupFabric_protectionContainer_protectedItem 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2020-02-02' = {
  name: '${vaultName_var}/${backupFabric}/${protectionContainer}/${protectedItem}'
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: resourceId('Microsoft.RecoveryServices/vaults/backupPolicies', vaultName_var, backupPolicyName)
    sourceResourceId: vmName.id
  }
  dependsOn: [
    vaultName
  ]
}