@description('Unique DNS Name for the Storage Account where the Virtual Machine\'s disks will be placed.')
param dnsName string

@description('Prefix Name for the Virtual Machine.')
param vmNamePrefix string = 'php'

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Size for the reversed proxy nginx and PHP Virtual Machine.')
param vmSize string = 'Standard_A4_v2'

@description('Size for the postgresql Virtual Machine.')
param postgresqlvmSize string = 'Standard_A4_v2'

@allowed([
  '11.0'
  '10.3'
])
@description('The FreeBSD version for the VM. This will pick a fully patched image of this given FreeBSD version.')
param freeBSDOSVersion string = '11.0'

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/php_pgsql-freebsd-setup/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@maxValue(64)
@description('Number of attached data disk')
param numberOfDataDisks int = 8

@maxValue(1023)
@description('Size of attached data disk')
param sizeOfDataDisksInGB int = 30

@allowed([
  'None'
  'ReadOnly'
  'ReadWrite'
])
@description('Caching type of data disk')
param diskCaching string = 'ReadWrite'

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var vmNames_var = [
  '${vmNamePrefix}-frontend'
  '${vmNamePrefix}-php1'
  '${vmNamePrefix}-php2'
]
var vmNameSql_var = '${vmNamePrefix}-postgresql'
var imagePublisher = 'MicrosoftOSTC'
var imageOffer = 'FreeBSD'
var nicConfig = [
  {
    name: '${vmNames_var[0]}nic1'
    subnetRef: subnet1Ref
  }
  {
    name: '${vmNames_var[0]}nic2'
    subnetRef: subnet2Ref
  }
  {
    name: '${vmNames_var[1]}nic1'
    subnetRef: subnet2Ref
  }
  {
    name: '${vmNames_var[1]}nic2'
    subnetRef: subnet3Ref
  }
  {
    name: '${vmNames_var[2]}nic1'
    subnetRef: subnet2Ref
  }
  {
    name: '${vmNames_var[2]}nic2'
    subnetRef: subnet3Ref
  }
]
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var subnet2Name = 'Subnet-2'
var subnet2Prefix = '10.0.1.0/24'
var subnet3Name = 'Subnet-3'
var subnet3Prefix = '10.0.2.0/24'
var publicIPAddressName_var = '${uniqueString(vmNamePrefix)}publicip'
var publicIPAddressType = 'Dynamic'
var virtualNetworkName_var = '${vmNamePrefix}-vnet'
var subnet1Ref = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnet1Name)
var subnet2Ref = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnet2Name)
var subnet3Ref = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnet3Name)
var publicIPAddressId = {
  id: publicIPAddressName.id
}
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

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2019-06-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsName
    }
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
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2Prefix
        }
      }
      {
        name: subnet3Name
        properties: {
          addressPrefix: subnet3Prefix
        }
      }
    ]
  }
}

resource nicConfig_name 'Microsoft.Network/networkInterfaces@2019-06-01' = [for i in range(0, 6): {
  name: nicConfig[i].name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: ((i == 0) ? publicIPAddressId : json('null'))
          subnet: {
            id: nicConfig[i].subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName
    virtualNetworkName
  ]
}]

resource vmNameSql 'Microsoft.Network/networkInterfaces@2019-06-01' = {
  name: vmNameSql_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet3Ref
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName
    virtualNetworkName
  ]
}

resource vmNames 'Microsoft.Compute/virtualMachines@2019-07-01' = [for i in range(0, 3): {
  name: vmNames_var[i]
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmNames_var[i]
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: freeBSDOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', nicConfig[(i * 2)].name)
          properties: {
            primary: true
          }
        }
        {
          id: resourceId('Microsoft.Network/networkInterfaces', nicConfig[((i * 2) + 1)].name)
          properties: {
            primary: false
          }
        }
      ]
    }
  }
  dependsOn: [
    nicConfig_name
  ]
}]

resource Microsoft_Compute_virtualMachines_vmNameSql 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vmNameSql_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: postgresqlvmSize
    }
    osProfile: {
      computerName: vmNameSql_var
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: freeBSDOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [for j in range(0, numberOfDataDisks): {
        diskSizeGB: sizeOfDataDisksInGB
        lun: j
        caching: diskCaching
        createOption: 'Empty'
      }]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNameSql.id
        }
      ]
    }
  }
  dependsOn: [
    nicConfig_name
  ]
}

resource vmNames_installnginx 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = [for i in range(0, 3): {
  name: '${vmNames_var[i]}/installnginx'
  location: location
  properties: {
    publisher: 'Microsoft.OSTCExtensions'
    type: 'CustomScriptForLinux'
    typeHandlerVersion: '1.4'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'scripts/install_reverse_nginx.sh${artifactsLocationSasToken}')
        uri(artifactsLocation, 'scripts/install_nginx_php.sh${artifactsLocationSasToken}')
        uri(artifactsLocation, 'conf/frontend_nginx.conf${artifactsLocationSasToken}')
        uri(artifactsLocation, 'conf/frontend_proxy.conf${artifactsLocationSasToken}')
        uri(artifactsLocation, 'conf/backend_nginx.conf${artifactsLocationSasToken}')
      ]
    }
    protectedSettings: {
      commandToExecute: ((i == 0) ? 'sh install_reverse_nginx.sh ${reference(nicConfig[0].name).ipConfigurations[0].properties.privateIPAddress} ${reference(nicConfig[2].name).ipConfigurations[0].properties.privateIPAddress} ${reference(nicConfig[4].name).ipConfigurations[0].properties.privateIPAddress}' : 'sh install_nginx_php.sh')
    }
  }
  dependsOn: [
    vmNames
  ]
}]

resource vmNameSql_installpostgresql 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  parent: Microsoft_Compute_virtualMachines_vmNameSql
  name: 'installpostgresql'
  location: location
  properties: {
    publisher: 'Microsoft.OSTCExtensions'
    type: 'CustomScriptForLinux'
    typeHandlerVersion: '1.4'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'conf/postgresql.conf${artifactsLocationSasToken}')
        uri(artifactsLocation, 'scripts/install_postgresql.sh${artifactsLocationSasToken}')
        uri(artifactsLocation, 'conf/pgbouncer.ini${artifactsLocationSasToken}')
      ]
    }
    protectedSettings: {
      commandToExecute: 'sh install_postgresql.sh ${numberOfDataDisks}'
    }
  }
  dependsOn: [
    vmNameSql_var
  ]
}