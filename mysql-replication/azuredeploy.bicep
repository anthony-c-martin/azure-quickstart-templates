@description('Connect to your cluster using dnsName.location.cloudapp.azure.com')
param dnsName string = 'mysql${uniqueString(resourceGroup().id)}'

@description('user name to ssh to the VMs')
param vmUserName string

@description('mysql root user password single quote not allowed')
@secure()
param mysqlRootPassword string

@description('mysql replication user password single quote not allowed')
@secure()
param mysqlReplicationPassword string

@description('mysql probe password single quote not allowed')
@secure()
param mysqlProbePassword string

@description('size for the VMs')
param vmSize string = 'Standard_D2s_v3'

@allowed([
  'Standard_LRS'
  'Premium_LRS'
  'StandardSSD_LRS'
])
@description('Storage account type for the cluster')
param diskType string = 'StandardSSD_LRS'

@description('Virtual network name for the cluster')
param virtualNetworkName string = 'mysqlvnet'

@allowed([
  'new'
  'existing'
])
@description('Identifies whether to use new or existing Virtual Network')
param virtualNetworkNewOrExisting string = 'new'

@description('If using existing VNet, specifies the resource group for the existing VNet')
param virtualNetworkResourceGroupName string = resourceGroup().name

@description('subnet name for the MySQL nodes')
param subnetName string = 'dbsubnet'

@description('IP address in CIDR for virtual network')
param virtualNetworkAddressPrefix string = '10.0.0.0/16'

@description('IP address in CIDR for db subnetq')
param subnetAddressPrefix string = '10.0.1.0/24'

@description('Start IP address in the subnet for the VMs')
param subnetStartAddress string = '10.0.1.4'

@allowed([
  'CentOS 6.10'
  'CentOS 7.8'
  'CentOS 8.2'
  'Ubuntu 14.04.5-LTS'
  'Ubuntu 16.04-LTS'
  'Ubuntu 18.04-LTS'
])
@description('publisher for the VM OS image')
param vmImage string = 'CentOS 8.2'

@description('MySQL public port master')
param mysqlFrontEndPort0 int = 3306

@description('MySQL public port slave')
param mysqlFrontEndPort1 int = 3307

@description('public ssh port for VM1')
param sshNatRuleFrontEndPort0 int = 64001

@description('public ssh port for VM2')
param sshNatRuleFrontEndPort1 int = 64002

@description('MySQL public port master')
param mysqlProbePort0 int = 9200

@description('MySQL public port slave')
param mysqlProbePort1 int = 9201

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var nodeCount = 2
var lbPublicIPName_var = 'mysqlIP01'
var lbPublicIPRef = lbPublicIPName.id
var lbName_var = '${dnsName}-lb'
var ilbBackendAddressPoolName = '${dnsName}-ilbBackendPool'
var ilbBackendAddressPoolID = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName_var, ilbBackendAddressPoolName)
var sshIPConfigName = '${dnsName}-sshIPCfg'
var sshIPConfigId = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName_var, sshIPConfigName)
var nicName_var = '${dnsName}-nic'
var availabilitySetName_var = '${dnsName}-set'
var customScriptFilePath = uri(artifactsLocation, 'azuremysql.sh${artifactsLocationSasToken}')
var mysqlConfigFilePath = uri(artifactsLocation, 'my.cnf.template${artifactsLocationSasToken}')
var sa = subnetStartAddress
var ipOctet01 = '${split(sa, '.')[0]}.${split(sa, '.')[1]}.'
var ipOctet2 = int(split(sa, '.')[2])
var ipOctet3 = int(split(sa, '.')[3])
var vmImageReference = {
  'CentOS 6.10': {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '6.10'
    version: 'latest'
  }
  'CentOS 7.8': {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '7_8'
    version: 'latest'
  }
  'CentOS 8.2': {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '8_2'
    version: 'latest'
  }
  'Ubuntu 14.04.5-LTS': {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '14.04.5-LTS'
    version: 'latest'
  }
  'Ubuntu 16.04-LTS': {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '16.04-LTS'
    version: 'latest'
  }
  'Ubuntu 18.04-LTS': {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '18.04-LTS'
    version: 'latest'
  }
}
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${vmUserName}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-06-01' = if (virtualNetworkNewOrExisting == 'new') {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
        }
      }
    ]
  }
}

resource lbPublicIPName 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: lbPublicIPName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: dnsName
    }
  }
}

