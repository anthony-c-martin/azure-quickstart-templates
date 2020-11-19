param adminUsername string {
  metadata: {
    description: 'User name for the Virtual Machine.'
  }
}
param jenkinsDnsPrefix string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Jenkins Virtual Machine.'
  }
}
param jenkinsReleaseType string {
  allowed: [
    'LTS'
    'weekly'
    'verified'
  ]
  metadata: {
    description: 'The Jenkins release type'
  }
  default: 'LTS'
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
param vmSize string {
  metadata: {
    description: 'Size of the virtual machine.'
  }
  default: 'Standard_DS1_v2'
}

var resourcePrefix = 'jenkins'
var nicName = '${resourcePrefix}VMNic'
var subnetName = '${resourcePrefix}Subnet'
var publicIPAddressName = '${resourcePrefix}PublicIP'
var vmName = '${resourcePrefix}VM'
var vmExtensionName = '${resourcePrefix}Init'
var virtualNetworkName = '${resourcePrefix}VNET'
var frontEndNSGName = '${resourcePrefix}NSG'
var vNetAddressPrefixes = '10.0.0.0/16'
var sNetAddressPrefixes = '10.0.0.0/24'
var vmPrivateIP = '10.0.0.5'
var azureDevOpsUtilsLocation = 'https://raw.githubusercontent.com/Azure/azure-devops-utils/master/'
var extensionScript = 'install_jenkins.sh'
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

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: jenkinsDnsPrefix
    }
  }
}

resource frontEndNSGName_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: frontEndNSGName
  location: location
  tags: {
    displayName: 'NSG - Front End'
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
        name: 'http-rule'
        properties: {
          description: 'Allow HTTP'
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

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNetAddressPrefixes
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: sNetAddressPrefixes
          networkSecurityGroup: {
            id: frontEndNSGName_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    frontEndNSGName_resource
  ]
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIpAddress: vmPrivateIP
          publicIPAddress: {
            id: publicIPAddressName_resource.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
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

resource vmName_resource 'Microsoft.Compute/virtualMachines@2019-12-01' = {
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
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '16.04-LTS'
        version: 'latest'
      }
      osDisk: {
        name: 'osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
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

resource vmName_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  name: '${vmName}/${vmExtensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(azureDevOpsUtilsLocation, 'jenkins/${extensionScript}')
      ]
    }
    protectedSettings: {
      commandToExecute: './${extensionScript} -jf "${reference(publicIPAddressName).dnsSettings.fqdn}" -pi "${vmPrivateIP}" -al "${azureDevOpsUtilsLocation}" -st "" -jrt "${jenkinsReleaseType}"'
    }
  }
  dependsOn: [
    vmName_resource
  ]
}

output jenkinsURL string = 'http://${reference(publicIPAddressName).dnsSettings.fqdn}'
output SSH string = 'ssh -L 8080:localhost:8080 ${adminUsername}@${reference(publicIPAddressName).dnsSettings.fqdn}'