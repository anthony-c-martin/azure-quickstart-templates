param coscaleKey string {
  metadata: {
    description: 'CoScale registration key. Get it at https://www.coscale.com/azure/'
  }
  secure: true
}
param coscaleEmail string {
  metadata: {
    description: 'Email for the CoScale Super User.'
  }
}
param coscalePassword string {
  metadata: {
    description: 'Password for the CoScale Super User.'
  }
  secure: true
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/coscale-dev-env/'
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

var newStorageAccountName_var = '${uniqueString(resourceGroup().id)}stg'
var vmStorageAccountContainerName = 'vdh'
var publicDnsName = 'coscale-${uniqueString(resourceGroup().id)}'
var vmSize = 'Standard_DS4_v2'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var vmName_var = 'coscale'
var nicName_var = 'coscaleNic'
var networkSecurityGroupName_var = 'coscaleNSG'
var publicIPAddressName_var = 'coscalePublicIP'
var vmUser = 'cs'
var vmPublicKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCkbtWpHEyZYJ+Eyl+jFVUYOH+YBqGAAvyl9oJRzWieJlDp9PucYhbtlXTm7VhlSZvFi7MtcJoxzlQqk1FoNsUPtPyrCtVz8uEHS4FZiuOhb1UFLMayInfXWUWzBt0EEbELlgipRpqGgsi+pn3P07C+8VcBXhAPpMn7Y3qb3txlr7tCCowk8XbXE+MFwfLMXqHavgzIcI++6zECQoFCjb1ktpiAPcP/HkzNDJ2r3tAWyJWOMs1GH3f67corKaKh54LCmQRJS1FAUEnb9da4Xn+Tgx16f42aBF4gY5CEmg2NZ4tvbgE7hXKxJY0TEBTQ1zjUgv92gXOuGcRgu+XM8fut CoScaleAzure'
var virtualNetworkName_var = 'coscaleVNET'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)

resource newStorageAccountName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: newStorageAccountName_var
  location: location
  properties: {
    accountType: 'Premium_LRS'
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: publicDnsName
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
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
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-ssh'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '22'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-http'
        properties: {
          priority: 1001
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '80'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-https'
        properties: {
          priority: 1002
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '443'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroupName.id
    }
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName_var
  location: location
  properties: {
    osProfile: {
      computerName: vmName_var
      adminUsername: vmUser
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${vmUser}/.ssh/authorized_keys'
              keyData: vmPublicKey
            }
          ]
        }
      }
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '16.04.0-LTS'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          name: '${vmName_var}_DataDisk'
          diskSizeGB: 512
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
        }
      ]
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
    newStorageAccountName
  ]
}

resource vmName_vmName_install 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName_var}/${vmName_var}-install'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation}install.sh${artifactsLocationSasToken}'
      ]
      commandToExecute: 'bash install.sh ${coscaleKey} ${coscaleEmail} ${coscalePassword} ${reference(publicIPAddressName_var).dnsSettings.fqdn}'
    }
  }
  dependsOn: [
    vmName
  ]
}

output coscaleURL string = 'http://${reference(publicIPAddressName_var).dnsSettings.fqdn}'