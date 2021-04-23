@description('Administrator username.')
param adminUsername string = 'openedxuser'

@description('Administrator password.')
@secure()
param adminPassword string

@description('DNS Label for the Public IP. Must be lowercase. It should match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.')
param dnsLabelPrefix string

@maxValue(20)
@description('Number of application virtual machines behind the load balancer.')
param appVmCount int = 1

@allowed([
  'Standard_DS2'
  'Standard_DS3'
  'Standard_DS4'
  'Standard_DS11'
  'Standard_DS12'
  'Standard_DS13'
  'Standard_DS14'
  'Standard_DS2_v2'
  'Standard_DS3_v2'
  'Standard_DS4_v2'
  'Standard_DS5_v2'
  'Standard_DS11_v2'
  'Standard_DS12_v2'
  'Standard_DS13_v2'
  'Standard_DS14_v2'
  'Standard_DS15_v2'
])
@description('Size of the application virtual machine(s).')
param appVmSize string = 'Standard_DS2_v2'

@allowed([
  'Standard_DS2'
  'Standard_DS3'
  'Standard_DS4'
  'Standard_DS11'
  'Standard_DS12'
  'Standard_DS13'
  'Standard_DS14'
  'Standard_DS2_v2'
  'Standard_DS3_v2'
  'Standard_DS4_v2'
  'Standard_DS5_v2'
  'Standard_DS11_v2'
  'Standard_DS12_v2'
  'Standard_DS13_v2'
  'Standard_DS14_v2'
  'Standard_DS15_v2'
])
@description('Size of the MySQL virtual machine.')
param mySqlVmSize string = 'Standard_DS2_v2'

@allowed([
  'Standard_DS2'
  'Standard_DS3'
  'Standard_DS4'
  'Standard_DS11'
  'Standard_DS12'
  'Standard_DS13'
  'Standard_DS14'
  'Standard_DS2_v2'
  'Standard_DS3_v2'
  'Standard_DS4_v2'
  'Standard_DS5_v2'
  'Standard_DS11_v2'
  'Standard_DS12_v2'
  'Standard_DS13_v2'
  'Standard_DS14_v2'
  'Standard_DS15_v2'
])
@description('Size of the MongoDB virtual machine.')
param mongoVmSize string = 'Standard_DS2_v2'

@description('Location for all resources.')
param location string = resourceGroup().location

var scriptDownloadUri = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/openedx-scalable-ubuntu/'
var installScript = 'install-openedx.sh'
var installCommand = 'bash -c \'nohup ./${installScript} ${appVmCount} ${adminUsername} ${adminPassword} </dev/null &>/var/log/azure/openedx-install.log &\''
var availabilitySetName_var = 'avail-set'
var osImagePublisher = 'Canonical'
var osImageOffer = 'UbuntuServer'
var osImageSKU = '12.04.5-LTS'
var appVmName_var = 'openedx-app'
var mySqlVmName_var = 'openedx-mysql'
var mongoVmName_var = 'openedx-mongo'
var appPublicIPAddressName_var = 'myPublicIP'
var mySqlPublicIPAddressName_var = 'myPublicIPMySql'
var mongoPublicIPAddressName_var = 'myPublicIPMongo'
var virtualNetworkName_var = 'VNET'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var subnetName = 'Subnet'
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var nsgName_var = 'node-nsg'
var nsgID = nsgName.id
var storageAccountType = 'Premium_LRS'
var storageAccountName_var = '${uniqueString(resourceGroup().id)}vhdsa'
var vhdBlobContainer = 'vhds'
var lbName_var = 'openedx-loadbalancer'
var lbID = lbName.id
var lbPoolID = '${lbID}/backendAddressPools/LoadBalancerBackend'
var lbProbeLMSID = '${lbID}/probes/tcpProbeLMS'
var lbProbeCMSID = '${lbID}/probes/tcpProbeCMS'
var frontEndIPConfigID = '${lbID}/frontendIPConfigurations/loadBalancerFrontend'

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

resource appPublicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: appPublicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource mySqlPublicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: mySqlPublicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource mongoPublicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: mongoPublicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
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
          networkSecurityGroup: {
            id: nsgID
          }
        }
      }
    ]
  }
  dependsOn: [
    nsgID
  ]
}

