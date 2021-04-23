@description('User name for the Virtual Machine administrator. Do not use simple names such as \'admin\'.')
param vmAdminUsername string

@description('Password for the Virtual Machine administrator.')
@secure()
param vmAdminPassword string

@description('Password for the OpenLDAP directory administrator.')
@secure()
param directoryAdminPassword string

@description('Name of the organization for which the directory is being created.')
param organization string

@description('Unique name that will be used to generate various other names including the name of the Public IP used to access the Virtual Machine.')
param namePrefix string

@allowed([
  1
  2
  3
  4
  5
])
@description('Number of VMs in the cluster.')
param vmCount int = 2

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
param vmSize string = 'Standard_A0'

@description('Location for all resources.')
param location string = resourceGroup().location

var newStorageAccountName_var = '${uniqueString(resourceGroup().id)}olc'
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var ubuntuOSVersion = '14.04.5-LTS'
var OSDiskName = '${namePrefix}Disk'
var nicName_var = '${namePrefix}Nic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.1.0/24'
var privateIPAddressPrefix = '10.0.1.1'
var storageAccountType = 'Standard_LRS'
var publicIPAddressName_var = '${namePrefix}IP'
var publicIPAddressID = publicIPAddressName.id
var publicIPAddressType = 'Dynamic'
var vmStorageAccountContainerName = 'vhds'
var vmName_var = '${namePrefix}VM'
var virtualNetworkName_var = '${namePrefix}VNet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var availabilitySetName_var = '${namePrefix}AvSet'
var lbName_var = '${namePrefix}LB'
var lbID = lbName.id
var frontEndIPConfigID = '${lbID}/frontendIPConfigurations/loadBalancerFrontend'
var lbProbeID = '${lbID}/probes/tcpProbe'
var lbPoolID = '${lbID}/backendAddressPools/LoadBalancerBackend'
var installScriptName = 'install_openldap.sh'
var fileUriBase = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/openldap-cluster-ubuntu/'
var ldifUriBase = '${fileUriBase}ldif/'
var installScriptUri = concat(fileUriBase, installScriptName)
var installCommand = 'bash ${installScriptName} ${vmAdminUsername} ${vmAdminPassword} ${directoryAdminPassword} ${namePrefix} ${location} ${organization} ${privateIPAddressPrefix} ${vmCount}'

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
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, vmCount): {
  name: concat(nicName_var, i)
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: concat(privateIPAddressPrefix, i)
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
        name: 'HTTPRule'
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
      {
        name: 'HTTPSRule'
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
          probe: {
            id: lbProbeID
          }
        }
      }
      {
        name: 'LDAPRule'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          backendAddressPool: {
            id: lbPoolID
          }
          protocol: 'Tcp'
          frontendPort: 389
          backendPort: 389
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
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
}

resource vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, vmCount): {
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
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
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
    'Microsoft.Network/networkInterfaces/${nicName_var}${i}'
    availabilitySetName
  ]
}]

resource vmName_newuserscript 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for i in range(0, vmCount): {
  name: '${vmName_var}${i}/newuserscript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        installScriptUri
        '${ldifUriBase}forceTLS.ldif'
        '${ldifUriBase}setTLSConfig.ldif'
        '${ldifUriBase}config_1_loadSyncProvModule.ldif'
        '${ldifUriBase}config_2_setServerID.ldif'
        '${ldifUriBase}config_3_setConfigPW.ldif'
        '${ldifUriBase}config_3a_addOlcRootDN.ldif'
        '${ldifUriBase}config_4_addConfigReplication.ldif'
        '${ldifUriBase}config_5_addSyncProv.ldif'
        '${ldifUriBase}config_6_addSyncRepl.ldif'
        '${ldifUriBase}config_7_testConfigReplication.ldif'
        '${ldifUriBase}hdb_1_addSyncProvToHDB.ldif'
        '${ldifUriBase}hdb_2_addOlcSuffix.ldif'
        '${ldifUriBase}hdb_3_addOlcRootDN.ldif'
        '${ldifUriBase}hdb_4_addOlcRootPW.ldif'
        '${ldifUriBase}hdb_5_addOlcSyncRepl.ldif'
        '${ldifUriBase}hdb_6_addOlcMirrorMode.ldif'
        '${ldifUriBase}hdb_7_addIndexHDB.ldif'
      ]
    }
    protectedSettings: {
      commandToExecute: '${installCommand} ${i}'
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${vmName_var}${i}'
  ]
}]