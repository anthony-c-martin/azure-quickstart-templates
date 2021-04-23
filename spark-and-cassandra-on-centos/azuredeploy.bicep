@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Premium_LRS'
])
@description('Storage type that is used for master Spark node.  This storage account is used to store VM disks.')
param storageMasterType string = 'Standard_LRS'

@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Premium_LRS'
])
@description('Storage type that is used for each of the slave Spark node.  This storage account is used to store VM disks.')
param storageSlaveType string = 'Standard_LRS'

@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Premium_LRS'
])
@description('Storage type that is used for Cassandra.  This storage account is used to store VM disks.')
param storageCassandraType string = 'Standard_LRS'

@allowed([
  'Standard_D1_v2'
  'Standard_D2_v2'
  'Standard_D3_v2'
  'Standard_D4_v2'
  'Standard_D5_v2'
  'Standard_D11_v2'
  'Standard_D12_v2'
  'Standard_D13_v2'
  'Standard_D14_v2'
  'Standard_A8'
  'Standard_A9'
  'Standard_A10'
  'Standard_A11'
])
@description('VM size for master Spark node.  This VM can be sized smaller.')
param vmMasterVMSize string = 'Standard_D1_v2'

@minValue(2)
@maxValue(200)
@description('Number of VMs to create to support the slaves.  Each slave is created on it\'s own VM.  Minimum of 2 & Maximum of 200 VMs.')
param vmNumberOfSlaves int

@allowed([
  'Standard_D1_v2'
  'Standard_D2_v2'
  'Standard_D3_v2'
  'Standard_D4_v2'
  'Standard_D5_v2'
  'Standard_D11_v2'
  'Standard_D12_v2'
  'Standard_D13_v2'
  'Standard_D14_v2'
  'Standard_A8'
  'Standard_A9'
  'Standard_A10'
  'Standard_A11'
])
@description('VM size for slave Spark nodes.  This VM should be sized based on workloads.')
param vmSlaveVMSize string = 'Standard_D3_v2'

@allowed([
  'Standard_D1_v2'
  'Standard_D2_v2'
  'Standard_D3_v2'
  'Standard_D4_v2'
  'Standard_D5_v2'
  'Standard_D11_v2'
  'Standard_D12_v2'
  'Standard_D13_v2'
  'Standard_D14_v2'
  'Standard_A8'
  'Standard_A9'
  'Standard_A10'
  'Standard_A11'
])
@description('VM size for Cassandra node.  This VM should be sized based on workloads.')
param vmCassandraVMSize string = 'Standard_D3_v2'

@minLength(1)
@description('Specific an admin username that should be used to login to the VM.')
param vmAdminUserName string

@description('Specific an admin password that should be used to login to the VM.')
@secure()
param vmAdminPassword string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/spark-and-cassandra-on-centos/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var osImagePublisher = 'OpenLogic'
var osImageOffer = 'CentOS'
var osVersion = '7.1'
var apiVersion = '2015-06-15'
var vnetSparkPrefix = '10.0.0.0/16'
var vnetSparkSubnet1Name = 'Subnet-Master'
var vnetSparkSubnet1Prefix = '10.0.0.0/24'
var vnetSparkSubnet2Name = 'Subnet-Slave'
var vnetSparkSubnet2Prefix = '10.0.1.0/24'
var vnetSparkSubnet3Name = 'Subnet-Cassandra'
var vnetSparkSubnet3Prefix = '10.0.2.0/24'
var storageMasterName_var = 'master${uniqueString(resourceGroup().id)}'
var storageSlaveNamePrefix_var = 'slave${uniqueString(resourceGroup().id)}'
var storageCassandraName_var = 'cass${uniqueString(resourceGroup().id)}'
var nsgSparkMasterName_var = 'nsg-spark-master'
var nsgSparkSlaveName_var = 'nsg-spark-slave'
var nsgCassandraName_var = 'nsg-cassandra'
var nicMasterName_var = 'nic-master'
var nicMasterSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-spark', vnetSparkSubnet1Name)
var nicMasterNodeIP = '10.0.0.5'
var nicCassandraName_var = 'nic-cassandra'
var nicCassandraSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-spark', vnetSparkSubnet3Name)
var nicCassandraNodeIP = '10.0.2.5'
var nicSlaveNamePrefix_var = 'nic-slave-'
var nicSlaveNodeIPPrefix = '10.0.1.'
var nicSlaveNodeIPStart = 5
var nicSlaveSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-spark', vnetSparkSubnet2Name)
var publicIPMasterName_var = 'public-ip-master'
var publicIPSlaveNamePrefix_var = 'public-ip-slave-'
var publicIPCassandraName_var = 'public-ip-cassandra'
var vmMasterName_var = 'spark-master'
var vmMasterOSDiskName = 'vmMasterOSDisk'
var vmMasterStorageAccountContainerName = 'vhds'
var vmSlaveNamePrefix_var = 'spark-slave-'
var vmSlaveOSDiskNamePrefix = 'vmSlaveOSDisk-'
var vmSlaveStorageAccountContainerName = 'vhds'
var vmCassandraName_var = 'cassandra'
var vmCassandraOSDiskName = 'vmCassandraOSDisk'
var vmCassandraStorageAccountContainerName = 'vhds'
var availabilitySlaveName_var = 'availability-slave'
var scriptSparkProvisionerScriptFileName = 'scriptSparkProvisioner.sh'
var scriptCassandraProvisionerScriptFileName = 'scriptCassandraProvisioner.sh'

