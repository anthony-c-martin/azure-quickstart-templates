param adminUsername string {
  minLength: 1
  metadata: {
    description: 'User name for the Web Server VM.'
  }
}
param dnsNameForPublicIP string {
  minLength: 1
  metadata: {
    description: 'Globally unique DNS Name for the Public IP used to access the Web Server VM.'
  }
}
param ubuntuOSVersion string {
  allowed: [
    '14.04.5-LTS'
    '16.04.0-LTS'
  ]
  metadata: {
    description: 'The Ubuntu version for the Web Server VM. Allowed values: 14.04.5-LTS, 16.04.0-LTS'
  }
  default: '14.04.5-LTS'
}
param testPage string {
  metadata: {
    description: 'Test page you want to create on the Web Server.'
  }
  default: 'index.html'
}
param testPageTitle string {
  metadata: {
    description: 'Test page title.'
  }
  default: 'Test Page'
}
param testPageBody string {
  metadata: {
    description: 'Test page content body markup.'
  }
  default: '<p>This is a test page.</p>'
}
param installPHP bool {
  metadata: {
    description: 'Set to True to install PHP.'
  }
  default: false
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/ubuntu-apache-test-page/'
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

var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var OSDiskName = 'webtestosdisk-${dnsNameForPublicIP}'
var nicName_var = 'webtestnic-${dnsNameForPublicIP}-${uniqueString(resourceGroup().id)}'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var vhdStorageType = 'Standard_LRS'
var publicIPAddressType = 'Dynamic'
var vhdStorageContainerName = 'vhds'
var vmName_var = 'webtestvm-${dnsNameForPublicIP}-${uniqueString(resourceGroup().id)}'
var vmSize = 'Standard_D2_v2'
var virtualNetworkName_var = 'webtestvnet-${uniqueString(resourceGroup().id, dnsNameForPublicIP)}'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var vhdStorageName_var = 'webtestvhd${uniqueString(resourceGroup().id, dnsNameForPublicIP)}'
var singleQuote = '\''
var frontEndNSGName_var = 'webtestnsg-${uniqueString(resourceGroup().id, dnsNameForPublicIP)}'
var testPageMarkup = '<html><head><title>${testPageTitle}</title></head><body>${testPageBody}</body></html>'
var scriptFolder = 'scripts'
var serverPrepareScriptFileName = 'prepwebserver.sh'
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

resource vhdStorageName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: vhdStorageName_var
  location: location
  tags: {
    displayName: 'StorageAccount'
  }
  properties: {
    accountType: vhdStorageType
  }
}

resource dnsNameForPublicIP_res 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: dnsNameForPublicIP
  location: location
  tags: {
    displayName: 'PublicIPAddress'
  }
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: virtualNetworkName_var
  location: location
  tags: {
    displayName: 'VirtualNetwork'
  }
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

resource frontEndNSGName 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: frontEndNSGName_var
  location: location
  tags: {
    displayName: 'NSG - Web Server'
  }
  properties: {
    securityRules: [
      {
        name: 'ssh-rule'
        properties: {
          description: 'Allow SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'web-rule'
        properties: {
          description: 'Allow Web'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName_var
  location: location
  tags: {
    displayName: 'NetworkInterface'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: dnsNameForPublicIP_res.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: frontEndNSGName.id
    }
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName_var
  location: location
  tags: {
    displayName: 'VirtualMachine'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
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
  dependsOn: [
    vhdStorageName
  ]
}

resource vmName_PrepareServer 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName_var}/PrepareServer'
  location: location
  tags: {
    displayName: 'PrepareServer'
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation}/${scriptFolder}/${serverPrepareScriptFileName}${artifactsLocationSasToken}'
      ]
      commandToExecute: 'sh prepwebserver.sh ${string(installPHP)} ${singleQuote}${testPageMarkup}${singleQuote} ${testPage} ${singleQuote}${ubuntuOSVersion}${singleQuote}'
    }
  }
  dependsOn: [
    vmName
  ]
}

output fqdn string = reference(dnsNameForPublicIP).dnsSettings.fqdn
output pageContent string = testPageMarkup