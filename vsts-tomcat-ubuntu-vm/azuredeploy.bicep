param adminUsername string {
  metadata: {
    description: 'Linux VM User Account Name'
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
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: deployment().properties.templateLink.uri
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param vmSize string {
  metadata: {
    description: 'VM Size or SKU.'
  }
  default: 'Standard_F1'
}

var imagePublisher = 'canonical'
var imageOffer = 'ubuntuserver'
var imageSKU = '16.04.0-LTS'
var baseName = uniqueString(dnsLabelPrefix, resourceGroup().id)
var nicName = 'myNic7${baseName}'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var publicIPAddressName = 'myIP7${baseName}'
var publicIPAddressType = 'Dynamic'
var vmName = dnsLabelPrefix
var virtualNetworkName = 'MyVNET7'
var frontEndNSGName = '${dnsLabelPrefix}-nsg7'
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

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2019-06-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource frontEndNSGName_resource 'Microsoft.Network/networkSecurityGroups@2019-06-01' = {
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

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-06-01' = {
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

resource nicName_resource 'Microsoft.Network/networkInterfaces@2019-06-01' = {
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

resource vmName_resource 'Microsoft.Compute/virtualMachines@2019-07-01' = {
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
    nicName_resource
  ]
}

resource vmName_newuserscript 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  name: '${vmName}/newuserscript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      fileUris: [
        uri(artifactsLocation, 'scripts/tomcat-setup-ubuntu.sh${artifactsLocationSasToken}')
      ]
      commandToExecute: 'sh tomcat-setup-ubuntu.sh ${adminUsername} ${tomcatUserName} ${tomcatPassword} ${sshPassPhrase}'
    }
  }
  dependsOn: [
    vmName_resource
  ]
}