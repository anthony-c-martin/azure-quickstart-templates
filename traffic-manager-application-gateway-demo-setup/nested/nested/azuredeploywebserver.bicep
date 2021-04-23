@minLength(1)
@description('User name for the Web Server VM.')
param adminUsername string

@description('Password for the Web Server VM.')
@secure()
param adminPassword string

@minLength(1)
@description('Globally unique DNS Name for the Public IP used to access the Web Server VM.')
param dnsNameForPublicIP string

@allowed([
  '14.04.5-LTS'
  '16.04.0-LTS'
])
@description('The Ubuntu version for the Web Server VM. Allowed values: 14.04.5-LTS, 16.04.0-LTS')
param ubuntuOSVersion string = '14.04.5-LTS'

@description('Test page you want to create on the Web Server.')
param testPage string = 'index.html'

@description('Test page title.')
param testPageTitle string = 'Test Page'

@description('Test page content body markup.')
param testPageBody string = '<p>This is a test page.</p>'

@description('Set to True to install PHP.')
param installPHP bool = false

@allowed([
  'East Asia'
  'Southeast Asia'
  'Central US'
  'East US'
  'East US 2'
  'West US'
  'North Central US'
  'South Central US'
  'North Europe'
  'West Europe'
  'Japan West'
  'Japan East'
  'Brazil South'
  'Australia East'
  'Australia Southeast'
  'South India'
  'Central India'
  'West India'
  'Canada Central'
  'Canada East'
])
@description('Location of resources')
param location string

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/traffic-manager-application-gateway-demo-setup/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

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

resource dnsNameForPublicIP_resource 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
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
            id: dnsNameForPublicIP_resource.id
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
      adminPassword: adminPassword
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
  parent: vmName
  name: 'PrepareServer'
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
}

output fqdn string = reference(dnsNameForPublicIP).dnsSettings.fqdn
output ipId string = dnsNameForPublicIP_resource.id
output pageContent string = testPageMarkup