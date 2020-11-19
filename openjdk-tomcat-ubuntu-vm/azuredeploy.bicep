param javaPackageName string {
  allowed: [
    'openjdk-11-jdk'
    'openjdk-12-jdk'
    'openjdk-13-jdk'
  ]
  metadata: {
    description: 'java Package Name'
  }
  default: 'openjdk-13-jdk'
}
param tomcatPackageName string {
  allowed: [
    'tomcat7'
    'tomcat8'
    'tomcat9'
  ]
  metadata: {
    description: 'tomcat Package Name'
  }
  default: 'tomcat9'
}
param adminUsername string {
  metadata: {
    description: 'User name for the Virtual Machine.'
  }
}
param vmSize string {
  metadata: {
    description: 'The size of the virtual machines used when provisioning'
  }
  default: 'Standard_D2s_v3'
}
param ubuntuOSVersion string {
  allowed: [
    '18.04-LTS'
    '16.04-LTS'
    '14.04.5-LTS'
  ]
  metadata: {
    description: 'The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.'
  }
  default: '18.04-LTS'
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
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/openjdk-tomcat-ubuntu-vm/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}

var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var nicName = 'myVMNic'
var nsgName = 'myNSG'
var vmName = 'Tomcat'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressName = 'myPublicIP'
var virtualNetworkName = 'MyVNET'
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
var networkSecurityGroupName = 'default-NSG'

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2019-06-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Basic'
  }
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
        name: 'default-allow-22'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
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
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
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
            id: publicIPAddressName_resource.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgName_resource.id
    }
  }
  dependsOn: [
    publicIPAddressName_resource
    virtualNetworkName_resource
    nsgName_resource
  ]
}

resource nsgName_resource 'Microsoft.Network/networkSecurityGroups@2019-06-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
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
        name: 'Web'
        properties: {
          description: 'Allow Web'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 112
          direction: 'Inbound'
        }
      }
    ]
  }
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
        osType: 'Linux'
        name: '${vmName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
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
  }
  dependsOn: [
    nicName_resource
  ]
}

resource vmName_installscript 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  name: '${vmName}/installscript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'java-tomcat-install.sh${artifactsLocationSasToken}')
      ]
      commandToExecute: 'sh java-tomcat-install.sh ${javaPackageName} ${tomcatPackageName}'
    }
  }
  dependsOn: [
    vmName_resource
  ]
}