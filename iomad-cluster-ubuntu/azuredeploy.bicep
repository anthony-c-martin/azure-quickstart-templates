@description('User name for the Virtual Machine administrator. Do not use simple names such as \'admin\'.')
param adminUsername string

@description('Password for the MySQL \'root\' admin user.')
@secure()
param mySqlPassword string

@description('Full name of the IOMAD site displayed in the UI.')
param fullNameOfSite string

@description('Short name of the IOMAD site.')
param shortNameOfSite string

@description('User name for the IOMAD site administrator.')
param iomadAdminUsername string

@description('Password for the IOMAD site administrator.')
@secure()
param iomadAdminPassword string

@description('Email for the IOMAD site administrator. It should be in the correct email address format such as: abc@xyz.com')
param iomadAdminEmail string

@description('Unique name that will be used to generate various other names including the name of the Public IP used to access the Virtual Machine.')
param uniqueNamePrefix string

@allowed([
  1
  2
  3
  4
  5
])
@description('Number of web front end VMs to create.')
param webVMCount int = 2

@description('The size of each web front end VM.')
param vmSize string = 'Standard_D2_v2'

@description('The size of the database backend VM.')
param vmSizeDB string = 'Standard_D2_v2'

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

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/iomad-cluster-ubuntu/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var newStorageAccountName_var = '${uniqueString(resourceGroup().id)}iomad'
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var ubuntuOSVersion = '14.04.5-LTS'
var nicName_var = '${uniqueNamePrefix}Nic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var subnetNameDB = 'SubnetDB'
var subnetPrefixDB = '10.0.1.0/24'
var storageAccountType = 'Standard_LRS'
var publicIPAddressName_var = '${uniqueNamePrefix}IP'
var publicDBIPAddressName_var = '${uniqueNamePrefix}DBIP'
var publicIPAddressType = 'Dynamic'
var vmName_var = '${uniqueNamePrefix}VM'
var virtualNetworkName_var = '${uniqueNamePrefix}VNet'
var availabilitySetName_var = '${uniqueNamePrefix}AvSet'
var lbName_var = '${uniqueNamePrefix}LB'
var SharedAzureFileName = 'iomadfileshare'
var installFrontendScriptName = 'install_frontend.sh'
var installFrontendScriptUri = uri(artifactsLocation, concat(installFrontendScriptName, artifactsLocationSasToken))
var installFrontendCommand = 'sh ${installFrontendScriptName} ${mySqlPassword} ${newStorageAccountName_var} ${SharedAzureFileName}'
var installBackendScriptName = 'install_backend.sh'
var installBackendScriptUri = uri(artifactsLocation, concat(installBackendScriptName, artifactsLocationSasToken))
var installBackendCommand = 'sh ${installBackendScriptName} ${mySqlPassword} ${newStorageAccountName_var} ${SharedAzureFileName}'
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

resource newStorageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: newStorageAccountName_var
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource availabilitySetName 'Microsoft.Compute/availabilitySets@2019-12-01' = {
  name: availabilitySetName_var
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: uniqueNamePrefix
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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
      {
        name: subnetNameDB
        properties: {
          addressPrefix: subnetPrefixDB
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, webVMCount): {
  name: concat(nicName_var, i)
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
          }
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName_var, 'LoadBalancerBackend')
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', lbName_var, 'Web-VM${i}')
            }
            {
              id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', lbName_var, 'SSH-VM${i}')
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
    lbName
  ]
}]

