@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-perforce-helix-core-server/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

@description('The location where these resources will be deployed.')
param location string = resourceGroup().location

@allowed([
  'Ubuntu 18.04 LTS'
  'CentOS 7.x'
  'RHEL 7.x'
])
@description('The operating system of the VM.')
param OS string = 'CentOS 7.x'

@description('Please select the size of the VM you wish to deploy.  Read more about sizing options here: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes-general. Compute optimized instances recommended for production use, e.g. Fsv2 series')
param VMSize string = 'Standard_B2s'

@minValue(10)
@maxValue(2048)
@description('Please select the size of the data disk you wish to deploy (value is integer GB) to hold your metadata, logs and depot (archive files). This can be any value up to 2TB (2048 GB).')
param dataDiskSize int = 50

@description('P4PORT value to connect to server (via ssl)')
param p4Port int = 1666

@description('Port for Swarm (Apache) to be setup on.')
param swarmPort int = 80

@description('Admin username for Virtual Machine')
param adminUsername string

@description('SSH Public Key for the Virtual Machine.')
@secure()
param adminSSHPubKey string

@description('CIDR block for SSH source - limit to your IP for secure access.')
param source_CIDR string = '*'

@description('Helix Core Server superuser password (user perforce).')
@secure()
param helix_admin_password string

var virtualNetworkName_var = 'HXVNET'
var NSGName_var = 'HXNSG'
var publicIPAddressType = 'Dynamic'
var addressPrefix = '10.166.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.166.6.0/24'
var numberOfInstances = 1
var linuxscripturi = uri(artifactsLocation, 'scripts/configure-linux.sh${artifactsLocationSasToken}')
var virtualMachineSize = VMSize
var imageReference = {
  'Ubuntu 18.04 LTS': {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '18.04-LTS'
    version: 'latest'
  }
  'CentOS 7.x': {
    publisher: 'OpenLogic'
    offer: 'CentOS-LVM'
    sku: '7-LVM'
    version: 'latest'
  }
  'RHEL 7.x': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '7-LVM'
    version: 'latest'
  }
}
var dataDiskSize_var = dataDiskSize
var publicIpName = substring(uniqueString(resourceGroup().id), 0, 6)
var LinuxScriptParameters = ' -w \'${helix_admin_password}\' -p \'${p4Port}\' -s \'${swarmPort}\''
var LiCmdWrapper = 'bash ./configure-linux.sh ${LinuxScriptParameters}'
var LinuxsecurityRules = [
  {
    name: 'ssh-rule'
    properties: {
      description: 'Allow SSH'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '22'
      sourceAddressPrefix: source_CIDR
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 100
      direction: 'Inbound'
    }
  }
  {
    name: 'web-rule'
    properties: {
      description: 'Allow WEB'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: swarmPort
      sourceAddressPrefix: 'Internet'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 102
      direction: 'Inbound'
    }
  }
  {
    name: 'p4d-rule'
    properties: {
      description: 'Allow WEB'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: p4Port
      sourceAddressPrefix: 'Internet'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 103
      direction: 'Inbound'
    }
  }
]
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminSSHPubKey
      }
    ]
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2019-04-01' = {
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
            id: NSGName.id
          }
        }
      }
    ]
  }
}

resource NSGName 'Microsoft.Network/networkSecurityGroups@2019-04-01' = {
  name: NSGName_var
  location: location
  tags: {
    displayName: NSGName_var
  }
  properties: {
    securityRules: LinuxsecurityRules
  }
}

resource hxpip_1 'Microsoft.Network/publicIPAddresses@2019-04-01' = [for i in range(0, numberOfInstances): {
  name: 'hxpip${(i + 1)}'
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: 'a${publicIpName}${(i + 1)}'
    }
  }
  dependsOn: [
    virtualNetworkName
  ]
}]

resource hxnic_1 'Microsoft.Network/networkInterfaces@2019-04-01' = [for i in range(0, numberOfInstances): {
  name: 'hxnic${(i + 1)}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses/', 'hxpip${(i + 1)}')
          }
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnet1Name)
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
    resourceId('Microsoft.Network/publicIPAddresses', 'hxpip${(i + 1)}')
  ]
}]

resource helixcore_1 'Microsoft.Compute/virtualMachines@2019-07-01' = [for i in range(0, numberOfInstances): {
  name: 'helixcore${(i + 1)}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    osProfile: {
      computerName: 'helixcorevm${(i + 1)}'
      adminUsername: adminUsername
      linuxConfiguration: linuxConfiguration
    }
    storageProfile: {
      imageReference: imageReference[OS]
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          diskSizeGB: dataDiskSize_var
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'hxnic${(i + 1)}')
        }
      ]
    }
  }
  dependsOn: [
    hxnic_1
  ]
}]

resource helixcore_1_CustomScript 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = [for i in range(0, numberOfInstances): {
  name: 'helixcore${(i + 1)}/CustomScript'
  location: location
  tags: {
    displayName: 'linuxappdeploy'
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      skipDos2Unix: false
      timestamp: 123456789
    }
    protectedSettings: {
      commandToExecute: LiCmdWrapper
      fileUris: [
        linuxscripturi
      ]
    }
  }
  dependsOn: [
    resourceId('Microsoft.Compute/virtualMachines', 'helixcore${(i + 1)}')
  ]
}]