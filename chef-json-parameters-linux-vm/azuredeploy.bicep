@description('DNS name for the VM')
param vmDnsName string

@description('Admin user name for the Virtual Machines')
param adminUsername string

@allowed([
  'Ubuntu-14.04.2-LTS'
  'Ubuntu-12.04.5-LTS'
  'Centos-7.1'
  'Centos-7'
])
@description('The type of the operating system you want to deploy.')
param osType string = 'Ubuntu-14.04.2-LTS'

@description('VM Size')
param vmSize string = 'Standard_A0'

@description('The name for the node (VM) in the Chef Organization')
param chef_node_name string

@description('Organization URL for the Chef Server. Example https://ChefServerDnsName.cloudapp.net/organizations/Orgname')
param chef_server_url string

@description('Validator key name for the organization. Example : MyOrg-validator')
param validation_client_name string

@description('Optional Run List to Execute')
param runlist string = 'recipe[getting-started]'

@description('JSON Escaped Validation Key')
param validation_key string

@allowed([
  'plaintext'
  'base64encoded'
])
@description('Format in which Validation Key is given. e.g. plaintext, base64encoded')
param validation_key_format string = 'plaintext'

@description('Encrypted Data bag secret')
param secret string = 'my_secret_key'

@description('Frequency(in minutes) at which the chef-service runs.')
param chef_service_interval string = '30'

@description('Chef Client Version')
param bootstrap_version string = 'latest'

@description('Release channel for Chef Client Version')
param bootstrap_channel string = 'stable'

@description('Daemon option is only for Windows. Allowed values: none/service/task')
param daemon string = 'service'

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

var images = {
  'Ubuntu-14.04.2-LTS': {
    sku: '14.04.2-LTS'
    offer: 'UbuntuServer'
    publisher: 'Canonical'
  }
  'Ubuntu-12.04.5-LTS': {
    sku: '12.04.5-LTS'
    offer: 'UbuntuServer'
    publisher: 'Canonical'
  }
  'Centos-7.1': {
    sku: '7.1'
    offer: 'CentOS'
    publisher: 'OpenLogic'
  }
  'Centos-7': {
    sku: '7'
    offer: 'CentOS'
    publisher: 'OpenLogic'
  }
}
var vnetID = virtualNetworkName.id
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var vmExtensionName = 'LinuxChefExtension'
var vmName_var = vmDnsName
var storageAccountType = 'Standard_LRS'
var newStorageAccountName_var = '${uniqueString(resourceGroup().id)}cheflinuxvm'
var publicIPAddressName_var = 'myPublicIP1'
var publicIPAddressType = 'Dynamic'
var vmStorageAccountContainerName = 'vhds'
var virtualNetworkName_var = 'MyVNET1'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'subnet-1'
var subnet2Name = 'subnet-2'
var subnet1Prefix = '10.0.0.0/24'
var subnet2Prefix = '10.0.1.0/24'
var nicName_var = 'myVMNic'
var dnsName = subnet1Name
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

resource newStorageAccountName 'Microsoft.Storage/storageAccounts@2015-05-01-preview' = {
  name: newStorageAccountName_var
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: vmDnsName
    }
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
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

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
  name: virtualNetworkName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2Prefix
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: nicName_var
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
            id: subnet1Ref
          }
        }
      }
    ]
  }
}

resource vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: images[osType].publisher
        offer: images[osType].offer
        sku: images[osType].sku
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
          id: nicName.id
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccountName
  ]
}

resource vmName_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  parent: vmName
  name: '${vmExtensionName}'
  location: location
  properties: {
    publisher: 'Chef.Bootstrap.WindowsAzure'
    type: 'LinuxChefClient'
    typeHandlerVersion: '1210.12'
    settings: {
      bootstrap_options: {
        chef_node_name: chef_node_name
        chef_server_url: chef_server_url
        validation_client_name: validation_client_name
      }
      runlist: runlist
      validation_key_format: validation_key_format
      chef_service_interval: chef_service_interval
      bootstrap_version: bootstrap_version
      bootstrap_channel: bootstrap_channel
      daemon: daemon
    }
    protectedSettings: {
      validation_key: validation_key
      secret: secret
    }
  }
}