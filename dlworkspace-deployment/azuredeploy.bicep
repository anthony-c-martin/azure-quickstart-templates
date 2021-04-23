@description('Name of cluster - should be lowercase, if it is not, a lowercase version will be used.')
param clusterNameDesired string = uniqueString(resourceGroup().id)

@description('Location of resources.')
param location string = resourceGroup().location

@description('Username on machines.')
param adminUsername string

@description('Password for the virtual machines .')
@secure()
param adminPassword string

@description('Comma separated list of users allowed to log into DLWorkspace webportal as administrator and manage the cluster')
param dlwsAdmins string

@description('Array of IP prefixes of machines which can be used to connect to the dev box.')
param devSourceIP array = [
  '10.0.0.0/8'
]

@description('Number of infra-VM to deploy.')
param numberOfInfraVM int = 1

@description('Size of the infra-VM. Use a CPU VM for infra-VM.')
param infraVMSize string = 'Standard_DS2_v2'

@description('Number of worker-VM to deploy.')
param numberOfWorkerVM int = 1

@description('Size of the worker-VM. Use a GPU VM for worker-VM.')
param workerVMSize string = 'Standard_DS2_v2'

@allowed([
  ''
  'Google'
  'MSFT'
])
@description('Provider for OpenID Authentication - currently supports MSFT or Google, leave blank if not using.')
param openIDProvider string = ''

@description('Name of the web application registered with the authentication provider.')
param openIDTenant string = ''

@description('ClientID of the web application registered with the authentication provider.')
param openIDClientID string = ''

@description('Client Secret of the web application registered with the authentication provider.')
param openIDClientSecret string = ''

@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/dlworkspace-deployment/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

var clusterName = toLower(clusterNameDesired)
var standardStorageAccountType = 'Standard_LRS'
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var ubuntuOSVersion = '16.04.0-LTS'
var virtualNetworkName_var = '${resourceGroup().name}-VNet'
var subnetName = 'VMSubnet'
var addressPrefix = '192.168.0.0/16'
var scriptFileUri = uri(artifactsLocation, 'scripts/setupdevbox.sh${artifactsLocationSasToken}')
var singleQuote = '\''
var adminPasswordQ = concat(singleQuote, adminPassword, singleQuote)
var dlwsAdminsQ = concat(singleQuote, dlwsAdmins, singleQuote)
var openIDProviderQ = concat(singleQuote, openIDProvider, singleQuote)
var openIDTenantQ = concat(singleQuote, openIDTenant, singleQuote)
var openIDClientIDQ = concat(singleQuote, openIDClientID, singleQuote)
var openIDClientSecretQ = concat(singleQuote, openIDClientSecret, singleQuote)

resource clusterName_dev 'Microsoft.Compute/virtualMachines@2017-12-01' = {
  name: '${clusterName}-dev'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: infraVMSize
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
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: standardStorageAccountType
        }
      }
    }
    osProfile: {
      computerName: '${clusterName}-dev'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: clusterName_dev_VMNic.id
        }
      ]
    }
  }
}

resource clusterName_dev_setupdevbox 'Microsoft.Compute/virtualMachines/extensions@2017-12-01' = {
  parent: clusterName_dev
  name: 'setupdevbox'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        scriptFileUri
      ]
    }
    protectedSettings: {
      commandToExecute: 'bash setupdevbox.sh ${adminUsername} --cluster_name ${clusterName} --cluster_location ${location} --worker_vm_size ${workerVMSize} --infra_vm_size ${infraVMSize}  --worker_node_num ${numberOfWorkerVM} --infra_node_num ${numberOfInfraVM} --password ${adminPasswordQ} --users ${dlwsAdminsQ} --openid_name ${openIDProviderQ} --openid_tenant ${openIDTenantQ} --openid_clientid ${openIDClientIDQ} --openid_clientsecret ${openIDClientSecretQ}'
    }
  }
}

resource clusterName_infra0_1 'Microsoft.Compute/virtualMachines@2017-12-01' = [for i in range(0, numberOfInfraVM): {
  name: '${clusterName}-infra0${(i + 1)}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: infraVMSize
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
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: standardStorageAccountType
        }
      }
    }
    osProfile: {
      computerName: '${clusterName}-infra0${(i + 1)}'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${clusterName}-infra0${(i + 1)}-VMNic')
        }
      ]
    }
  }
  dependsOn: [
    resourceId('Microsoft.Network/networkInterfaces', '${clusterName}-infra0${(i + 1)}-VMNic')
  ]
}]

