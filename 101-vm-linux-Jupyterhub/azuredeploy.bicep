param adminUsername string {
  metadata: {
    description: 'Username for Administrator Account'
  }
}
param vmName string {
  metadata: {
    description: 'The name of you Virtual Machine.'
  }
  default: 'Ubuntu-Jupyter'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param cpu_gpu string {
  allowed: [
    'CPU-4GB'
    'CPU-7GB'
    'CPU-8GB'
    'CPU-14GB'
    'CPU-16GB'
    'GPU-56GB'
  ]
  metadata: {
    description: 'Choose between CPU or GPU processing'
  }
  default: 'CPU-4GB'
}
param virtualNetworkName string {
  metadata: {
    description: 'Name of the VNET'
  }
  default: 'vNet'
}
param subnetName string {
  metadata: {
    description: 'Name of the subnet in the virtual network'
  }
  default: 'subnet'
}
param networkSecurityGroupName string {
  metadata: {
    description: 'Name of the Network Security Group'
  }
  default: 'SecGroupNet'
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-vm-linux-Jupyterhub/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param diskSizeGB string {
  allowed: [
    '1024'
    '2048'
    '4096'
    '8192'
    '16384'
    '32767'
  ]
  metadata: {
    description: 'The size for an atached disk.'
  }
  default: '1024'
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

var networkInterfaceName = '${vmName}NetInt'
var publicIpAddressName = '${vmName}PublicIP'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var nsgId = networkSecurityGroupName_resource.id
var storageAccountName = 'storage${uniqueString(resourceGroup().id)}'
var storageAccountType = 'Standard_LRS'
var storageAccountKind = 'Storage'
var vmSize = {
  'CPU-4GB': 'Standard_B2s'
  'CPU-7GB': 'Standard_DS2_v2'
  'CPU-8GB': 'Standard_D2s_v3'
  'CPU-14GB': 'Standard_DS3_v2'
  'CPU-16GB': 'Standard_D4s_v3'
  'GPU-56GB': 'Standard_NC6_Promo'
}
var vmName_variable = '${vmName}-${cpu_gpu}'
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

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-06-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'HTTP'
        properties: {
          priority: 300
          protocol: 'TCP'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
      {
        name: 'HTTPS'
        properties: {
          priority: 310
          protocol: 'TCP'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'SSH'
        properties: {
          priority: 340
          protocol: 'TCP'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'AzureNotebooks'
        properties: {
          priority: 360
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '8000'
        }
      }
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/24'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

resource publicIpAddressName_resource 'Microsoft.Network/publicIpAddresses@2019-06-01' = {
  name: publicIpAddressName
  location: location
  properties: {
    publicIpAllocationMethod: 'Dynamic'
  }
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
}

resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2019-06-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIpAddress: {
            id: publicIpAddressName_resource.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
  }
  dependsOn: [
    networkSecurityGroupName_resource
    virtualNetworkName_resource
    publicIpAddressName_resource
  ]
}

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: storageAccountKind
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vmName_variable
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize[cpu_gpu]
    }
    storageProfile: {
      osDisk: {
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      dataDisks: [
        {
          lun: 0
          name: 'Datadisk${vmName}'
          createOption: 'Empty'
          diskSizeGB: diskSizeGB
        }
      ]
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName_resource.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: concat(reference(storageAccountName).primaryEndpoints.blob)
      }
    }
  }
  dependsOn: [
    networkInterfaceName_resource
    storageAccountName_resource
  ]
}

resource vmName_installscript 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  name: '${vmName_variable}/installscript'
  location: location
  tags: {
    displayName: 'Execute my custom script'
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      commandToExecute: 'bash install.sh ${adminUsername}'
      fileUris: [
        uri(artifactsLocation, 'scripts/install.sh${artifactsLocationSasToken}')
      ]
    }
  }
  dependsOn: [
    vmName_resource
  ]
}

output adminUsername_output string = adminUsername