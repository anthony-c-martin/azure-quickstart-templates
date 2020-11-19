param adminUsername string {
  metadata: {
    description: 'User name for the Virtual Machine.'
  }
}
param mysqlPassword string {
  metadata: {
    description: 'Password for the openvpn user.'
  }
  secure: true
}
param dnsNamePrefix string {
  metadata: {
    description: 'DNS Name for the publicly accessible node. Must be lowercase. It should match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.'
  }
}
param vmSize string {
  allowed: [
    'Standard_A1'
    'Standard_A2'
    'Standard_A3'
    'Standard_D1'
    'Standard_D3'
    'Standard_D4'
  ]
  metadata: {
    description: 'The size of the virtual machines used when provisioning'
  }
  default: 'Standard_A1'
}
param ubuntuOSVersion string {
  allowed: [
    '12.04.5-LTS'
    '14.04.5-LTS'
    '15.10'
  ]
  metadata: {
    description: 'The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version. Allowed values: 12.04.5-LTS, 14.04.5-LTS, 15.10.'
  }
  default: '14.04.5-LTS'
}
param artifactsLocation string {
  metadata: {
    description: 'Default URI of the template folder. Override with your own URI when using a different path.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/mysql-standalone-server-ubuntu'
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

var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var OSDiskName = 'osdiskforlinuxsimple'
var nicName = 'myVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var storageAccountName = '${uniqueString(resourceGroup().id)}standardsa'
var apiVersion = '2015-06-15'
var storageAccountType = 'Standard_LRS'
var publicIPAddressName = 'myPublicIP'
var publicIPAddressType = 'Dynamic'
var vmStorageAccountContainerName = 'vhds'
var vmName = 'MyubuntuVM'
var virtualNetworkName = 'MyVNET'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
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

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageAccountName
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNamePrefix
    }
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
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2015-06-15' = {
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
            id: subnetRef
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
        publisher: imagePublisher
        offer: imageOffer
        sku: ubuntuOSVersion
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
    storageAccountName_resource
    nicName_resource
  ]
}

resource vmName_newuserscript 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName}/newuserscript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation}/scripts/install_mysql_server_5.6.sh'
      ]
    }
    protectedSettings: {
      commandToExecute: 'bash install_mysql_server_5.6.sh ${mysqlPassword}'
    }
  }
  dependsOn: [
    vmName_resource
  ]
}