resource nsgName 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: nsgName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'ssh'
        properties: {
          description: 'SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'LMS'
        properties: {
          description: 'Allow connection to Open edX LMS'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 201
          direction: 'Inbound'
        }
      }
      {
        name: 'CMS'
        properties: {
          description: 'Allow connection to Open edX CMS'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '18010'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 203
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource appVmName_nic 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, appVmCount): {
  name: '${appVmName_var}${i}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfigNode'
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
    'Microsoft.Network/loadBalancers/${lbName_var}/inboundNatRules/SSH-VM${i}'
  ]
}]

resource mySqlVmName_nic 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: '${mySqlVmName_var}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfigNode'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: mySqlPublicIPAddressName.id
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

resource mongoVmName_nic 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: '${mongoVmName_var}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfigNode'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: mongoPublicIPAddressName.id
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

resource lbName 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: lbName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontend'
        properties: {
          publicIPAddress: {
            id: appPublicIPAddressName.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'LoadBalancerBackend'
      }
    ]
    loadBalancingRules: [
      {
        name: 'LBRuleLMS'
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
            id: lbProbeLMSID
          }
        }
      }
      {
        name: 'LBRuleCMS'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          backendAddressPool: {
            id: lbPoolID
          }
          protocol: 'Tcp'
          frontendPort: 18010
          backendPort: 18010
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          loadDistribution: 'SourceIP'
          probe: {
            id: lbProbeCMSID
          }
        }
      }
      {
        name: 'LBRuleSSL'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          backendAddressPool: {
            id: lbPoolID
          }
          protocol: 'Tcp'
          frontendPort: 443
          backendPort: 443
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          loadDistribution: 'SourceIP'
        }
      }
    ]
    probes: [
      {
        name: 'tcpProbeLMS'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
      {
        name: 'tcpProbeCMS'
        properties: {
          protocol: 'Tcp'
          port: 18010
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
}

resource lbName_SSH_VM 'Microsoft.Network/loadBalancers/inboundNatRules@2015-06-15' = [for i in range(0, appVmCount): {
  name: '${lbName_var}/SSH-VM${i}'
  location: location
  properties: {
    frontendIPConfiguration: {
      id: frontEndIPConfigID
    }
    protocol: 'Tcp'
    frontendPort: (i + 2220)
    backendPort: 22
    enableFloatingIP: false
  }
  dependsOn: [
    lbName
  ]
}]

resource appVmName 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, appVmCount): {
  name: concat(appVmName_var, i)
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetName.id
    }
    hardwareProfile: {
      vmSize: appVmSize
    }
    osProfile: {
      computerName: concat(appVmName_var, i)
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: osImagePublisher
        offer: osImageOffer
        sku: osImageSKU
        version: 'latest'
      }
      osDisk: {
        name: '${appVmName_var}${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${appVmName_var}${i}-nic')
        }
      ]
    }
  }
  dependsOn: [
    storageAccountName
    'Microsoft.Network/networkInterfaces/${appVmName_var}${i}-nic'
    availabilitySetName
  ]
}]

resource mySqlVmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: mySqlVmName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: mySqlVmSize
    }
    osProfile: {
      computerName: mySqlVmName_var
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: osImagePublisher
        offer: osImageOffer
        sku: osImageSKU
        version: 'latest'
      }
      osDisk: {
        name: '${mySqlVmName_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: mySqlVmName_nic.id
        }
      ]
    }
  }
  dependsOn: [
    storageAccountName
    'Microsoft.Network/networkInterfaces/${mySqlVmName_var}-nic'
  ]
}

resource mongoVmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: mongoVmName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: mongoVmSize
    }
    osProfile: {
      computerName: mongoVmName_var
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: osImagePublisher
        offer: osImageOffer
        sku: osImageSKU
        version: 'latest'
      }
      osDisk: {
        name: '${mongoVmName_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: mongoVmName_nic.id
        }
      ]
    }
  }
  dependsOn: [
    storageAccountName
    'Microsoft.Network/networkInterfaces/${mongoVmName_var}-nic'
  ]
}

resource appVmName_0_installscript 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${appVmName_var}0/installscript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        concat(scriptDownloadUri, installScript)
        '${scriptDownloadUri}server-vars.yml'
        '${scriptDownloadUri}inventory.ini'
      ]
    }
    protectedSettings: {
      commandToExecute: installCommand
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${appVmName_var}0'
  ]
}