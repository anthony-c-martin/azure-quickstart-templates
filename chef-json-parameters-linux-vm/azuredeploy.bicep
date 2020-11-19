param vmDnsName string {
  metadata: {
    description: 'DNS name for the VM'
  }
}
param adminUsername string {
  metadata: {
    description: 'Admin user name for the Virtual Machines'
  }
}
param osType string {
  allowed: [
    'Ubuntu-14.04.2-LTS'
    'Ubuntu-12.04.5-LTS'
    'Centos-7.1'
    'Centos-7'
  ]
  metadata: {
    description: 'The type of the operating system you want to deploy.'
  }
  default: 'Ubuntu-14.04.2-LTS'
}
param vmSize string {
  metadata: {
    description: 'VM Size'
  }
  default: 'Standard_A0'
}
param chef_node_name string {
  metadata: {
    description: 'The name for the node (VM) in the Chef Organization'
  }
}
param chef_server_url string {
  metadata: {
    description: 'Organization URL for the Chef Server. Example https://ChefServerDnsName.cloudapp.net/organizations/Orgname'
  }
}
param validation_client_name string {
  metadata: {
    description: 'Validator key name for the organization. Example : MyOrg-validator'
  }
}
param runlist string {
  metadata: {
    description: 'Optional Run List to Execute'
  }
  default: 'recipe[getting-started]'
}
param validation_key string {
  metadata: {
    description: 'JSON Escaped Validation Key'
  }
}
param validation_key_format string {
  allowed: [
    'plaintext'
    'base64encoded'
  ]
  metadata: {
    description: 'Format in which Validation Key is given. e.g. plaintext, base64encoded'
  }
  default: 'plaintext'
}
param secret string {
  metadata: {
    description: 'Encrypted Data bag secret'
  }
  default: 'my_secret_key'
}
param chef_service_interval string {
  metadata: {
    description: 'Frequency(in minutes) at which the chef-service runs.'
  }
  default: '30'
}
param bootstrap_version string {
  metadata: {
    description: 'Chef Client Version'
  }
  default: 'latest'
}
param bootstrap_channel string {
  metadata: {
    description: 'Release channel for Chef Client Version'
  }
  default: 'stable'
}
param daemon string {
  metadata: {
    description: 'Daemon option is only for Windows. Allowed values: none/service/task'
  }
  default: 'service'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param authenticationType string {
  allowed: [
    'sshPublicKey'
    'password'
  ]
  metadata: {
    description: 'Type of authentication to use on the Virtual Machine. SSH key is recommended.'
  }
  default: 'sshPublicKey'
}
param adminPasswordOrKey string {
  metadata: {
    description: 'SSH Key or password for the Virtual Machine. SSH key is recommended.'
  }
  secure: true
}

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
var vnetID = virtualNetworkName_resource.id
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var vmExtensionName = 'LinuxChefExtension'
var vmName = vmDnsName
var storageAccountType = 'Standard_LRS'
var newStorageAccountName = '${uniqueString(resourceGroup().id)}cheflinuxvm'
var publicIPAddressName = 'myPublicIP1'
var publicIPAddressType = 'Dynamic'
var vmStorageAccountContainerName = 'vhds'
var virtualNetworkName = 'MyVNET1'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'subnet-1'
var subnet2Name = 'subnet-2'
var subnet1Prefix = '10.0.0.0/24'
var subnet2Prefix = '10.0.1.0/24'
var nicName = 'myVMNic'
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
var networkSecurityGroupName = 'default-NSG'

resource newStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-05-01-preview' = {
  name: newStorageAccountName
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: vmDnsName
    }
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName
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

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
  name: virtualNetworkName
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
            id: networkSecurityGroupName_resource.id
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
  dependsOn: [
    networkSecurityGroupName_resource
  ]
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: nicName
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
            id: subnet1Ref
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
    virtualNetworkName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
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
        publisher: images[osType].publisher
        offer: images[osType].offer
        sku: images[osType].sku
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccountName_resource
    nicName_resource
  ]
}

resource vmName_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  name: '${vmName}/${vmExtensionName}'
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
  dependsOn: [
    vmName_resource
  ]
}