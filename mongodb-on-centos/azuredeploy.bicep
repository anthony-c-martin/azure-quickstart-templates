param dnsNameForPublicIP string {
  metadata: {
    description: 'Unique FQDN for the VM'
  }
}
param adminUsername string {
  metadata: {
    description: 'Desired admin username to log on to the VM'
  }
}
param imagePublisher string {
  metadata: {
    description: 'Image Publisher'
  }
  default: 'OpenLogic'
}
param imageOffer string {
  metadata: {
    description: 'Image Offer'
  }
  default: 'CentOS'
}
param imageSKU string {
  metadata: {
    description: 'Image SKU'
  }
  default: '7.7'
}
param vmSize string {
  metadata: {
    description: 'Desired VM size'
  }
  default: 'Standard_A1_v2'
}
param publicIPAddressName string {
  metadata: {
    description: 'Name of the public IP address'
  }
  default: 'myPublicIP'
}
param vmName string {
  metadata: {
    description: 'Name of the VM'
  }
  default: 'myLinuxVM'
}
param virtualNetworkName string {
  metadata: {
    description: 'Name of the virtual network'
  }
  default: 'myVNET'
}
param nicName string {
  metadata: {
    description: 'Name of the virtual network adapter'
  }
  default: 'myNIC'
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
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. For example, if stored on a public GitHub repo, you\'d use the following URI: https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/mongodb-on-ubuntu/.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/mongodb-on-centos/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  If your artifacts are stored on a public repo or public storage account you can leave this blank.'
  }
  secure: true
  default: ''
}

var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet2Name = 'Subnet-2'
var subnet1Prefix = '10.0.0.0/24'
var subnet2Prefix = '10.0.1.0/24'
var publicIPAddressType = 'Dynamic'
var subnet1Ref = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnet1Name)
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

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2Prefix
        }
      }
    ]
  }
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2020-05-01' = {
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
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
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
    nicName_resource
  ]
}

resource vmName_installmongo 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${vmName}/installmongo'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'mongo-install-centos.sh${artifactsLocationSasToken}')
      ]
      commandToExecute: 'sh mongo-install-centos.sh'
    }
  }
  dependsOn: [
    vmName_resource
  ]
}