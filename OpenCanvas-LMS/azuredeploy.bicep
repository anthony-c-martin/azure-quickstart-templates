@minLength(3)
@description('User name for the Virtual Machine.')
param adminVMUsername string

@minLength(3)
@description('Globally unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsNameForPublicIP string = 'oc${uniqueString(resourceGroup().id)}'

@minLength(1)
@description('Provide SMTP Email.')
param smtpEmail string

@minLength(12)
@description('Provide Password for the Postgres.')
@secure()
param postgresPassword string

@minLength(3)
@description('Provide Admin Email for Open Canvas.')
param adminLoginEmail string

@minLength(12)
@description('Provide Admin Password for for Open Canvas.')
@secure()
param adminLoginPassword string

@minLength(3)
@description('Provide Admin Account Name.')
param adminAccountName string

@description('Provide lms stat coll.')
param lms_stat_coll string = 'opt_in'

@minLength(3)
@description('Provide SMTP Type.')
param smtp_type string = 'smtp.gmail.com'

@description('Provide SMTP Port.')
param smtp_port string = '465'

@minLength(12)
@description('Provide lms SMTP Password.')
param smtp_pass string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/OpenCanvas-LMS/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var nicName_var = 'canvasVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressType = 'Dynamic'
var vmSize = 'Standard_D2_v2'
var vmName_var = 'opencanvas'
var virtualNetworkName_var = 'canvasLMSVNET'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
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
var networkSecurityGroupName_var = 'default-NSG'

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

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName_var
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

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2018-02-01' = {
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
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2018-02-01' = {
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
          id: nicName.id
        }
      ]
    }
  }
}

resource vmName_installopencavas 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = {
  parent: vmName
  name: 'installopencavas'
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
}