@allowed([
  'Ubuntu 20.04-LTS'
  'Ubuntu 18.04-LTS'
  'Debian 10'
  'Debian 9'
  'CentOS 8.1'
])
@description('The Linux distribution for the VM. This will pick a fully patched image of the selected distribution.')
param OS string = 'Ubuntu 20.04-LTS'

@allowed([
  'Azul_Zulu_OpenJDK-7-JDK'
  'Azul_Zulu_OpenJDK-7-JRE'
  'Azul_Zulu_OpenJDK-7-JRE-Headless'
  'Azul_Zulu_OpenJDK-8-JDK'
  'Azul_Zulu_OpenJDK-8-JRE'
  'Azul_Zulu_OpenJDK-8-JRE-Headless'
  'Azul_Zulu_OpenJDK-11-JDK'
  'Azul_Zulu_OpenJDK-11-JRE'
  'Azul_Zulu_OpenJDK-11-JRE-Headless'
  'Azul_Zulu_OpenJDK-13-JDK'
  'Azul_Zulu_OpenJDK-13-JRE'
  'Azul_Zulu_OpenJDK-13-JRE-Headless'
])
@description('Azul Zulu OpenJDK JVM for Azure package name')
param javaPackageName string = 'Azul_Zulu_OpenJDK-8-JDK'

@description('Size for the Virtual Machine.')
param vmSize string = 'Standard_D2s_v3'

@description('Name for the Virtual Machine.')
param vmName string = 'linux-zulu'

@description('User name for the Virtual Machine.')
param adminUsername string

@allowed([
  'password'
  'sshPublicKey'
])
@description('Type of authentication to use on the Virtual Machine.')
param authenticationType string = 'sshPublicKey'

@description('Password or SSH key for the Virtual Machine.')
@secure()
param adminPasswordOrKey string

@description('Determines whether or not a new storage account should be provisioned.')
param storageNewOrExisting string = 'new'

@description('Name of the storage account')
param storageAccountName string = 'storage${uniqueString(resourceGroup().id)}'

@allowed([
  'Standard_LRS'
])
@description('Storage account type')
param storageAccountType string = 'Standard_LRS'

@description('Name of the resource group for the existing storage account')
param storageAccountResourceGroupName string = resourceGroup().name

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
])
@description('Allocation method for the public ip address')
param publicIpAllocationMethod string = 'Dynamic'

@allowed([
  'Basic'
  'Standard'
])
@description('Name of the resource group for the public ip address')
param publicIpSku string = 'Basic'

@description('Location for the resources.')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var imageReference = {
  'Ubuntu 20.04-LTS': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-focal'
    sku: '20_04-lts'
    version: 'latest'
  }
  'Ubuntu 18.04-LTS': {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '18.04-LTS'
    version: 'latest'
  }
  'Debian 10': {
    publisher: 'Debian'
    offer: 'debian-10'
    sku: '10'
    version: 'latest'
  }
  'Debian 9': {
    publisher: 'credativ'
    offer: 'Debian'
    sku: '9'
    version: 'latest'
  }
  'CentOS 8.1': {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '8_1'
    version: 'latest'
  }
}
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
var networkSecurityGroupName_var = '${vmName}-nsg'
var nicName_var = '${vmName}-nic'
var publicIpAddressId = {
  id: resourceId(publicIpResourceGroupName, 'Microsoft.Network/publicIPAddresses', publicIpName)
}
var scriptFile = {
  'Ubuntu 20.04-LTS': {
    scriptFileName: 'apt-zulu-install.sh'
  }
  'Ubuntu 18.04-LTS': {
    scriptFileName: 'apt-zulu-install.sh'
  }
  'Debian 9': {
    scriptFileName: 'apt-zulu-install.sh'
  }
  'Debian 10': {
    scriptFileName: 'apt-zulu-install.sh'
  }
  'CentOS 8.1': {
    scriptFileName: 'yum-zulu-install.sh'
  }
}

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = if (storageNewOrExisting == 'new') {
  name: storageAccountName
  location: location
  kind: 'Storage'
  sku: {
    name: storageAccountType
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-11-01' = if (virtualNetworkNewOrExisting == 'new') {
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
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource publicIpName_resource 'Microsoft.Network/publicIPAddresses@2019-11-01' = if (publicIpNewOrExisting == 'new') {
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

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowSSH'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2019-11-01' = {
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

resource vmName_resource 'Microsoft.Compute/virtualMachines@2019-12-01' = {
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
      imageReference: imageReference[OS]
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
        storageUri: reference(resourceId(storageAccountResourceGroupName, 'Microsoft.Storage/storageAccounts/', storageAccountName), '2019-06-01').primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    storageAccountName_resource
  ]
}

resource vmName_installScript 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  parent: vmName_resource
  name: 'installScript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'scripts/${scriptFile[OS].scriptFileName}${artifactsLocationSasToken}')
      ]
      commandToExecute: 'bash ${scriptFile[OS].scriptFileName} ${javaPackageName}'
    }
  }
}

output ssh_command string = ((publicIpNewOrExisting == 'none') ? 'no public ip' : 'ssh ${adminUsername}@${reference(resourceId(publicIpResourceGroupName, 'Microsoft.Network/publicIPAddresses', publicIpName), '2019-11-01').dnsSettings.fqdn}')