resource clusterName_worker0_1 'Microsoft.Compute/virtualMachines@2017-12-01' = [for i in range(0, numberOfWorkerVM): {
  name: '${clusterName}-worker0${(i + 1)}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: workerVMSize
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
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: standardStorageAccountType
        }
      }
    }
    osProfile: {
      computerName: '${clusterName}-worker0${(i + 1)}'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${clusterName}-worker0${(i + 1)}-VMNic')
        }
      ]
    }
  }
  dependsOn: [
    resourceId('Microsoft.Network/networkInterfaces', '${clusterName}-worker0${(i + 1)}-VMNic')
  ]
}]

resource clusterName_dev_PublicIP 'Microsoft.Network/publicIPAddresses@2018-02-01' = {
  sku: {
    name: 'Basic'
  }
  name: '${clusterName}-dev-PublicIP'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower('${clusterName}-dev')
    }
  }
}

resource clusterName_infra0_1_PublicIP 'Microsoft.Network/publicIPAddresses@2018-02-01' = [for i in range(0, numberOfInfraVM): {
  sku: {
    name: 'Basic'
  }
  name: '${clusterName}-infra0${(i + 1)}-PublicIP'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower('${clusterName}-infra0${(i + 1)}')
    }
  }
}]

resource clusterName_worker0_1_PublicIP 'Microsoft.Network/publicIPAddresses@2018-02-01' = [for i in range(0, numberOfWorkerVM): {
  sku: {
    name: 'Basic'
  }
  name: '${clusterName}-worker0${(i + 1)}-PublicIP'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower('${clusterName}-worker0${(i + 1)}')
    }
  }
}]

resource clusterName_dev_VMNic 'Microsoft.Network/networkInterfaces@2018-02-01' = {
  name: '${clusterName}-dev-VMNic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${clusterName}-dev-IPConfig'
        properties: {
          privateIPAddress: '192.168.255.${(numberOfInfraVM + 1)}'
          privateIPAllocationMethod: 'Static'
          privateIPAddressVersion: 'IPv4'
          publicIPAddress: {
            id: clusterName_dev_PublicIP.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: clusterName_NSG.id
    }
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource clusterName_infra0_1_VMNic 'Microsoft.Network/networkInterfaces@2018-02-01' = [for i in range(0, numberOfInfraVM): {
  name: '${clusterName}-infra0${(i + 1)}-VMNic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${clusterName}-infra0${(i + 1)}-IPConfig'
        properties: {
          privateIPAddress: '192.168.255.${(i + 1)}'
          privateIPAllocationMethod: 'Static'
          privateIPAddressVersion: 'IPv4'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', '${clusterName}-infra0${(i + 1)}-PublicIP')
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: clusterName_NSG.id
    }
  }
  dependsOn: [
    resourceId('Microsoft.Network/publicIPAddresses', '${clusterName}-infra0${(i + 1)}-PublicIP')
    virtualNetworkName
    clusterName_NSG
  ]
}]

resource clusterName_worker0_1_VMNic 'Microsoft.Network/networkInterfaces@2018-02-01' = [for i in range(0, numberOfWorkerVM): {
  name: '${clusterName}-worker0${(i + 1)}-VMNic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${clusterName}-worker0${(i + 1)}-IPConfig'
        properties: {
          privateIPAddress: '192.168.1.${(i + 1)}'
          privateIPAllocationMethod: 'Static'
          privateIPAddressVersion: 'IPv4'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', '${clusterName}-worker0${(i + 1)}-PublicIP')
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: clusterName_NSG.id
    }
  }
  dependsOn: [
    resourceId('Microsoft.Network/publicIPAddresses', '${clusterName}-worker0${(i + 1)}-PublicIP')
    virtualNetworkName
    clusterName_NSG
  ]
}]

resource clusterName_NSG 'Microsoft.Network/networkSecurityGroups@2018-02-01' = {
  name: '${clusterName}-NSG'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allowalltcp'
        properties: {
          protocol: 'Tcp'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRanges: [
            '80'
            '443'
            '30000-32767'
            '25826'
            '3080'
          ]
        }
      }
      {
        name: 'allowalludp'
        properties: {
          protocol: 'Udp'
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '25826'
        }
      }
      {
        name: 'allowdevtcp'
        properties: {
          protocol: 'Tcp'
          access: 'Allow'
          priority: 900
          direction: 'Inbound'
          sourceAddressPrefixes: devSourceIP
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRanges: [
            '22'
            '1443'
            '2379'
            '3306'
            '5000'
            '8086'
          ]
        }
      }
    ]
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2018-02-01' = {
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
          addressPrefix: addressPrefix
        }
      }
    ]
  }
}

output devmachine string = reference('${clusterName}-dev-PublicIP').dnsSettings.fqdn
output webportal string = reference('${clusterName}-infra01-PublicIP').dnsSettings.fqdn