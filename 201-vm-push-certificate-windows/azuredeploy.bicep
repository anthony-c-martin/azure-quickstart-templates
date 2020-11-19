param vmName string {
  metadata: {
    description: 'Name of the VM'
  }
  default: 'WindowsVm'
}
param vmSize string {
  metadata: {
    description: 'Size of the VM'
  }
  default: 'Standard_DS2_v2'
}
param adminUsername string {
  metadata: {
    description: 'Admin Username'
  }
}
param adminPassword string {
  metadata: {
    description: 'Admin Password'
  }
  secure: true
}
param vaultResourceId string {
  metadata: {
    description: 'Resource Group of Key Vault that has a secret - must be of the format /subscriptions/xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/<vaultName>/providers/Microsoft.KeyVault/vaults/<vaultName>'
  }
}
param secretUrlWithVersion string {
  metadata: {
    description: 'Url of the certificate in Key Vault - the url must be to a base64 encoded secret, not a key or cert: https://<vaultEndpoint>/secrets/<secretName>/<secretVersion>'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var subnet1Ref = resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName, subnet1Name)
var nicName = 'certNIC'
var subnet1Prefix = '10.0.0.0/24'
var subnet1Name = 'Subnet-1'
var virtualNetworkName = 'certVNET'
var addressPrefix = '10.0.0.0/16'
var publicIPName = 'certPublicIP'
var networkSecurityGroupName = '${subnet1Name}-nsg'

resource publicIPName_resource 'Microsoft.Network/publicIPAddresses@2019-06-01' = {
  name: publicIPName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
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
            id: networkSecurityGroupName_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    networkSecurityGroupName_resource
  ]
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2019-06-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPName_resource.id
          }
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPName_resource
    virtualNetworkName_resource
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
      adminPassword: adminPassword
      secrets: [
        {
          sourceVault: {
            id: vaultResourceId
          }
          vaultCertificates: [
            {
              certificateUrl: secretUrlWithVersion
              certificateStore: 'My'
            }
          ]
        }
      ]
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
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