param adminUsername string {
  metadata: {
    description: 'Linux VM user account name'
  }
}
param dnsLabelPrefix string {
  metadata: {
    description: 'DNS Label for the Public IP. Must be lowercase. It should match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.'
  }
}
param tomcatUserName string {
  metadata: {
    description: 'User name for Tomcat manager'
  }
  default: 'tcdeploy'
}
param tomcatPassword string {
  metadata: {
    description: 'Password for Tomcat manager'
  }
}
param sshPassPhrase string {
  metadata: {
    description: 'Pass phrase for SSH certificate'
  }
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

var imagePublisher = 'redhat'
var imageOffer = 'rhel'
var imageSKU = '7.2'
var baseName = uniqueString(dnsLabelPrefix, resourceGroup().id, uniqueString(deployment().name))
var nicName = 'myNic8${baseName}'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var publicIPAddressName = 'myIP8${baseName}'
var publicIPAddressType = 'Dynamic'
var vmStorageAccountContainerName = 'vhds'
var vmName = dnsLabelPrefix
var vmSize = 'Standard_F1'
var virtualNetworkName = 'MyVNET8'
var frontEndNSGName = '${dnsLabelPrefix}-nsg8'
var vnetID = virtualNetworkName_resource.id
var storageAccountType = 'Standard_LRS'
var storageAccountName = 'vsts8${baseName}'
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
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

resource StorageAccountName_resource 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {}
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource frontEndNSGName_resource 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: frontEndNSGName
  location: location
  tags: {
    displayName: 'Custom Network Security Group'
  }
  properties: {
    securityRules: [
      {
        name: 'default-allow-ssh'
        properties: {
          description: 'Allow SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'default-allow-tomcat'
        properties: {
          description: 'Allow WEB/Tomcat'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
        }
      }
      {
        name: 'default-allow-ftp'
        properties: {
          description: 'Allow FTP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '21'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1020
          direction: 'Inbound'
        }
      }
      {
        name: 'default-allow-ftps'
        properties: {
          description: 'Allow FTPS'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '13450-13454'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1030
          direction: 'Inbound'
        }
      }
    ]
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
          networkSecurityGroup: {
            id: frontEndNSGName_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    frontEndNSGName_resource
  ]
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName
  location: location
  properties: {
    networkSecurityGroup: {
      id: frontEndNSGName_resource.id
    }
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
    frontEndNSGName_resource
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
      customData: base64(publicIPAddressName)
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
    StorageAccountName_resource
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
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/vsts-tomcat-redhat-vm/scripts/tomcat-setup-redhat.sh'
      ]
      commandToExecute: 'sh tomcat-setup-redhat.sh ${adminUsername} ${tomcatUserName} ${tomcatPassword} ${sshPassPhrase}'
    }
  }
  dependsOn: [
    vmName_resource
  ]
}