resource storageMasterName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageMasterName_var
  location: location
  tags: {
    displayName: 'storageMaster'
  }
  properties: {
    accountType: storageMasterType
  }
  dependsOn: []
}

resource storageSlaveNamePrefix 'Microsoft.Storage/storageAccounts@2015-06-15' = [for i in range(0, vmNumberOfSlaves): {
  name: concat(storageSlaveNamePrefix_var, i)
  location: location
  tags: {
    displayName: 'storageSlave'
  }
  properties: {
    accountType: storageSlaveType
  }
  dependsOn: []
}]

resource storageCassandraName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageCassandraName_var
  location: location
  tags: {
    displayName: 'storageCassandra'
  }
  properties: {
    accountType: storageMasterType
  }
  dependsOn: []
}

resource vnet_spark 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: 'vnet-spark'
  location: location
  tags: {
    displayName: 'vnetSpark'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetSparkPrefix
      ]
    }
    subnets: [
      {
        name: vnetSparkSubnet1Name
        properties: {
          addressPrefix: vnetSparkSubnet1Prefix
        }
      }
      {
        name: vnetSparkSubnet2Name
        properties: {
          addressPrefix: vnetSparkSubnet2Prefix
        }
      }
      {
        name: vnetSparkSubnet3Name
        properties: {
          addressPrefix: vnetSparkSubnet3Prefix
        }
      }
    ]
  }
  dependsOn: []
}

resource publicIPMasterName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPMasterName_var
  location: location
  tags: {
    displayName: 'publicIPMaster'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  dependsOn: []
}

resource publicIPSlaveNamePrefix 'Microsoft.Network/publicIPAddresses@2015-06-15' = [for i in range(0, vmNumberOfSlaves): {
  location: location
  name: concat(publicIPSlaveNamePrefix_var, i)
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: {
    displayName: 'publicIPSlave'
  }
  dependsOn: []
}]

resource publicIPCassandraName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPCassandraName_var
  location: location
  tags: {
    displayName: 'publicIPCassandra'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  dependsOn: []
}

resource nsgSparkMasterName 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: nsgSparkMasterName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'ssh'
        properties: {
          description: 'Allow SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'http_webui_spark'
        properties: {
          description: 'Allow Web UI Access to Spark'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
      {
        name: 'http_rest_spark'
        properties: {
          description: 'Allow REST API Access to Spark'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '6066'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 102
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource nsgSparkSlaveName 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: nsgSparkSlaveName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'ssh'
        properties: {
          description: 'Allow SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
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

resource nsgCassandraName 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: nsgCassandraName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'ssh'
        properties: {
          description: 'Allow SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
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

resource nicMasterName 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicMasterName_var
  location: location
  tags: {
    displayName: 'nicMaster'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: nicMasterNodeIP
          subnet: {
            id: nicMasterSubnetRef
          }
          publicIPAddress: {
            id: publicIPMasterName.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgSparkMasterName.id
    }
  }
  dependsOn: [
    vnet_spark
  ]
}

resource nicSlaveNamePrefix 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, vmNumberOfSlaves): {
  name: concat(nicSlaveNamePrefix_var, i)
  location: location
  tags: {
    displayName: 'nicSlave'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: concat(nicSlaveNodeIPPrefix, (nicSlaveNodeIPStart + i))
          subnet: {
            id: nicSlaveSubnetRef
          }
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', concat(publicIPSlaveNamePrefix_var, i))
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgSparkSlaveName.id
    }
  }
  dependsOn: [
    vnet_spark
    nsgSparkSlaveName
    'Microsoft.Network/publicIPAddresses/${publicIPSlaveNamePrefix_var}${i}'
  ]
}]

resource nicCassandraName 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicCassandraName_var
  location: location
  tags: {
    displayName: 'nicCassandra'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: nicCassandraNodeIP
          subnet: {
            id: nicCassandraSubnetRef
          }
          publicIPAddress: {
            id: publicIPCassandraName.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgCassandraName.id
    }
  }
  dependsOn: [
    vnet_spark
  ]
}

resource availabilitySlaveName 'Microsoft.Compute/availabilitySets@2017-12-01' = {
  name: availabilitySlaveName_var
  location: location
  tags: {
    displayName: 'availability-set'
  }
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
  dependsOn: []
}

resource vmMasterName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmMasterName_var
  location: location
  tags: {
    displayName: 'vmMaster'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmMasterVMSize
    }
    osProfile: {
      computerName: vmMasterName_var
      adminUsername: vmAdminUserName
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: osImagePublisher
        offer: osImageOffer
        sku: osVersion
        version: 'latest'
      }
      osDisk: {
        name: '${vmMasterName_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicMasterName.id
        }
      ]
    }
  }
  dependsOn: [
    storageMasterName
  ]
}

