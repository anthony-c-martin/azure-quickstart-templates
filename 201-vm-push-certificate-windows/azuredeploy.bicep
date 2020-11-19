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

var subnet1Ref = resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName_var, subnet1Name)
var nicName_var = 'certNIC'
var subnet1Prefix = '10.0.0.0/24'
var subnet1Name = 'Subnet-1'
var virtualNetworkName_var = 'certVNET'
var addressPrefix = '10.0.0.0/16'
var publicIPName_var = 'certPublicIP'
var networkSecurityGroupName_var = '${subnet1Name}-nsg'

resource publicIPName 'Microsoft.Network/publicIPAddresses@2019-06-01' = {
  name: publicIPName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName_var
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

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2019-06-01' = {
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
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2019-06-01' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPName.id
          }
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource vmName_res 'Microsoft.Compute/virtualMachines@2019-07-01' = {
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
          id: nicName.id
        }
      ]
    }
  }
}