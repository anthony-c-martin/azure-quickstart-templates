param adminUsername string {
  metadata: {
    description: 'User name for the Virtual Machine.'
  }
}
param sshKeyData string {
  metadata: {
    description: 'Please copy the content of your SSH RSA public key and paste it here. You can use "ssh-keygen -t rsa -b 2048" to generate your SSH key pairs.'
  }
}
param dnsLabelPrefix string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Virtual Machine.'
  }
}
param ubuntuOSVersion string {
  allowed: [
    '16.04.0-LTS'
  ]
  metadata: {
    description: 'The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.'
  }
  default: '16.04.0-LTS'
}
param vmSize string {
  allowed: [
    'Basic_A3'
    'Basic_A4'
    'Standard_A3'
    'Standard_A4'
  ]
  metadata: {
    description: 'VM size.'
  }
  default: 'Basic_A3'
}
param adminEmail string {
  metadata: {
    description: 'admin_email is used to login seafile server, i.e. admin@seafile.local'
  }
}
param adminPass string {
  metadata: {
    description: 'admin_pass is optional, if you do not specify it, a random string is generated'
  }
  secure: true
  default: ''
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/ubuntu-netdisk-setup/'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var nicName = 'myVMNic1'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressName = 'myPublicIP'
var publicIPAddressType = 'Dynamic'
var vmName = 'MyUbuntuVM'
var virtualNetworkName = 'MyVNET'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var filesToDownload = uri(artifactsLocation, 'script/install.sh')
var sshKeyPath = '/home/${adminUsername}/.ssh/authorized_keys'

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2017-06-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2017-06-01' = {
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

resource nicName_resource 'Microsoft.Network/networkInterfaces@2017-06-01' = {
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
    networkSecurityGroup: {
      id: mysg.id
    }
  }
  dependsOn: [
    publicIPAddressName_resource
    virtualNetworkName_resource
  ]
}

resource mysg 'Microsoft.Network/networkSecurityGroups@2017-06-01' = {
  name: 'mysg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'port80'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
      {
        name: 'SSH'
        properties: {
          description: 'Allows SSH traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
    networkInterfaces: [
      {
        id: nicName_resource.id
      }
    ]
  }
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2016-04-30-preview' = {
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
      }
      dataDisks: [
        {
          diskSizeGB: 1023
          lun: 0
          createOption: 'Empty'
          caching: 'ReadWrite'
        }
      ]
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

resource vmName_CustomScript 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = {
  name: '${vmName}/CustomScript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    settings: {
      fileUris: [
        filesToDownload
      ]
    }
    protectedSettings: {
      commandToExecute: 'export TERM=xterm && bash install.sh -u ${adminEmail} -d ${reference(publicIPAddressName).dnsSettings.fqdn} -p "${adminPass}"'
    }
  }
  dependsOn: [
    vmName_resource
  ]
}

output hostname string = reference(publicIPAddressName).dnsSettings.fqdn
output sshCommand string = 'ssh ${adminUsername}@${reference(publicIPAddressName).dnsSettings.fqdn}'
output extensionOutput string = reference('Microsoft.Compute/virtualMachines/MyUbuntuVM/extensions/CustomScript').instanceView.statuses[0].message