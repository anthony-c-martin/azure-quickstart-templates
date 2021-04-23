@description('Operating System to install')
param OS string

@allowed([
  1
  2
  3
  4
])
@description('number of VM nodes to create')
param clusterNodes int = 2

@description('the VM size for all nodes')
param vmSize string = 'Standard_A2_v2'

@description('User for the Virtual Machines.')
param adminUser string

@description('Password for the Virtual Machines.')
@secure()
param adminPassword string

@description('url of the application module to install on all nodes (optional)')
param moduleUrl string = ''

@description('name of the application module to install on all nodes (optional)')
param moduleName string = 'mirror'

@description('Public VIP dns label (optional. If set, an additionnal Standard SKU, unassociated public IP will be created)')
param VIPDnsLabel string = ''

@description('Public VM IP dns label prefix')
param VMDnsPrefix string

@allowed([
  'External'
  'none'
])
@description('loadbalancer (optional. If set, a loadbalancer will be created, with the VIP as frontend and the VMs in the backend pool.')
param Loadbalancer string = 'none'

@allowed([
  'yes'
  'no'
])
@description('install azure powershell module (optional)')
param azurePwsh string = 'no'

@description('resources location')
param location string

@description('url of safekit package')
param safekitFileUri string = ''

@description('base URL of deployment resources (template,subtemplates,scripts)')
param artifactsLocation string

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string

var allvms = [
  'VM1'
  'VM2'
  'VM3'
  'VM4'
]
var vms_var = take(allvms, clusterNodes)
var cltemplate = uri(artifactsLocation, 'nested/cluster.json')
var frontEndIPConfigName = '${VIPDnsLabel}LBFE'
var lbPoolName = '${VIPDnsLabel}BEP'
var lbProbeName = '${VIPDnsLabel}LBP'
var lbName_var = '${VIPDnsLabel}LB'
var NetworkContributor = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'
var ostype = ((OS == 'Linux CentOS') ? 'linux' : 'windows')
var adminUsername = (empty(adminUser) ? 'admin${resourceGroup().name}' : adminUser)
var ips = [
  '10.0.0.10'
  '10.0.0.11'
  '10.0.0.12'
  '10.0.0.13'
]
var sktemplate = concat(uri(artifactsLocation, 'nestedtemplates/safekitdepl.json'), artifactsLocationSasToken)
var skclustertemplate = concat(uri(artifactsLocation, 'nestedtemplates/installCluster.json'), artifactsLocationSasToken)
var createviptemplate = concat(uri(artifactsLocation, 'nestedtemplates/createvip.json'), artifactsLocationSasToken)
var skmoduletemplate = concat(uri(artifactsLocation, 'nestedtemplates/installModule.json'), artifactsLocationSasToken)
var NSGName_var = 'SafeKit-NSG'
var storageAccountName_var = '${uniqueString(resourceGroup().id, location)}stor'
var lbPoolID = ((Loadbalancer == 'none') ? '' : resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName_var, lbPoolName))
var lbaddrpool1 = [
  {
    id: lbPoolID
  }
]
var lbaddrpool0 = []
var lbaddrpool = ((length(lbPoolID) > 0) ? lbaddrpool1 : lbaddrpool0)
var WindowsStorageProfile = {
  imageReference: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: OS
    version: 'latest'
  }
  osDisk: {
    createOption: 'FromImage'
  }
}
var CentosStorageProfile = {
  imageReference: {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '7.5'
    version: 'latest'
  }
  osDisk: {
    createOption: 'fromImage'
  }
  dataDisks: []
}
var linuxConfiguration = {
  disablePasswordAuthentication: 'false'
}
var addressPrefix = '10.0.0.0/16'
var virtualNetworkName_var = '${resourceGroup().name}VNET'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2018-08-01' = {
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

module optionalVip '?' /*TODO: replace with correct path to [variables('createviptemplate')]*/ = {
  name: 'optionalVip'
  params: {
    location: location
    VIPDnsLabel: VIPDnsLabel
  }
}

