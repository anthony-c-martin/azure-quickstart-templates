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
param eapUserName string {
  metadata: {
    description: 'User name for EAP manager'
  }
}
param eapPassword string {
  metadata: {
    description: 'Password for EAP manager'
  }
  secure: true
}
param rhsmUserName string {
  metadata: {
    description: 'User name for Red Hat subscription manager'
  }
}
param rhsmPassword string {
  metadata: {
    description: 'Password for Red Hat subscription  manager'
  }
  secure: true
}
param rhsmPool string {
  metadata: {
    description: 'Red Hat Subscription Manager Pool (must contain JBoss EAP entitlement).'
  }
}
param sshPassPhrase string {
  metadata: {
    description: 'Pass phrase for SSH certificate'
  }
  secure: true
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/jboss-eap-standalone-rhel7/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
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
var baseName = uniqueString(dnsLabelPrefix, resourceGroup().id)
var nicName_var = 'myNic8${baseName}'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var publicIPAddressName_var = 'myIP8${baseName}'
var publicIPAddressType = 'Dynamic'
var vmName_var = dnsLabelPrefix
var vmSize = 'Standard_F1'
var virtualNetworkName_var = 'MyVNET8'
var frontEndNSGName_var = '${dnsLabelPrefix}-nsg8'
var storageAccountType = 'Standard_LRS'
var storageAccountName_var = 'vsts8${baseName}'
var ScriptFolder = 'scripts'
var ScriptFileName = 'eap-setup-redhat.sh'
var subnet1Ref = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnet1Name)
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

resource StorageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {}
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2017-10-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource frontEndNSGName 'Microsoft.Network/networkSecurityGroups@2017-10-01' = {
  name: frontEndNSGName_var
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
        name: 'default-allow-eap-admin'
        properties: {
          description: 'Allow EAP/ADMIN'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9990'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1020
          direction: 'Inbound'
        }
      }
      {
        name: 'default-allow-eap'
        properties: {
          description: 'Allow WEB/EAP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2017-10-01' = {
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
            id: frontEndNSGName.id
          }
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2017-10-01' = {
  name: nicName_var
  location: location
  properties: {
    networkSecurityGroup: {
      id: frontEndNSGName.id
    }
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
      customData: base64(publicIPAddressName_var)
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
}

resource vmName_newuserscript 'Microsoft.Compute/virtualMachines/extensions@2017-12-01' = {
  name: '${vmName_var}/newuserscript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, '${ScriptFolder}/${ScriptFileName}${artifactsLocationSasToken}')
      ]
      commandToExecute: 'sh eap-setup-redhat.sh ${adminUsername} ${eapUserName} ${eapPassword} ${rhsmUserName} ${rhsmPassword} ${rhsmPool} ${sshPassPhrase}'
    }
  }
}