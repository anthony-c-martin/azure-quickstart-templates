@allowed([
  'Ubuntu'
])
@description('OS to install on the host system (Centos was removed due to breaking change)')
param hostOs string = 'Ubuntu'

@allowed([
  2
  4
  6
  8
])
@description('Number of nodes in the gluster file system')
param scaleNumber int = 2

@description('ssh user name')
param adminUsername string

@description('VM size for the nodes')
param vmSize string = 'Standard_A2_v2'

@allowed([
  32
  64
  128
  256
  512
  1024
  2048
  4095
])
@description('The size of the datadisks to be striped. The total capacity will be this size multiplied by the number of data disks you specify.')
param diskSize int = 1024

@description('VM name prefix, a number will be appended for each node')
param vmNamePrefix string = 'gluster'

@description('Virtual network name for the cluster')
param virtualNetworkName string = 'gluster-vnet'

@allowed([
  'new'
  'existing'
])
@description('Identifies whether to use new or existing Virtual Network')
param virtualNetworkNewOrExisting string = 'new'

@description('If using existing VNet, specifies the resource group for the existing VNet')
param virtualNetworkResourceGroupName string = resourceGroup().name

@description('subnet name')
param subnetName string = 'gluster-subnet'

@description('IP address in CIDR for virtual network')
param virtualNetworkAddressPrefix string = '10.0.0.0/16'

@description('IP address in CIDR for subnet')
param subnetAddressPrefix string = '10.0.1.0/24'

@description('Gluster file system volume name')
param volumeName string = 'gfsvol'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/gluster-file-system/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var pipName_var = 'pip'
var nicName_var = 'nic'
var gfsSubnetRef = resourceId(virtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var vmIPPrefix = '${substring(subnetAddressPrefix, 0, lastIndexOf(subnetAddressPrefix, '.'))}.10'
var imageReference = {
  Ubuntu: {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '14.04.5-LTS'
    version: 'latest'
  }
  CentOS: {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '7.5'
    version: 'latest'
  }
}
var customScriptFilePath = uri(artifactsLocation, 'azuregfs.sh${artifactsLocationSasToken}')
var customScriptCommandToExecute = 'bash azuregfs.sh'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}
var networkSecurityGroupName_var = 'default-NSG'

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2020-06-01' = if (virtualNetworkNewOrExisting == 'new') {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-22'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
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
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource pipName 'Microsoft.Network/publicIPAddresses@2020-06-01' = [for i in range(0, scaleNumber): {
  name: concat(pipName_var, i)
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}]

resource nicName 'Microsoft.Network/networkInterfaces@2020-06-01' = [for i in range(0, scaleNumber): {
  name: concat(nicName_var, i)
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', concat(pipName_var, i))
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: concat(vmIPPrefix, i)
          subnet: {
            id: gfsSubnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
    pipName
  ]
}]

resource vmNamePrefix_resource 'Microsoft.Compute/virtualMachines@2020-06-01' = [for i in range(0, scaleNumber): {
  name: concat(vmNamePrefix, i)
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(vmNamePrefix, i)
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: imageReference[hostOs]
      osDisk: {
        name: '${vmNamePrefix}${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      dataDisks: [
        {
          name: '${vmNamePrefix}${i}_DataDisk1'
          diskSizeGB: diskSize
          lun: 0
          createOption: 'Empty'
        }
        {
          name: '${vmNamePrefix}${i}_DataDisk2'
          diskSizeGB: diskSize
          lun: 1
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
    nicName
  ]
}]

resource vmNamePrefix_gfs_config 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = [for i in range(0, scaleNumber): {
  name: '${vmNamePrefix}${i}/gfs-config'
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
      commandToExecute: '${customScriptCommandToExecute} ${vmNamePrefix} ${vmIPPrefix} ${volumeName} ${i} ${scaleNumber}'
    }
  }
  dependsOn: [
    resourceId('Microsoft.Compute/virtualMachines', concat(vmNamePrefix, i))
  ]
}]