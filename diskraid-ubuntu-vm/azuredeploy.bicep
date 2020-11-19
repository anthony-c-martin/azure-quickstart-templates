param adminUsername string {
  metadata: {
    description: 'Admin username used when provisioning virtual machines'
  }
}
param storageAccountName string {
  metadata: {
    description: 'Unique namespace for the Storage Account where the Virtual Machine\'s disks will be placed'
  }
}
param virtualNetworkName string {
  metadata: {
    description: 'Virtual Network'
  }
  default: 'myVNET'
}
param vmSize string {
  metadata: {
    description: 'Size of the virtual machine'
  }
  default: 'Standard_A1'
}
param addressPrefix string {
  metadata: {
    description: 'Address space for the VNET'
  }
  default: '10.0.0.0/16'
}
param subnet1Name string {
  metadata: {
    description: 'Subnet name for the VNET that resources will be provisioned in to'
  }
  default: 'Data'
}
param subnet1Prefix string {
  metadata: {
    description: 'Address space for the subnet'
  }
  default: '10.0.0.0/24'
}
param dnsName string {
  metadata: {
    description: 'Load balancer subdomain name: for example (<subdomain>.westus.cloudapp.azure.com)'
  }
}
param dataDiskSize int {
  metadata: {
    description: 'Size of each data disk attached to data nodes in (Gb)'
  }
  default: 20
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

var vnetID = virtualNetworkName_resource.id
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var scriptUrl = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/shared_scripts/ubuntu/vm-disk-utils-0.1.sh'
var securityGroupName = 'diskraidnsg'
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

resource securityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: securityGroupName
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
      id: securityGroupName_resource.id
    }
  }
  dependsOn: [
    virtualNetworkName_resource
    publicIp
    securityGroupName_resource
  ]
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
    nic
    storageAccountName_resource
  ]
}

resource myvm_azureVmUtils 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: 'myvm/azureVmUtils'
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
  dependsOn: [
    myvm
  ]
}