@allowed([
  'westeurope'
  'eastus2'
])
@description('Location for the VM, only certain regions support zones during preview.')
param location string = 'westeurope'

@description('user name to ssh to the VMs')
param adminUsername string

@description('password to ssh to the VMs')
@secure()
param adminPassword string

@description('Virtual network name for the cluster')
param virtualNetworkName string = 'pxcvnet'

@description('subnet name for the MySQL nodes')
param dbSubnetName string = 'dbsubnet'

@description('IP address in CIDR for virtual network')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('IP address in CIDR for db subnet')
param dbSubnetAddressPrefix string = '10.0.1.0/24'

@maxLength(3)
@description('IP Addresses for the 3 VMs')
param vmIPs array = [
  '10.0.1.4'
  '10.0.1.5'
  '10.0.1.6'
]

@description('host name prefix for the VMs')
param vmNamePrefix string = 'pxcnd'

@allowed([
  'OpenLogic'
  'Canonical'
])
@description('publisher for the VM OS image')
param imagePublisher string = 'OpenLogic'

@allowed([
  'CentOS'
  'UbuntuServer'
])
@description('VM OS name')
param imageOffer string = 'CentOS'

@allowed([
  '6.5'
  '12.04.5-LTS'
  '14.04.5-LTS'
  '15.10'
  '16.04.0-LTS'
])
@description('VM OS version')
param imageSKU string = '6.5'

@description('bash script command line')
param customScriptCommandToExecute string = 'bash azurepxc.sh'

@allowed([
  'Standard_LRS'
  'Premium_LRS'
])
@description('Storage account type for the data disks')
param storageAccountType string = 'Standard_LRS'

@description('Linked Templates base url')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/mysql-ha-pxc-zones/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var customScriptFilePath = uri(artifactsLocation, 'azurepxc.sh${artifactsLocationSasToken}')
var mysqlConfigFilePath = uri(artifactsLocation, 'my.cnf.template${artifactsLocationSasToken}')
var dbSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName, dbSubnetName)
var publicIpAddressName_var = 'pip'
var pxcClusterAddress = '${vmIPs[0]},${vmIPs[1]},${vmIPs[2]}'
var customScriptCommandCommon = '${customScriptCommandToExecute} ${pxcClusterAddress} '
var customScriptParam = [
  '${vmIPs[0]} bootstrap-pxc ${mysqlConfigFilePath}'
  '${vmIPs[1]} start ${mysqlConfigFilePath}'
  '${vmIPs[1]} start ${mysqlConfigFilePath}'
]

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2017-08-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: dbSubnetName
        properties: {
          addressPrefix: dbSubnetAddressPrefix
        }
      }
    ]
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2017-08-01' = [for i in range(0, 3): {
  name: concat(publicIpAddressName_var, i)
  location: location
  zones: [
    (i + 1)
  ]
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}]

resource nic_1 'Microsoft.Network/networkInterfaces@2017-08-01' = [for i in range(0, 3): {
  name: 'nic-${(i + 1)}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: vmIPs[i]
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', concat(publicIpAddressName_var, i))
          }
          subnet: {
            id: dbSubnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
    publicIPAddressName
  ]
}]

resource disk_1 'Microsoft.Compute/disks@2017-03-30' = [for i in range(0, 6): {
  name: 'disk-${(i + 1)}'
  location: location
  sku: {
    name: storageAccountType
  }
  zones: [
    ((i / 2) + 1)
  ]
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: 64
  }
}]

resource vmNamePrefix_1 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, 3): {
  name: '${vmNamePrefix}-${(i + 1)}'
  location: location
  zones: [
    (i + 1)
  ]
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_A1_v2'
    }
    osProfile: {
      computerName: '${vmNamePrefix}-${(i + 1)}'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      dataDisks: [for j in range(0, 2): {
        lun: j
        createOption: 'Attach'
        managedDisk: {
          id: resourceId('Microsoft.Compute/disks', 'disk-${((i * 2) + (j + 1))}')
        }
      }]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkinterfaces', 'nic-${(i + 1)}')
        }
      ]
    }
  }
  dependsOn: [
    nic_1
  ]
}]

resource vmNamePrefix_1_mySQLConfig 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = [for i in range(0, 3): {
  name: '${vmNamePrefix}-${(i + 1)}/mySQLConfig'
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
      commandToExecute: concat(customScriptCommandCommon, customScriptParam[i])
    }
  }
  dependsOn: [
    '${vmNamePrefix}-${(i + 1)}'
  ]
}]