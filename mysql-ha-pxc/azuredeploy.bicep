@description('Connect to your cluster using dnsName.cloudapp.net')
param dnsName string

@description('user name to ssh to the VMs')
param userName string

@description('size for the VMs')
param vmSize string = 'Standard_A1'

@description('Virtual network name for the cluster')
param virtualNetworkName string = 'pxcvnet'

@description('subnet name for the MySQL nodes')
param dbSubnetName string = 'dbsubnet'

@description('IP address in CIDR for virtual network')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('IP address in CIDR for db subnet')
param dbSubnetAddressPrefix string = '10.0.1.0/24'

@description('IP address for VM1 must be available in db subnet')
param vmIP1 string = '10.0.1.4'

@description('IP address for VM2 must be available in db subnet')
param vmIP2 string = '10.0.1.5'

@description('IP address for VM3 must be available in db subnet')
param vmIP3 string = '10.0.1.6'

@description('host name prefix for the VMs')
param vmNamePrefix string = 'pxcnd'

@allowed([
  'OpenLogic'
  'Canonical'
])
@description('publisher for the VM OS image')
param imagePublisher string = 'OpenLogic'

@allowed([
  'CentOS'
  'UbuntuServer'
])
@description('VM OS name')
param imageOffer string = 'CentOS'

@allowed([
  '6.5'
  '12.04.5-LTS'
  '14.04.5-LTS'
])
@description('VM OS version')
param imageSKU string = '6.5'

@description('MySQL public port')
param mysqlFrontEndPort int = 3306

@description('MySQL private port')
param mysqlBackEndPort int = 3306

@description('idel timeout for load balancer')
param idleTimeoutInMinutesforILBRule int = 4

@description('cluster health check probe port exposed to load balancer')
param probePort int = 9200

@description('cluster health check probe path')
param probeRequestPath string = '/'

@description('health check probe interval')
param probeIntervalInSeconds int = 10

@description('number of health check probes to consider failure')
param numberOfProbes int = 20

@description('public ssh port for VM1')
param sshNatRuleFrontEndPort1 int = 64001

@description('public ssh port for VM2')
param sshNatRuleFrontEndPort2 int = 64002

@description('public ssh port for VM3')
param sshNatRuleFrontEndPort3 int = 64003

@description('private ssh port for the VMs')
param sshNatRuleBackEndPort int = 22

@description('bash script command line')
param customScriptCommandToExecute string = 'bash azurepxc.sh'

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
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/mysql-ha-pxc/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var dbSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName, dbSubnetName)
var lbPublicIPName_var = '${lbName_var}-publicIP'
var lbPublicIPRef = lbPublicIPName.id
var lbName_var = '${vmNamePrefix}-lb'
var lbID = lbName.id
var ilbBackendAddressPoolName = '${vmNamePrefix}-ilbBackendPool'
var ilbBackendAddressPoolID = '${lbID}/backendAddressPools/${ilbBackendAddressPoolName}'
var ilbRuleName = '${vmNamePrefix}-ilbRule'
var probeName = '${vmNamePrefix}-probe'
var probeID = '${lbID}/probes/${probeName}'
var sshIPConfigName = '${vmNamePrefix}-sshIPCfg'
var sshIPConfig = '${lbID}/frontendIPConfigurations/${sshIPConfigName}'
var sshNatRuleName = '${vmNamePrefix}-natRule'
var sshNatRuleName1 = '${sshNatRuleName}-1'
var sshNatRuleName2 = '${sshNatRuleName}-2'
var sshNatRuleName3 = '${sshNatRuleName}-3'
var sshNatRuleID1 = '${lbID}/inboundNatRules/${sshNatRuleName1}'
var sshNatRuleID2 = '${lbID}/inboundNatRules/${sshNatRuleName2}'
var sshNatRuleID3 = '${lbID}/inboundNatRules/${sshNatRuleName3}'
var nicName = '${vmNamePrefix}-nic'
var nicName1_var = '${nicName}-1'
var nicName2_var = '${nicName}-2'
var nicName3_var = '${nicName}-3'
var nicId1 = nicName1.id
var nicId2 = nicName2.id
var nicId3 = nicName3.id
var vmName1_var = 'a-${vmNamePrefix}'
var vmName2_var = 'k-${vmNamePrefix}'
var vmName3_var = 'z-${vmNamePrefix}'
var availabilitySetName_var = '${vmNamePrefix}-set'
var vmExtensionName = '${vmNamePrefix}-ext'
var pxcClusterAddress = '${vmIP1},${vmIP2},${vmIP3}'
var customScriptCommandCommon = '${customScriptCommandToExecute} ${pxcClusterAddress} '
var mysqlConfigFilePath = uri(artifactsLocation, 'my.cnf.template${artifactsLocationSasToken}')
var customScriptParamVm1 = '${vmIP1} bootstrap-pxc ${mysqlConfigFilePath}'
var vmExtensionName1_var = '${vmName1_var}/${vmExtensionName}'
var customScriptParamVm2 = '${vmIP2} start ${mysqlConfigFilePath}'
var customScriptParamVm3 = '${vmIP3} start ${mysqlConfigFilePath}'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${userName}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource lbPublicIPName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: lbPublicIPName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: dnsName
    }
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

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: dbSubnetName
        properties: {
          addressPrefix: dbSubnetAddressPrefix
        }
      }
    ]
  }
}

