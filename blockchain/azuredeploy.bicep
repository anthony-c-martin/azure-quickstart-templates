param vmDnsPrefix string {
  metadata: {
    description: 'This is the unique DNS name of the for the public IP for your VM'
  }
}
param adminUsername string {
  metadata: {
    description: 'This is the the username you wish to assign to your VMs admin account'
  }
}
param blockchainSoftware string {
  allowed: [
    'bitcoin'
    'bitshares'
    'bitswift'
    'blocknet'
    'bloqenterprise'
    'dash'
    'digibyte'
    'dynamic'
    'sequence'
    'emercoin'
    'influx'
    'jumbucks'
    'monero'
    'multichain'
    'nxt'
    'okcash'
    'particl'
    'stratis'
    'syscoin'
    'vcash'
    'viacoin'
    'vechain'
  ]
  metadata: {
    description: 'The blockchain software to install on the VM'
  }
}
param vmSize string {
  metadata: {
    description: 'Size of VM'
  }
  default: 'Standard_D1_v2'
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

var nicName_var = 'VMNic'
var addressPrefix = '10.0.0.0/16'
var imagePublisher = 'Canonical'
var imageVersion = 'latest'
var imageSKU = '18.04-LTS'
var imageOffer = 'UbuntuServer'
var subnetName = 'Subnet-1'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressName_var = 'publicIP'
var publicIPAddressType = 'Dynamic'
var vmName_var = vmDnsPrefix
var virtualNetworkName_var = 'VNET'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
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
var commandToExecute = {
  emercoin: 'sh ${blockchainSoftware}.sh "${adminUsername}" "${adminPasswordOrKey}"'
  stratis: 'sh ${blockchainSoftware}.sh From_Source${adminUsername}'
  syscoin: 'sh ${blockchainSoftware}.sh From_Source${adminUsername}'
  viacoin: 'sh ${blockchainSoftware}.sh From_Source'
  bitswift: 'sh ${blockchainSoftware}.sh From_Source'
  blocknet: 'sh ${blockchainSoftware}.sh From_Source'
  influx: 'sh ${blockchainSoftware}.sh From_Source'
  bitshares: 'sh ${blockchainSoftware}.sh From_Source'
  digibyte: 'sh ${blockchainSoftware}.sh From_Source'
  vcash: 'sh ${blockchainSoftware}.sh From_Source'
  bitcoin: 'sh ${blockchainSoftware}.sh From_Source${adminUsername}'
  dash: 'sh ${blockchainSoftware}.sh From_Source${adminUsername}'
  dynamic: 'sh ${blockchainSoftware}.sh From_Source${adminUsername}'
  sequence: 'sh ${blockchainSoftware}.sh From_Source${adminUsername}'
  bloqenterprise: 'sh ${blockchainSoftware}.sh Download_Binaries'
  monero: 'sh ${blockchainSoftware}.sh Download_Binaries'
  jumbucks: 'sh ${blockchainSoftware}.sh From_Source ${adminUsername}'
  okcash: 'sh ${blockchainSoftware}.sh From_Source ${adminUsername}'
  particl: 'sh ${blockchainSoftware}.sh From_Source ${adminUsername}'
  multichain: 'sh ${blockchainSoftware}.sh ${adminUsername}'
  nxt: 'sh ${blockchainSoftware}.sh false false'
  vechain: 'sh ${blockchainSoftware}.sh main'
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: vmDnsPrefix
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2019-11-01' = {
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

resource nicName 'Microsoft.Network/networkInterfaces@2019-11-01' = {
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
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: imageVersion
      }
      osDisk: {
        name: 'osdisk1'
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

resource vmName_newuserscript 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  name: '${vmName_var}/newuserscript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'scripts/${blockchainSoftware}.sh${artifactsLocationSasToken}')
      ]
    }
    protectedSettings: {
      commandToExecute: commandToExecute[blockchainSoftware]
    }
  }
  dependsOn: [
    vmName
  ]
}