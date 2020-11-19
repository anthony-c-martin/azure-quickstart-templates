param adminUsername string {
  metadata: {
    description: 'User name for the Virtual Machine.'
  }
}
param sshKeyData string {
  metadata: {
    description: 'The SSH public key data for the administrator account as a string.'
  }
}
param dnsLabelPrefix string {
  metadata: {
    description: 'DNS Label for the Public IP. Must be lowercase. It should match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.'
  }
}
param ubuntuOSVersion string {
  allowed: [
    '18.04-LTS'
    '16.04.0-LTS'
    '14.04.5-LTS'
  ]
  metadata: {
    description: 'The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version. Allowed values: 18.04-LTS, 16.04.0-LTS, 14.04.5-LTS.'
  }
  default: '18.04-LTS'
}
param dokkuVersion string {
  metadata: {
    description: 'The Dokku version to launch'
  }
  default: '0.21.3'
}
param vmSize string {
  metadata: {
    description: 'Size of the virtual machine'
  }
  default: 'Standard_D2S_V3'
}
param storageAccountType string {
  allowed: [
    'Standard_LRS'
    'Premium_LRS'
  ]
  metadata: {
    description: 'Type of storage to be used for the VM\'s OS disk.  Diagnostics disk will use Standard_LRS.'
  }
  default: 'Standard_LRS'
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
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var storageAccountName = '${uniqueString(resourceGroup().id)}dokku'
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var nicName = 'dokkuVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressName = 'dokkuPublicIP'
var publicIPAddressType = 'Dynamic'
var vmName = 'DokkuVM'
var virtualNetworkName = 'DokkuVNet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName, subnetName)
var sshKeyPath = '/home/${adminUsername}/.ssh/authorized_keys'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
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
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
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
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: sshKeyPath
              keyData: sshKeyData
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: ubuntuOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageAccountType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName_resource.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccountName_resource.properties.primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    storageAccountName_resource
    nicName_resource
  ]
}

resource vmName_initdokku 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${vmName}/initdokku'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'scripts/deploy_dokku.sh${artifactsLocationSasToken}')
      ]
      commandToExecute: 'sh deploy_dokku.sh ${dokkuVersion}'
    }
  }
  dependsOn: [
    vmName_resource
  ]
}