resource nicName1 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName1_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: vmIP1
          subnet: {
            id: dbSubnetRef
          }
          loadBalancerBackendAddressPools: [
            {
              id: ilbBackendAddressPoolID
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: sshNatRuleID1
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource nicName2 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName2_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: vmIP2
          subnet: {
            id: dbSubnetRef
          }
          loadBalancerBackendAddressPools: [
            {
              id: ilbBackendAddressPoolID
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: sshNatRuleID2
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource nicName3 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName3_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: vmIP3
          subnet: {
            id: dbSubnetRef
          }
          loadBalancerBackendAddressPools: [
            {
              id: ilbBackendAddressPoolID
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: sshNatRuleID3
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource vmName1 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName1_var
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetName.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName1_var
      adminUsername: userName
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        name: '${vmName1_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          name: '${vmName1_var}_DataDisk1'
          diskSizeGB: '1000'
          lun: 0
          createOption: 'Empty'
        }
        {
          name: '${vmName1_var}_DataDisk2'
          diskSizeGB: '1000'
          lun: 1
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicId1
        }
      ]
    }
  }
}

resource vmExtensionName1 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: vmExtensionName1_var
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'azurepxc.sh${artifactsLocationSasToken}')
      ]
    }
    protectedSettings: {
      commandToExecute: concat(customScriptCommandCommon, customScriptParamVm1)
    }
  }
  dependsOn: [
    vmName1
  ]
}

resource vmName2 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName2_var
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetName.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName2_var
      adminUsername: userName
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        name: '${vmName2_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          name: '${vmName2_var}_DataDisk1'
          diskSizeGB: '1000'
          lun: 0
          createOption: 'Empty'
        }
        {
          name: '${vmName2_var}_DataDisk2'
          diskSizeGB: '1000'
          lun: 1
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicId2
        }
      ]
    }
  }
}

resource vmName2_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  parent: vmName2
  name: '${vmExtensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'azurepxc.sh${artifactsLocationSasToken}')
      ]
    }
    protectedSettings: {
      commandToExecute: concat(customScriptCommandCommon, customScriptParamVm2)
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${vmName1_var}/extensions/${vmExtensionName}'
  ]
}

resource vmName3 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName3_var
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetName.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName3_var
      adminUsername: userName
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        name: '${vmName3_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          name: '${vmName3_var}_DataDisk1'
          diskSizeGB: '1000'
          lun: 0
          createOption: 'Empty'
        }
        {
          name: '${vmName3_var}_DataDisk2'
          diskSizeGB: '1000'
          lun: 1
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicId3
        }
      ]
    }
  }
}

resource vmName3_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  parent: vmName3
  name: '${vmExtensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'azurepxc.sh${artifactsLocationSasToken}')
      ]
    }
    protectedSettings: {
      commandToExecute: concat(customScriptCommandCommon, customScriptParamVm3)
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${vmName1_var}/extensions/${vmExtensionName}'
  ]
}

resource lbName 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: lbName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: sshIPConfigName
        properties: {
          publicIPAddress: {
            id: lbPublicIPRef
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: ilbBackendAddressPoolName
      }
    ]
    inboundNatRules: [
      {
        name: sshNatRuleName1
        properties: {
          frontendIPConfiguration: {
            id: sshIPConfig
          }
          protocol: 'Tcp'
          frontendPort: sshNatRuleFrontEndPort1
          backendPort: sshNatRuleBackEndPort
          enableFloatingIP: false
        }
      }
      {
        name: sshNatRuleName2
        properties: {
          frontendIPConfiguration: {
            id: sshIPConfig
          }
          protocol: 'Tcp'
          frontendPort: sshNatRuleFrontEndPort2
          backendPort: sshNatRuleBackEndPort
          enableFloatingIP: false
        }
      }
      {
        name: sshNatRuleName3
        properties: {
          frontendIPConfiguration: {
            id: sshIPConfig
          }
          protocol: 'Tcp'
          frontendPort: sshNatRuleFrontEndPort3
          backendPort: sshNatRuleBackEndPort
          enableFloatingIP: false
        }
      }
    ]
    loadBalancingRules: [
      {
        name: ilbRuleName
        properties: {
          frontendIPConfiguration: {
            id: sshIPConfig
          }
          backendAddressPool: {
            id: ilbBackendAddressPoolID
          }
          protocol: 'Tcp'
          frontendPort: mysqlFrontEndPort
          backendPort: mysqlBackEndPort
          enableFloatingIP: false
          idleTimeoutInMinutes: idleTimeoutInMinutesforILBRule
          probe: {
            id: probeID
          }
        }
      }
    ]
    probes: [
      {
        name: probeName
        properties: {
          protocol: 'Http'
          port: probePort
          intervalInSeconds: probeIntervalInSeconds
          numberOfProbes: numberOfProbes
          requestPath: probeRequestPath
        }
      }
    ]
  }
}