@description('Admin username used when provisioning virtual machines')
param adminUsername string

@description('Unique namespace for the Storage Account where the Virtual Machine\'s disks will be placed')
param storageAccountName string

@description('Virtual Network')
param virtualNetworkName string = 'myVNET'

@description('Size of the virtual machine')
param vmSize string = 'Standard_A1'

@description('Address space for the VNET')
param addressPrefix string = '10.0.0.0/16'

@description('Subnet name for the VNET that resources will be provisioned in to')
param subnet1Name string = 'Data'

@description('Address space for the subnet')
param subnet1Prefix string = '10.0.0.0/24'

@description('Load balancer subdomain name: for example (<subdomain>.westus.cloudapp.azure.com)')
param dnsName string

@description('Size of each data disk attached to data nodes in (Gb)')
param dataDiskSize int = 20

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

var vnetID = virtualNetworkName_resource.id
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var scriptUrl = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/shared_scripts/ubuntu/vm-disk-utils-0.1.sh'
var securityGroupName_var = 'diskraidnsg'
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

resource securityGroupName 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: securityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          description: 'Allows SSH traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-05-01-preview' = {
  name: storageAccountName
  location: location
  properties: {
    accountType: 'Standard_LRS'
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-06-15' = {
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
        }
      }
    ]
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: 'publicIp'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsName
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: 'nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: securityGroupName.id
    }
  }
}

resource myvm 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: 'myvm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'myvm'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '14.04.5-LTS'
        version: 'latest'
      }
      osDisk: {
        name: 'myvm_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          name: 'myvm_DataDisk1'
          diskSizeGB: dataDiskSize
          lun: 0
          caching: 'None'
          createOption: 'Empty'
        }
        {
          name: 'myvm_DataDisk2'
          diskSizeGB: dataDiskSize
          lun: 1
          caching: 'None'
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
  dependsOn: [
    storageAccountName_resource
  ]
}

resource myvm_azureVmUtils 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  parent: myvm
  name: 'azureVmUtils'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        scriptUrl
      ]
      commandToExecute: 'bash vm-disk-utils-0.1.sh -s'
    }
  }
}