resource vmMasterName_scriptMasterSparkProvisioner 'Microsoft.Compute/virtualMachines/extensions@[variables(\'apiVersion\')]' = {
  name: '${vmMasterName_var}/scriptMasterSparkProvisioner'
  location: location
  tags: {
    displayName: 'scriptMasterSparkProvisioner'
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'CustomScripts/${scriptSparkProvisionerScriptFileName}${artifactsLocationSasToken}')
      ]
      commandToExecute: 'sh ${scriptSparkProvisionerScriptFileName} -runas=master -master=${nicMasterNodeIP}'
    }
  }
  dependsOn: [
    vmMasterName
  ]
}

resource vmSlaveNamePrefix 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, vmNumberOfSlaves): {
  name: concat(vmSlaveNamePrefix_var, i)
  location: location
  tags: {
    displayName: 'vmSlave'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSlaveVMSize
    }
    osProfile: {
      computerName: concat(vmSlaveNamePrefix_var, i)
      adminUsername: vmAdminUserName
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: osImagePublisher
        offer: osImageOffer
        sku: osVersion
        version: 'latest'
      }
      osDisk: {
        name: '${vmSlaveNamePrefix_var}${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces/', concat(nicSlaveNamePrefix_var, i))
        }
      ]
    }
    availabilitySet: {
      id: availabilitySlaveName.id
    }
  }
  dependsOn: [
    concat(storageSlaveNamePrefix_var, i)
    'Microsoft.Network/networkInterfaces/${nicSlaveNamePrefix_var}${i}'
  ]
}]

resource vmSlaveNamePrefix_scriptSlaveProvisionerScript 'Microsoft.Compute/virtualMachines/extensions@[variables(\'apiVersion\')]' = [for i in range(0, vmNumberOfSlaves): {
  name: '${vmSlaveNamePrefix_var}${i}/scriptSlaveProvisionerScript'
  location: location
  tags: {
    displayName: 'scriptSlaveProvisionerScript'
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'CustomScripts/${scriptSparkProvisionerScriptFileName}${artifactsLocationSasToken}')
      ]
      commandToExecute: 'sh ${scriptSparkProvisionerScriptFileName} -runas=slave -master=${nicMasterNodeIP}'
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${vmSlaveNamePrefix_var}${i}'
  ]
}]

resource vmCassandraName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmCassandraName_var
  location: location
  tags: {
    displayName: 'vmCassandra'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmCassandraVMSize
    }
    osProfile: {
      computerName: vmCassandraName_var
      adminUsername: vmAdminUserName
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: osImagePublisher
        offer: osImageOffer
        sku: osVersion
        version: 'latest'
      }
      osDisk: {
        name: '${vmCassandraName_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicCassandraName.id
        }
      ]
    }
  }
  dependsOn: [
    storageCassandraName
  ]
}

resource vmCassandraName_scriptCassandraProvisioner 'Microsoft.Compute/virtualMachines/extensions@[variables(\'apiVersion\')]' = {
  name: '${vmCassandraName_var}/scriptCassandraProvisioner'
  location: location
  tags: {
    displayName: 'scriptCassandraProvisioner'
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'CustomScripts/${scriptCassandraProvisionerScriptFileName}${artifactsLocationSasToken}')
      ]
      commandToExecute: 'sh ${scriptCassandraProvisionerScriptFileName}'
    }
  }
  dependsOn: [
    vmCassandraName
  ]
}

output SparkMasterHostInternal string = 'spark://${nicMasterNodeIP}:7077'