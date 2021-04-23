@description('Location for the resources.')
param location string = resourceGroup().location

@description('Name for the Virtual Machine.')
param vmName string = 'linux-vm'

@description('User name for the Virtual Machine.')
param adminUsername string

@allowed([
  'password'
  'sshPublicKey'
])
@description('Type of authentication to use on the Virtual Machine.')
param authenticationType string = 'sshPublicKey'

@description('Password or ssh key for the Virtual Machine.')
@secure()
param adminPasswordOrKey string

@description('Size for the Virtual Machine.')
param vmSize string = 'Standard_A2_v2'

@allowed([
  'new'
  'existing'
])
@description('Determines whether or not a new storage account should be provisioned.')
param storageNewOrExisting string = 'new'

@description('Name of the storage account')
param storageAccountName string = 'storage${uniqueString(resourceGroup().id)}'

@description('Storage account type')
param storageAccountType string = 'Standard_LRS'

@description('Name of the resource group for the existing storage account')
param storageAccountResourceGroupName string = resourceGroup().name

@allowed([
  'new'
  'existing'
])
@description('Determines whether or not a new virtual network should be provisioned.')
param virtualNetworkNewOrExisting string = 'new'

@description('Name of the virtual network')
param virtualNetworkName string = 'VirtualNetwork'

@description('Address prefix of the virtual network')
param addressPrefixes array = [
  '10.0.0.0/16'
]

@description('Name of the subnet')
param subnetName string = 'default'

@description('Subnet prefix of the virtual network')
param subnetPrefix string = '10.0.0.0/24'

@description('Name of the resource group for the existing virtual network')
param virtualNetworkResourceGroupName string = resourceGroup().name

@allowed([
  'none'
  'new'
  'existing'
])
@description('Determines whether or not a new public ip should be provisioned.')
param publicIpNewOrExisting string = 'new'

@description('Name of the public ip address')
param publicIpName string = 'PublicIp'

@description('DNS of the public ip address for the VM')
param publicIpDns string = 'linux-vm-${uniqueString(resourceGroup().id)}'

@description('Name of the resource group for the public ip address')
param publicIpResourceGroupName string = resourceGroup().name

@allowed([
  'Dynamic'
  'Static'
  ''
])
@description('Allocation method for the public ip address')
param publicIpAllocationMethod string = 'Dynamic'

@allowed([
  'Basic'
  'Standard'
  ''
])
@description('Name of the resource group for the public ip address')
param publicIpSku string = 'Basic'

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var nicName_var = '${vmName}-nic'
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
var publicIpAddressId = {
  id: resourceId(publicIpResourceGroupName, 'Microsoft.Network/publicIPAddresses', publicIpName)
}
var networkSecurityGroupName_var = 'nsg-ssh'
var fileToBeCopied = 'FileToBeCopied.txt'
var scriptFolder = 'scripts'
var scriptFileName = 'copyfilefromazure.sh'
var scriptArgs = '-a ${uri(artifactsLocation, '.')} -t "${artifactsLocationSasToken}" -p ${scriptFolder} -f ${fileToBeCopied}'

module pid_00000000_0000_0000_0000_000000000000 './nested_pid_00000000_0000_0000_0000_000000000000.bicep' = {
  name: 'pid-00000000-0000-0000-0000-000000000000'
  params: {}
}

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = if (storageNewOrExisting == 'new') {
  name: storageAccountName
  location: location
  kind: 'Storage'
  sku: {
    name: storageAccountType
  }
}

resource publicIpName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = if (publicIpNewOrExisting == 'new') {
  name: publicIpName
  location: location
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: publicIpAllocationMethod
    dnsSettings: {
      domainNameLabel: publicIpDns
    }
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = if (virtualNetworkNewOrExisting == 'new') {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-ssh'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '22'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId(virtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName, subnetName)
          }
          publicIPAddress: ((!(publicIpNewOrExisting == 'none')) ? publicIpAddressId : json('null'))
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroupName.id
    }
  }
  dependsOn: [
    publicIpName_resource
    virtualNetworkName_resource
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
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '16.04-LTS'
        version: 'latest'
      }
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(resourceId(storageAccountResourceGroupName, 'Microsoft.Storage/storageAccounts/', storageAccountName), '2018-02-01').primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    storageAccountName_resource
  ]
}

resource vmName_configScript 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  parent: vmName_resource
  name: 'configScript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'scripts/copyfilefromazure.sh${artifactsLocationSasToken}')
      ]
    }
    protectedSettings: {
      commandToExecute: 'bash ${scriptFileName} ${scriptArgs}'
    }
  }
}

output ssh_command string = ((publicIpNewOrExisting == 'none') ? 'no public ip, vnet access only' : 'ssh ${adminUsername}@${reference(resourceId(publicIpResourceGroupName, 'Microsoft.Network/publicIPAddresses', publicIpName), '2018-04-01').dnsSettings.fqdn}')