resource lbName 'Microsoft.Network/loadBalancers@2020-05-01' = {
  name: lbName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontend'
        properties: {
          publicIPAddress: {
            id: publicIPAddressName.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'LoadBalancerBackend'
      }
    ]
    inboundNatRules: [
      {
        name: 'Web-VM0'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName_var, 'loadBalancerFrontend')
          }
          protocol: 'Tcp'
          frontendPort: 8080
          backendPort: 8080
          enableFloatingIP: false
        }
      }
      {
        name: 'SSH-VM0'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName_var, 'loadBalancerFrontend')
          }
          protocol: 'Tcp'
          frontendPort: 2200
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: 'Web-VM1'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName_var, 'loadBalancerFrontend')
          }
          protocol: 'Tcp'
          frontendPort: 8081
          backendPort: 8080
          enableFloatingIP: false
        }
      }
      {
        name: 'SSH-VM1'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName_var, 'loadBalancerFrontend')
          }
          protocol: 'Tcp'
          frontendPort: 2201
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: 'Web-VM2'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName_var, 'loadBalancerFrontend')
          }
          protocol: 'Tcp'
          frontendPort: 8082
          backendPort: 8080
          enableFloatingIP: false
        }
      }
      {
        name: 'SSH-VM2'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName_var, 'loadBalancerFrontend')
          }
          protocol: 'Tcp'
          frontendPort: 2202
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: 'Web-VM3'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName_var, 'loadBalancerFrontend')
          }
          protocol: 'Tcp'
          frontendPort: 8083
          backendPort: 8080
          enableFloatingIP: false
        }
      }
      {
        name: 'SSH-VM3'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName_var, 'loadBalancerFrontend')
          }
          protocol: 'Tcp'
          frontendPort: 2203
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: 'Web-VM4'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName_var, 'loadBalancerFrontend')
          }
          protocol: 'Tcp'
          frontendPort: 8084
          backendPort: 8080
          enableFloatingIP: false
        }
      }
      {
        name: 'SSH-VM4'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName_var, 'loadBalancerFrontend')
          }
          protocol: 'Tcp'
          frontendPort: 2204
          backendPort: 22
          enableFloatingIP: false
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'LBRule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName_var, 'loadBalancerFrontend')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName_var, 'LoadBalancerBackend')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          loadDistribution: 'SourceIP'
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName_var, 'tcpProbe')
          }
        }
      }
    ]
    probes: [
      {
        name: 'tcpProbe'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: '5'
          numberOfProbes: '2'
        }
      }
    ]
  }
}

resource vmName 'Microsoft.Compute/virtualMachines@2019-12-01' = [for i in range(0, webVMCount): {
  name: concat(vmName_var, i)
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetName.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(vmName_var, i)
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
        name: '${vmName_var}${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(nicName_var, i))
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccountName
    resourceId('Microsoft.Network/networkInterfaces/', concat(nicName_var, i))
    availabilitySetName
    vmName_db_newuserscript
  ]
}]

resource vmName_newuserscript 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = [for i in range(0, webVMCount): {
  name: '${vmName_var}${i}/newuserscript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        installFrontendScriptUri
      ]
    }
    protectedSettings: {
      commandToExecute: '${installFrontendCommand} ${listKeys(newStorageAccountName.id, '2016-01-01').keys[0].value} ${reference(publicIPAddressName.id, '2015-06-15').dnsSettings.fqdn} ${reference(publicDBIPAddressName.id, '2015-06-15').dnsSettings.fqdn} ${fullNameOfSite} ${shortNameOfSite} ${iomadAdminUsername} ${iomadAdminPassword} ${iomadAdminEmail}'
    }
  }
  dependsOn: [
    resourceId('Microsoft.Compute/virtualMachines/', concat(vmName_var, i))
  ]
}]

resource availabilitySetName_db 'Microsoft.Compute/availabilitySets@2019-12-01' = {
  name: '${availabilitySetName_var}db'
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
}

resource publicDBIPAddressName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicDBIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: '${uniqueNamePrefix}db'
    }
  }
}

resource nicName_db 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: '${nicName_var}db'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfigdb'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicDBIPAddressName.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetNameDB)
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource vmName_db 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: '${vmName_var}db'
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetName_db.id
    }
    hardwareProfile: {
      vmSize: vmSizeDB
    }
    osProfile: {
      computerName: '${vmName_var}db'
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
        name: '${vmName_var}db_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName_db.id
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccountName
  ]
}

resource vmName_db_newuserscript 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  parent: vmName_db
  name: 'newuserscript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        installBackendScriptUri
      ]
    }
    protectedSettings: {
      commandToExecute: '${installBackendCommand} ${listKeys(newStorageAccountName.id, '2016-01-01').keys[0].value}'
    }
  }
}