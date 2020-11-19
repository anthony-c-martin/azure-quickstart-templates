param adminVMUsername string {
  minLength: 3
  metadata: {
    description: 'User name for the Virtual Machine.'
  }
}
param dnsNameForPublicIP string {
  minLength: 3
  metadata: {
    description: 'Globally unique DNS Name for the Public IP used to access the Virtual Machine.'
  }
  default: 'oc${uniqueString(resourceGroup().id)}'
}
param smtpEmail string {
  minLength: 1
  metadata: {
    description: 'Provide SMTP Email.'
  }
}
param postgresPassword string {
  minLength: 12
  metadata: {
    description: 'Provide Password for the Postgres.'
  }
  secure: true
}
param adminLoginEmail string {
  minLength: 3
  metadata: {
    description: 'Provide Admin Email for Open Canvas.'
  }
}
param adminLoginPassword string {
  minLength: 12
  metadata: {
    description: 'Provide Admin Password for for Open Canvas.'
  }
  secure: true
}
param adminAccountName string {
  minLength: 3
  metadata: {
    description: 'Provide Admin Account Name.'
  }
}
param lms_stat_coll string {
  metadata: {
    description: 'Provide lms stat coll.'
  }
  default: 'opt_in'
}
param smtp_type string {
  minLength: 3
  metadata: {
    description: 'Provide SMTP Type.'
  }
  default: 'smtp.gmail.com'
}
param smtp_port string {
  metadata: {
    description: 'Provide SMTP Port.'
  }
  default: '465'
}
param smtp_pass string {
  minLength: 12
  metadata: {
    description: 'Provide lms SMTP Password.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located including a trailing \'/\''
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/OpenCanvas-LMS/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.'
  }
  secure: true
  default: ''
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
var nicName = 'canvasVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressType = 'Dynamic'
var vmSize = 'Standard_D2_v2'
var vmName = 'opencanvas'
var virtualNetworkName = 'canvasLMSVNET'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var installScriptName = 'opencanvas.sh'
var ubuntuOSVersion = '16.04-LTS'
var installScriptUrl = uri(artifactsLocation, concat(installScriptName, artifactsLocationSasToken))
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminVMUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}
var networkSecurityGroupName = 'default-NSG'

resource dnsNameForPublicIP_resource 'Microsoft.Network/publicIPAddresses@2018-02-01' = {
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
      {
        name: 'default-allow-80'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '80'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-443'
        properties: {
          priority: 1002
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '443'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2018-02-01' = {
  name: virtualNetworkName
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

resource nicName_resource 'Microsoft.Network/networkInterfaces@2018-02-01' = {
  name: nicName
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
  }
  dependsOn: [
    dnsNameForPublicIP_resource
    virtualNetworkName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: location
  tags: {
    displayName: 'VirtualMachine'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminVMUsername
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
        name: 'osdisk'
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

resource vmName_installopencavas 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = {
  name: '${vmName}/installopencavas'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        installScriptUrl
      ]
    }
    protectedSettings: {
      commandToExecute: 'mv *.sh /home/${adminVMUsername} && cd /home/${adminVMUsername} && sudo chmod 777 *.sh && sudo -u ${adminVMUsername} /bin/bash ${installScriptName} ${reference(dnsNameForPublicIP_resource.id, '2016-03-30').dnsSettings.fqdn} ${smtpEmail} ${postgresPassword} ${adminLoginEmail} ${adminLoginPassword} ${adminAccountName} ${lms_stat_coll} ${smtp_type} ${smtp_port} ${smtp_pass}'
    }
  }
  dependsOn: [
    vmName_resource
  ]
}