resource availabilitySetName 'Microsoft.Compute/availabilitySets@2020-06-01' = {
  location: location
  name: availabilitySetName_var
  properties: {
    platformUpdateDomainCount: 20
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2020-06-01' = [for i in range(0, nodeCount): {
  name: concat(nicName_var, i)
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig${i}'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '${ipOctet01}${(ipOctet2 + ((i + ipOctet3) / 255))}.${((i + ipOctet3) % 255)}'
          subnet: {
            id: resourceId(virtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
          loadBalancerBackendAddressPools: [
            {
              id: ilbBackendAddressPoolID
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', lbName_var, '${dnsName}NatRule${i}')
            }
            {
              id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', lbName_var, '${dnsName}ProbeNatRule${i}')
            }
            {
              id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', lbName_var, '${dnsName}MySQLNatRule${i}')
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
    lbName
  ]
}]

resource dnsName_resource 'Microsoft.Compute/virtualMachines@2020-06-01' = [for i in range(0, nodeCount): {
  name: concat(dnsName, i)
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetName.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(dnsName, i)
      adminUsername: vmUserName
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: vmImageReference[vmImage]
      osDisk: {
        name: '${dnsName}${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: diskType
        }
      }
      dataDisks: [
        {
          name: '${dnsName}${i}_DataDisk1'
          diskSizeGB: 1024
          lun: 0
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: diskType
          }
          createOption: 'Empty'
        }
        {
          name: '${dnsName}${i}_DataDisk2'
          diskSizeGB: 1024
          lun: 1
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: diskType
          }
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(nicName_var, i))
        }
      ]
    }
  }
  dependsOn: [
    availabilitySetName
    resourceId('Microsoft.Network/networkInterfaces', concat(nicName_var, i))
  ]
}]

resource dnsName_setupMySQL 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = [for i in range(0, nodeCount): {
  name: '${dnsName}${i}/setupMySQL'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        customScriptFilePath
      ]
    }
    protectedSettings: {
      commandToExecute: 'bash azuremysql.sh ${(i + 1)} ${ipOctet01}${(ipOctet2 + ((i + ipOctet3) / 255))}.${((i + ipOctet3) % 255)} \'${mysqlConfigFilePath}\' \'${mysqlReplicationPassword}\' \'${mysqlRootPassword}\' \'${mysqlProbePassword}\' ${subnetStartAddress}'
    }
  }
  dependsOn: [
    resourceId('Microsoft.Compute/virtualMachines', concat(dnsName, i))
  ]
}]

resource lbName 'Microsoft.Network/loadBalancers@2020-06-01' = {
  name: lbName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: sshIPConfigName
        properties: {
          publicIPAddress: {
            id: lbPublicIPRef
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: ilbBackendAddressPoolName
      }
    ]
    inboundNatRules: [
      {
        name: '${dnsName}NatRule0'
        properties: {
          frontendIPConfiguration: {
            id: sshIPConfigId
          }
          protocol: 'Tcp'
          frontendPort: sshNatRuleFrontEndPort0
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: '${dnsName}NatRule1'
        properties: {
          frontendIPConfiguration: {
            id: sshIPConfigId
          }
          protocol: 'Tcp'
          frontendPort: sshNatRuleFrontEndPort1
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: '${dnsName}MySQLNatRule0'
        properties: {
          frontendIPConfiguration: {
            id: sshIPConfigId
          }
          protocol: 'Tcp'
          frontendPort: mysqlFrontEndPort0
          backendPort: 3306
          enableFloatingIP: false
        }
      }
      {
        name: '${dnsName}MySQLNatRule1'
        properties: {
          frontendIPConfiguration: {
            id: sshIPConfigId
          }
          protocol: 'Tcp'
          frontendPort: mysqlFrontEndPort1
          backendPort: 3306
          enableFloatingIP: false
        }
      }
      {
        name: '${dnsName}ProbeNatRule0'
        properties: {
          frontendIPConfiguration: {
            id: sshIPConfigId
          }
          protocol: 'Tcp'
          frontendPort: mysqlProbePort0
          backendPort: 9200
          enableFloatingIP: false
        }
      }
      {
        name: '${dnsName}ProbeNatRule1'
        properties: {
          frontendIPConfiguration: {
            id: sshIPConfigId
          }
          protocol: 'Tcp'
          frontendPort: mysqlProbePort1
          backendPort: 9200
          enableFloatingIP: false
        }
      }
    ]
  }
}

output publicIpResourceId string = lbPublicIPName.id
output fqdn string = lbPublicIPName.properties.dnsSettings.fqdn
output ipaddress string = lbPublicIPName.properties.ipAddress