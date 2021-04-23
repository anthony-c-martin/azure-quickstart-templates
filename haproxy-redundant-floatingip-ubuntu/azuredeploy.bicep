@description('Admin username')
param adminUsername string = 'azureuser'

@description('SSH rsa public key file as a string.')
param sshKeyData string

@description('DNS Label for the load balancer Public IP. Must be lowercase. It should match with the regex: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$.')
param lbDNSLabelPrefix string

@description('Prefix to use for names of VMs under the load balancer')
param haproxyVMNamePrefix string = 'haproxyvm-'

@description('Prefix to use for names of application VMs')
param appVMNamePrefix string = 'appvm-'

@allowed([
  '12.04.5-LTS'
  '14.04.5-LTS'
  '15.10'
])
@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version. Allowed values: 12.04.5-LTS, 14.04.5-LTS, 15.10.')
param ubuntuOSVersion string = '14.04.5-LTS'

@description('Size of the VM')
param vmSize string = 'Standard_D1'

var scriptsBaseUrl = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/haproxy-redundant-floatingip-ubuntu/'
var storageAccountName_var = '${uniqueString(resourceGroup().id)}haproxysa'
var numberOfHAproxyInstances = 2
var masterHAproxyInstanceIndex = 0
var haproxyVMScripts = {
  fileUris: [
    '${scriptsBaseUrl}haproxyvm-configure.sh'
    '${scriptsBaseUrl}keepalived-action.sh'
    '${scriptsBaseUrl}keepalived-check-appsvc.sh'
  ]
  commandToExecute: 'sudo bash -x haproxyvm-configure.sh  -a ${appVMNamePrefix}0 -a ${appVMNamePrefix}1 -p ${appVMPort} -l ${lbDNSLabelPrefix}.${resourceGroup().location}.cloudapp.azure.com -t ${lbVIPPort} -m ${haproxyVMNamePrefix}0 -b ${haproxyVMNamePrefix}1'
}
var numberOfAppInstances = 2
var appVMScripts = {
  fileUris: [
    '${scriptsBaseUrl}apache-setup.sh'
  ]
  commandToExecute: 'sudo bash apache-setup.sh'
}
var appVMPort = 80
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var sshKeyPath = '/home/${adminUsername}/.ssh/authorized_keys'
var nicNamePrefix = 'nic-'
var storageAccountType = 'Standard_LRS'
var haproxyAvailabilitySetName_var = 'haproxyAvSet'
var appAvailabilitySetName_var = 'appAvSet'
var vnetName_var = 'haproxyVNet'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet-1'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetName)
var subnetPrefix = '10.0.0.0/24'
var lbName_var = 'haproxyLB'
var lbPublicIPAddressType = 'Static'
var lbPublicIPAddressName_var = '${lbName_var}-publicip'
var lbVIPPort = 80
var lbID = lbName.id
var frontEndIPConfigID = '${lbID}/frontendIPConfigurations/LoadBalancerFrontEnd'
var lbPoolID = '${lbID}/backendAddressPools/BackendPool1'
var lbProbeID = '${lbID}/probes/tcpProbe'

resource storageAccountName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageAccountName_var
  location: resourceGroup().location
  properties: {
    accountType: storageAccountType
  }
}

resource haproxyAvailabilitySetName 'Microsoft.Compute/availabilitySets@2017-03-30' = {
  name: haproxyAvailabilitySetName_var
  location: resourceGroup().location
  properties: {
    platformUpdateDomainCount: 3
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource appAvailabilitySetName 'Microsoft.Compute/availabilitySets@2017-03-30' = {
  name: appAvailabilitySetName_var
  location: resourceGroup().location
  properties: {
    platformUpdateDomainCount: 3
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource lbPublicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: lbPublicIPAddressName_var
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: lbPublicIPAddressType
    dnsSettings: {
      domainNameLabel: lbDNSLabelPrefix
    }
  }
}

resource vnetName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: vnetName_var
  location: resourceGroup().location
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

resource lbName 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: lbName_var
  location: resourceGroup().location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          publicIPAddress: {
            id: lbPublicIPAddressName.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'BackendPool1'
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
          frontendPort: 50001
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
          frontendPort: 50002
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
          frontendPort: lbVIPPort
          backendPort: lbVIPPort
          enableFloatingIP: true
          idleTimeoutInMinutes: 5
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
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
}

resource haproxyVMNamePrefix_nicNamePrefix 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, numberOfHAproxyInstances): {
  name: concat(haproxyVMNamePrefix, nicNamePrefix, i)
  location: resourceGroup().location
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
              id: '${lbID}/backendAddressPools/BackendPool1'
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
    vnetName
    lbName
  ]
}]

resource haproxyVMNamePrefix_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, numberOfHAproxyInstances): {
  name: concat(haproxyVMNamePrefix, i)
  location: resourceGroup().location
  properties: {
    availabilitySet: {
      id: haproxyAvailabilitySetName.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(haproxyVMNamePrefix, i)
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: sshKeyPath
              keyData: sshKeyData
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: ubuntuOSVersion
        version: 'latest'
      }
      osDisk: {
        name: '${haproxyVMNamePrefix}OSDisk-${i}'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageAccountType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(haproxyVMNamePrefix, nicNamePrefix, i))
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'http://${storageAccountName_var}.blob.core.windows.net'
      }
    }
  }
  dependsOn: [
    storageAccountName
    'Microsoft.Network/networkInterfaces/${haproxyVMNamePrefix}${nicNamePrefix}${i}'
    haproxyAvailabilitySetName
  ]
}]

resource appVMNamePrefix_nicNamePrefix 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, numberOfAppInstances): {
  name: concat(appVMNamePrefix, nicNamePrefix, i)
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetName
  ]
}]

resource appVMNamePrefix_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, numberOfAppInstances): {
  name: concat(appVMNamePrefix, i)
  location: resourceGroup().location
  properties: {
    availabilitySet: {
      id: appAvailabilitySetName.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(appVMNamePrefix, i)
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: sshKeyPath
              keyData: sshKeyData
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: ubuntuOSVersion
        version: 'latest'
      }
      osDisk: {
        name: '${appVMNamePrefix}OSDisk-${i}'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageAccountType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(appVMNamePrefix, nicNamePrefix, i))
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'http://${storageAccountName_var}.blob.core.windows.net'
      }
    }
  }
  dependsOn: [
    storageAccountName
    'Microsoft.Network/networkInterfaces/${appVMNamePrefix}${nicNamePrefix}${i}'
    appAvailabilitySetName
  ]
}]

resource appVMNamePrefix_configureAppVM 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for i in range(0, numberOfAppInstances): {
  name: '${appVMNamePrefix}${i}/configureAppVM'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: appVMScripts.fileUris
      commandToExecute: appVMScripts.commandToExecute
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${appVMNamePrefix}${i}'
  ]
}]

resource haproxyVMNamePrefix_configureHAproxyVM 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for i in range(0, numberOfHAproxyInstances): {
  name: '${haproxyVMNamePrefix}${i}/configureHAproxyVM'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: haproxyVMScripts.fileUris
      commandToExecute: haproxyVMScripts.commandToExecute
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${haproxyVMNamePrefix}${i}'
    appVMNamePrefix_configureAppVM
  ]
}]