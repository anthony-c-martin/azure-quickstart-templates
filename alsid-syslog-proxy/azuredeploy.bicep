@minLength(1)
@description('Hostname of the virtual machine.')
param vmName string

@minLength(1)
@description('User name of the administrator account of the virtual machine.')
param vmAdminUserName string

@description('Password of the administrator account of the virtual machine')
@secure()
param vmAdminPassword string

@description('DNS Label for the Public IP. Must be lowercase. It should match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.')
param dnsLabelPrefix string = 'a${uniqueString(resourceGroup().id)}'

@description('The ID of the log analytics workspace where you want to forward the logs. To find it, go to your workspace and you will have both the workspace ID and Primary key in the \'Agent management\' tab.')
param workspaceId string

@description('The key to authenticate to the log analytics workspace where you want to forward the logs. To find it, go to your workspace and you will have both the workspace ID and Primary key in the \'Agent management\' tab.')
param primaryKey string

@allowed([
  '12.04.5-LTS'
  '14.04.2-LTS'
  '15.04'
  '18.04-LTS'
])
@description('Version of the Ubuntu OS.')
param vmUbuntuOSVersion string = '18.04-LTS'

@description('Size of the virtual machine\'s disk')
param vmSize string = 'Standard_A3'

@description('Location where resources should be deployed.')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/alsid-syslog-proxy/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

var vmImagePublisher = 'Canonical'
var vmImageOffer = 'UbuntuServer'
var vmNicName_var = '${vmName}NetworkInterface'
var netPrefix = '10.0.0.0/16'
var netSubnet1Name = 'Subnet-1'
var netSubnet1Prefix = '10.0.0.0/24'
var netSubnet2Name = 'Subnet-2'
var netSubnet2Prefix = '10.0.1.0/24'
var publicIPAddressName_var = 'alsid-syslog-IP'
var setupScriptURI = uri(artifactsLocation, 'scripts/setup.sh${artifactsLocationSasToken}')

resource vmName_resource 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName
  location: location
  tags: {
    displayName: 'vm'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmAdminUserName
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: vmImagePublisher
        offer: vmImageOffer
        sku: vmUbuntuOSVersion
        version: 'latest'
      }
      osDisk: {
        name: 'vmOSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNicName.id
        }
      ]
    }
  }
}

resource vmName_config_app 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  parent: vmName_resource
  name: 'config-app'
  location: location
  tags: {
    displayName: 'config-app'
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        setupScriptURI
      ]
    }
    protectedSettings: {
      commandToExecute: 'sudo ./setup.sh ${workspaceId} ${primaryKey} ${artifactsLocation} ${publicIPAddressName.properties.dnsSettings.fqdn} ${artifactsLocationSasToken}'
    }
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource net 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: 'net'
  location: location
  tags: {
    displayName: 'net'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        netPrefix
      ]
    }
    subnets: [
      {
        name: netSubnet1Name
        properties: {
          addressPrefix: netSubnet1Prefix
        }
      }
      {
        name: netSubnet2Name
        properties: {
          addressPrefix: netSubnet2Prefix
        }
      }
    ]
  }
}

resource vmNicName 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: vmNicName_var
  location: location
  tags: {
    displayName: 'vmNic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          publicIPAddress: {
            id: publicIPAddressName.id
          }
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets/', 'net', netSubnet1Name)
          }
        }
      }
    ]
  }
  dependsOn: [
    net
  ]
}