resource lbName 'Microsoft.Network/loadBalancers@2018-08-01' = if ((!empty(VIPDnsLabel)) && (!(Loadbalancer == 'none'))) {
  name: lbName_var
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: frontEndIPConfigName
        properties: {
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', 'pip${VIPDnsLabel}')
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: lbPoolName
      }
    ]
    loadBalancingRules: [
      {
        name: 'LBRule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName_var, frontEndIPConfigName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName_var, lbPoolName)
          }
          protocol: 'Tcp'
          frontendPort: 9453
          backendPort: 9453
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName_var, lbProbeName)
          }
        }
      }
    ]
    probes: [
      {
        name: lbProbeName
        properties: {
          protocol: 'Http'
          port: 9010
          requestPath: '/var/modules/${moduleName}/ready.txt'
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
  dependsOn: [
    optionalVip
  ]
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2018-02-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource NSGName 'Microsoft.Network/networkSecurityGroups@2018-07-01' = {
  name: NSGName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'remoteaccess'
        properties: {
          description: 'Allow Remote Access'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: ((ostype == 'linux') ? '22' : '3389')
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'secconsole'
        properties: {
          description: 'Allow Web Console Security Access'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9001'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'webconsole'
        properties: {
          description: 'Allow Web Console Access'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9453'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource pip_vms 'Microsoft.Network/publicIPAddresses@2018-07-01' = [for item in vms_var: {
  name: 'pip${item}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: toLower(concat(VMDnsPrefix, item))
    }
  }
}]

resource nic_vms 'Microsoft.Network/networkInterfaces@2018-07-01' = [for (item, i) in vms_var: {
  name: 'nic${item}'
  location: location
  properties: {
    networkSecurityGroup: {
      id: NSGName.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: ips[i]
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses/', 'pip${item}')
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, 'Subnet')
          }
          loadBalancerBackendAddressPools: lbaddrpool
        }
      }
    ]
  }
  dependsOn: [
    lbName
    resourceId('Microsoft.Network/publicIPAddresses/', 'pip${item}')
    NSGName
    virtualNetworkName
  ]
}]

resource vms 'Microsoft.Compute/virtualMachines@2018-06-01' = [for (item, i) in vms_var: {
  name: item
  location: location
  zones: split(string(((i % 3) + 1)), ',')
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: item
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: ((ostype == 'linux') ? linuxConfiguration : '')
    }
    storageProfile: ((OS == 'Linux CentOS') ? CentosStorageProfile : WindowsStorageProfile)
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces/', 'nic${item}')
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccountName.properties.primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    storageAccountName
    resourceId('Microsoft.Network/networkInterfaces/', 'nic${item}')
  ]
}]

resource id_vms 'Microsoft.Authorization/roleAssignments@2016-07-01' = [for item in vms_var: if (azurePwsh == 'yes') {
  name: guid(resourceGroup().id, item)
  properties: {
    roleDefinitionId: NetworkContributor
    principalId: reference('Microsoft.Compute/virtualMachines/${item}', '2018-06-01', 'Full').identity.principalId
  }
  dependsOn: [
    item
  ]
}]

module safekitInstall_vms '?' /*TODO: replace with correct path to [variables('sktemplate')]*/ = [for item in vms_var: {
  name: 'safekitInstall${item}'
  params: {
    location: location
    vmname: item
    ostype: ostype
    azurePwsh: azurePwsh
    capassword: adminPassword
    safekitFileUri: safekitFileUri
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    item
  ]
}]

module safekitClusterConfig '?' /*TODO: replace with correct path to [variables('skclustertemplate')]*/ = {
  name: 'safekitClusterConfig'
  params: {
    location: location
    ostype: ostype
    vmname: vms_var[0]
    vmList: vms_var
    fqdn: reference(resourceId('Microsoft.Network/publicIPAddresses/', 'pip${vms_var[0]}')).dnsSettings.fqdn
    privateIps: ips
    VMDnsPrefix: VMDnsPrefix
    lblist: ((length(VIPDnsLabel) > 0) ? reference('optionalVip').outputs.fqdn.value : '')
    capassword: adminPassword
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    safekitInstall_vms
  ]
}

module safekitModuleConfig '?' /*TODO: replace with correct path to [variables('skmoduletemplate')]*/ = {
  name: 'safekitModuleConfig'
  params: {
    location: location
    ostype: ostype
    vmname: vms_var[0]
    moduleUrl: moduleUrl
    moduleName: moduleName
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    safekitClusterConfig
  ]
}

output adminUser string = adminUsername
output fqdn string = reference(resourceId('Microsoft.Network/publicIPAddresses/', 'pip${vms_var[0]}')).dnsSettings.fqdn
output Credentials_Url string = 'https://${reference(resourceId('Microsoft.Network/publicIPAddresses/', 'pip${vms_var[0]}')).dnsSettings.fqdn}:9001/adduser.html'
output Credentials_Url_Login string = 'user: CA_admin, password: the value of AdminPassword'
output Console_Url string = 'https://${reference(resourceId('Microsoft.Network/publicIPAddresses/', 'pip${vms_var[0]}')).dnsSettings.fqdn}:9453/deploy.html'
output Mosaic_URL string = 'https://${reference('optionalVip').outputs.fqdn.value}:9453/cgi-bin/mosaic?mode=mosaic&arg0=${moduleName}'