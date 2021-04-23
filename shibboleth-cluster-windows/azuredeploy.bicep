@description('User name for the Virtual Machine administrator. Do not use simple names such as \'admin\'.')
param adminUsername string

@description('Password for the Virtual Machine administrator.')
@secure()
param adminPassword string

@description('Unique name that will be used to generate various other names including the name of the Public IP used to access the Virtual Machine.')
param uniqueNamePrefix string

@allowed([
  '2008-R2-SP1'
  '2012-Datacenter'
  '2012-R2-Datacenter'
])
@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version. Allowed values: 2008-R2-SP1, 2012-Datacenter, 2012-R2-Datacenter.')
param windowsOSVersion string = '2012-R2-Datacenter'

@description('Password for the MySQL \'root\' admin user.')
@secure()
param mySqlPasswordForRootUser string

@description('User name that will be used to create user in MySQL database which has all privileges.')
param mySqlIdpUser string

@description('Password for the MySQL Idp user.')
@secure()
param mySqlPasswordForIdpUser string

@allowed([
  1
  2
  3
  4
  5
])
@description('Number of web front end VMs to create.')
param vmCountFrontend int = 2

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
@description('The size of the VM.')
param vmSizeFrontend string = 'Standard_D11'

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

var newStorageAccountName_var = '${uniqueString(resourceGroup().id)}shc'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var OSVersion = windowsOSVersion
var OSDiskName = '${uniqueNamePrefix}Disk'
var nicName_var = '${uniqueNamePrefix}Nic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var subnetNameDB = 'SubnetDB'
var subnetPrefixDB = '10.0.1.0/24'
var storageAccountType = 'Standard_LRS'
var publicIPAddressName_var = '${uniqueNamePrefix}IP'
var publicDBIPAddressName_var = '${uniqueNamePrefix}DBIP'
var publicIPAddressID = publicIPAddressName.id
var publicIPAddressType = 'Dynamic'
var vmStorageAccountContainerName = 'vhds'
var vmName_var = '${uniqueNamePrefix}VM'
var virtualNetworkName_var = '${uniqueNamePrefix}VNet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var subnetRefDB = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetNameDB)
var availabilitySetName_var = '${uniqueNamePrefix}AvSet'
var lbName_var = '${uniqueNamePrefix}LB'
var lbID = lbName.id
var frontEndIPConfigID = '${lbID}/frontendIPConfigurations/loadBalancerFrontend'
var lbProbeID = '${lbID}/probes/tcpProbe'
var lbPoolID = '${lbID}/backendAddressPools/LoadBalancerBackend'
var installScriptName = 'install_shibboleth_idp.ps1'
var installScriptUri = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/shibboleth-cluster-windows/${installScriptName}'
var installCommand = 'powershell.exe -File ${installScriptName} ${uniqueNamePrefix} ${location} ${uniqueNamePrefix}db ${mySqlIdpUser} "${mySqlPasswordForIdpUser}"'
var installBackendScriptName = 'install_backend.ps1'
var installBackendScriptUri = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/shibboleth-cluster-windows/${installBackendScriptName}'
var installBackendCommand = 'powershell.exe -File ${installBackendScriptName} "${mySqlPasswordForRootUser}" ${mySqlIdpUser} "${mySqlPasswordForIdpUser}"'

resource newStorageAccountName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: newStorageAccountName_var
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
      domainNameLabel: uniqueNamePrefix
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
          networkSecurityGroup: {
            id: virtualNetworkName_sg.id
          }
        }
      }
    ]
  }
  dependsOn: [
    'Microsoft.Network/networkSecurityGroups/${virtualNetworkName_var}-sg'
  ]
}

resource nicName 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, vmCountFrontend): {
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
          frontendPort: 8443
          backendPort: 8443
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
          port: 8443
          intervalInSeconds: '5'
          numberOfProbes: '2'
        }
      }
    ]
  }
}

resource vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, vmCountFrontend): {
  name: concat(vmName_var, i)
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetName.id
    }
    hardwareProfile: {
      vmSize: vmSizeFrontend
    }
    osProfile: {
      computerName: concat(vmName_var, i)
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: OSVersion
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
    'Microsoft.Network/networkInterfaces/${nicName_var}${i}'
    availabilitySetName
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
      domainNameLabel: '${uniqueNamePrefix}db'
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
          networkSecurityGroup: {
            id: virtualNetworkName_sg.id
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
    'Microsoft.Network/networkSecurityGroups/${virtualNetworkName_var}-sg'
  ]
}

resource virtualNetworkName_sg 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: '${virtualNetworkName_var}-sg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'MySQL'
        properties: {
          description: 'Allows MySQL traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3306'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1101
          direction: 'Inbound'
        }
      }
      {
        name: 'RDPTCP'
        properties: {
          description: 'Allows RDP traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1301
          direction: 'Inbound'
        }
      }
      {
        name: 'RDPUDP'
        properties: {
          description: 'Allows RDP traffic'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1401
          direction: 'Inbound'
        }
      }
      {
        name: 'SSH'
        properties: {
          description: 'Allows SSH traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1201
          direction: 'Inbound'
        }
      }
    ]
  }
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
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: OSVersion
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
    'Microsoft.Network/networkInterfaces/${nicName_var}db'
    'Microsoft.Compute/availabilitySets/${availabilitySetName_var}db'
  ]
}

resource vmName_db_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  parent: vmName_db
  name: 'CustomScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.4'
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

resource vmName_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for i in range(0, vmCountFrontend): {
  name: '${vmName_var}${i}/CustomScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.4'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        installScriptUri
      ]
    }
    protectedSettings: {
      commandToExecute: installCommand
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${vmName_var}${i}'
  ]
}]