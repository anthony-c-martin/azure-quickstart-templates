@description('User name for the Virtual Machine.')
param adminUsername string

@description('Password for the MySQL admin user.')
@secure()
param mySqlPassword string

@description('Unique name that will be used to generate various other names including the name of the Public IP used to access the Virtual Machine.')
param namePrefix string

@allowed([
  1
  2
  3
  4
  5
])
@description('Number of web front end VMs to create.')
param webVMCount int = 2

@allowed([
  'Standard_A0'
  'Standard_A1'
  'Standard_A2'
  'Standard_A3'
  'Standard_A4'
  'Standard_A5'
  'Standard_A6'
  'Standard_A7'
  'Standard_A8'
  'Standard_A9'
  'Standard_A10'
  'Standard_A11'
  'Standard_D1'
  'Standard_D2'
  'Standard_D3'
  'Standard_D4'
  'Standard_D11'
  'Standard_D12'
  'Standard_D13'
  'Standard_D14'
])
@description('The size of each web front end VM.')
param vmSize string = 'Standard_A0'

@allowed([
  'Standard_A0'
  'Standard_A1'
  'Standard_A2'
  'Standard_A3'
  'Standard_A4'
  'Standard_A5'
  'Standard_A6'
  'Standard_A7'
  'Standard_A8'
  'Standard_A9'
  'Standard_A10'
  'Standard_A11'
  'Standard_D1'
  'Standard_D2'
  'Standard_D3'
  'Standard_D4'
  'Standard_D11'
  'Standard_D12'
  'Standard_D13'
  'Standard_D14'
])
@description('The size of the database backend VM.')
param vmSizeDB string = 'Standard_A0'

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

var storageAccountName_var = '${uniqueString(resourceGroup().id)}storage'
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var ubuntuOSVersion = '14.04.5-LTS'
var OSDiskName = '${namePrefix}Disk'
var nicName_var = '${namePrefix}Nic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var subnetNameDB = 'SubnetDB'
var subnetPrefixDB = '10.0.1.0/24'
var storageAccountType = 'Standard_LRS'
var publicIPAddressName_var = '${namePrefix}IP'
var publicDBIPAddressName_var = '${namePrefix}DBIP'
var publicIPAddressID = publicIPAddressName.id
var publicIPAddressType = 'Dynamic'
var vmStorageAccountContainerName = 'vhds'
var vmName_var = '${namePrefix}VM'
var virtualNetworkName_var = '${namePrefix}VNet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var subnetRefDB = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetNameDB)
var availabilitySetName_var = '${namePrefix}AvSet'
var lbName_var = '${namePrefix}LB'
var lbID = lbName.id
var frontEndIPConfigID = '${lbID}/frontendIPConfigurations/loadBalancerFrontend'
var lbProbeID = '${lbID}/probes/tcpProbe'
var lbPoolID = '${lbID}/backendAddressPools/LoadBalancerBackend'
var installFrontendScriptName = 'install_frontend.sh'
var installFrontendScriptUri = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/opensis-cluster-ubuntu/${installFrontendScriptName}'
var installFrontendCommand = 'sh ${installFrontendScriptName} ${mySqlPassword}'
var installBackendScriptName = 'install_backend.sh'
var installBackendScriptUri = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/opensis-cluster-ubuntu/${installBackendScriptName}'
var installBackendCommand = 'sh ${installBackendScriptName} ${mySqlPassword}'
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

resource storageAccountName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageAccountName_var
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource availabilitySetName 'Microsoft.Compute/availabilitySets@2017-12-01' = {
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

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: namePrefix
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
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

resource nicName 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, webVMCount): {
  name: concat(nicName_var, i)
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
          loadBalancerBackendAddressPools: [
            {
              id: '${lbID}/backendAddressPools/LoadBalancerBackend'
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: '${lbID}/inboundNatRules/Web-VM${i}'
            }
            {
              id: '${lbID}/inboundNatRules/SSH-VM${i}'
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

resource lbName 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: lbName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontend'
        properties: {
          publicIPAddress: {
            id: publicIPAddressID
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
            id: frontEndIPConfigID
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
            id: frontEndIPConfigID
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
            id: frontEndIPConfigID
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
            id: frontEndIPConfigID
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
            id: frontEndIPConfigID
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
            id: frontEndIPConfigID
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
            id: frontEndIPConfigID
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
            id: frontEndIPConfigID
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
            id: frontEndIPConfigID
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
            id: frontEndIPConfigID
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
            id: frontEndIPConfigID
          }
          backendAddressPool: {
            id: lbPoolID
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          loadDistribution: 'SourceIP'
          probe: {
            id: lbProbeID
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

resource vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, webVMCount): {
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
    storageAccountName
    'Microsoft.Network/networkInterfaces/${nicName_var}${i}'
    availabilitySetName
  ]
}]

resource vmName_newuserscript 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for i in range(0, webVMCount): {
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
      commandToExecute: installFrontendCommand
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${vmName_var}${i}'
  ]
}]

resource availabilitySetName_db 'Microsoft.Compute/availabilitySets@2017-12-01' = {
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

resource publicDBIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicDBIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: '${namePrefix}db'
    }
  }
}

resource nicName_db 'Microsoft.Network/networkInterfaces@2015-06-15' = {
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
            id: subnetRefDB
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource vmName_db 'Microsoft.Compute/virtualMachines@2017-03-30' = {
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
    storageAccountName
    'Microsoft.Network/networkInterfaces/${nicName_var}db'
    'Microsoft.Compute/availabilitySets/${availabilitySetName_var}db'
  ]
}

resource vmName_db_newuserscript 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
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
      commandToExecute: installBackendCommand
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${vmName_var}db'
  ]
}