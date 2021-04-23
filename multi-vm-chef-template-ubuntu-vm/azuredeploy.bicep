@description('DNS name for the VM')
param vmDnsName string

@description('Number of VM instances to create, default is 2')
param numberOfInstances int = 2

@description('Availability Set name for the VMs')
param availabilitySetName string

@description('Admin user name for the Virtual Machines')
param adminUsername string

@description(' Publisher for the OS image, the default is Canonical')
param imagePublisher string = 'Canonical'

@description('The name of the image offer. The default is Ubuntu')
param imageOffer string = 'UbuntuServer'

@description('Version of the image. The default is 16.04-LTS')
param imageSKU string = '16.04-LTS'

@description('VM Size')
param vmSize string = 'Standard_D1'

@description('Organization URL for the Chef Server. Example https://chefserver.cloudapp.net/organizations/orgname')
param chef_server_url string

@description('Validator key name for the organization. Example: myorg-validator')
param validation_client_name string

@description('Optional Run List to Execute')
param runlist string = 'recipe[getting-started::default]'

@description('JSON Escaped Validation Key')
@secure()
param validation_key string

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

var vnetID = virtualNetworkName.id
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var vmExtensionName = 'LinuxChefExtension'
var vmName_var = vmDnsName
var publicIPAddressName_var = 'chefPublicIP'
var publicIPAddressType = 'Dynamic'
var virtualNetworkName_var = 'MyVNET'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var nicName_var = 'myVMNic'
var provider = toUpper('33194f91-eb5f-4110-827a-e95f640a9e46')
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

resource availabilitySetName_resource 'Microsoft.Compute/availabilitySets@2016-04-30-preview' = {
  name: availabilitySetName
  location: location
  properties: {
    managed: true
    platformFaultDomainCount: 3
    platformUpdateDomainCount: 5
  }
  tags: {
    provider: provider
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2017-03-01' = [for i in range(0, numberOfInstances): {
  name: concat(publicIPAddressName_var, i)
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: concat(vmDnsName, i)
    }
  }
  tags: {
    provider: provider
  }
}]

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2017-03-01' = {
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
        }
      }
    ]
  }
  tags: {
    provider: provider
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2017-03-01' = [for i in range(0, numberOfInstances): {
  name: concat(nicName_var, i)
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', concat(publicIPAddressName_var, i))
          }
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
  tags: {
    provider: provider
  }
  dependsOn: [
    'Microsoft.Network/publicIPAddresses/${publicIPAddressName_var}${i}'
    virtualNetworkName
  ]
}]

resource vmName 'Microsoft.Compute/virtualMachines@2016-04-30-preview' = [for i in range(0, numberOfInstances): {
  name: concat(vmName_var, i)
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetName_resource.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(vmName_var, i)
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
      }
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(nicName_var, i))
        }
      ]
    }
  }
  tags: {
    provider: provider
  }
  dependsOn: [
    'Microsoft.Network/networkInterfaces/${nicName_var}${i}'
    availabilitySetName_resource
  ]
}]

resource vmName_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2016-04-30-preview' = [for i in range(0, numberOfInstances): {
  name: '${vmName_var}${i}/${vmExtensionName}'
  location: location
  properties: {
    publisher: 'Chef.Bootstrap.WindowsAzure'
    type: 'LinuxChefClient'
    typeHandlerVersion: '1210.12'
    settings: {
      bootstrap_options: {
        chef_server_url: chef_server_url
        validation_client_name: validation_client_name
      }
      runlist: runlist
    }
    protectedSettings: {
      validation_key: validation_key
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${vmName_var}${i}'
  ]
}]