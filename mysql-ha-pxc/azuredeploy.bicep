param dnsName string {
  metadata: {
    description: 'Connect to your cluster using dnsName.cloudapp.net'
  }
}
param userName string {
  metadata: {
    description: 'user name to ssh to the VMs'
  }
}
param vmSize string {
  metadata: {
    description: 'size for the VMs'
  }
  default: 'Standard_A1'
}
param virtualNetworkName string {
  metadata: {
    description: 'Virtual network name for the cluster'
  }
  default: 'pxcvnet'
}
param dbSubnetName string {
  metadata: {
    description: 'subnet name for the MySQL nodes'
  }
  default: 'dbsubnet'
}
param vnetAddressPrefix string {
  metadata: {
    description: 'IP address in CIDR for virtual network'
  }
  default: '10.0.0.0/16'
}
param dbSubnetAddressPrefix string {
  metadata: {
    description: 'IP address in CIDR for db subnet'
  }
  default: '10.0.1.0/24'
}
param vmIP1 string {
  metadata: {
    description: 'IP address for VM1 must be available in db subnet'
  }
  default: '10.0.1.4'
}
param vmIP2 string {
  metadata: {
    description: 'IP address for VM2 must be available in db subnet'
  }
  default: '10.0.1.5'
}
param vmIP3 string {
  metadata: {
    description: 'IP address for VM3 must be available in db subnet'
  }
  default: '10.0.1.6'
}
param vmNamePrefix string {
  metadata: {
    description: 'host name prefix for the VMs'
  }
  default: 'pxcnd'
}
param imagePublisher string {
  allowed: [
    'OpenLogic'
    'Canonical'
  ]
  metadata: {
    description: 'publisher for the VM OS image'
  }
  default: 'OpenLogic'
}
param imageOffer string {
  allowed: [
    'CentOS'
    'UbuntuServer'
  ]
  metadata: {
    description: 'VM OS name'
  }
  default: 'CentOS'
}
param imageSKU string {
  allowed: [
    '6.5'
    '12.04.5-LTS'
    '14.04.5-LTS'
  ]
  metadata: {
    description: 'VM OS version'
  }
  default: '6.5'
}
param mysqlFrontEndPort int {
  metadata: {
    description: 'MySQL public port'
  }
  default: 3306
}
param mysqlBackEndPort int {
  metadata: {
    description: 'MySQL private port'
  }
  default: 3306
}
param idleTimeoutInMinutesforILBRule int {
  metadata: {
    description: 'idel timeout for load balancer'
  }
  default: 4
}
param probePort int {
  metadata: {
    description: 'cluster health check probe port exposed to load balancer'
  }
  default: 9200
}
param probeRequestPath string {
  metadata: {
    description: 'cluster health check probe path'
  }
  default: '/'
}
param probeIntervalInSeconds int {
  metadata: {
    description: 'health check probe interval'
  }
  default: 10
}
param numberOfProbes int {
  metadata: {
    description: 'number of health check probes to consider failure'
  }
  default: 20
}
param sshNatRuleFrontEndPort1 int {
  metadata: {
    description: 'public ssh port for VM1'
  }
  default: 64001
}
param sshNatRuleFrontEndPort2 int {
  metadata: {
    description: 'public ssh port for VM2'
  }
  default: 64002
}
param sshNatRuleFrontEndPort3 int {
  metadata: {
    description: 'public ssh port for VM3'
  }
  default: 64003
}
param sshNatRuleBackEndPort int {
  metadata: {
    description: 'private ssh port for the VMs'
  }
  default: 22
}
param customScriptCommandToExecute string {
  metadata: {
    description: 'bash script command line'
  }
  default: 'bash azurepxc.sh'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param authenticationType string {
  allowed: [
    'sshPublicKey'
    'password'
  ]
  metadata: {
    description: 'Type of authentication to use on the Virtual Machine. SSH key is recommended.'
  }
  default: 'sshPublicKey'
}
param adminPasswordOrKey string {
  metadata: {
    description: 'SSH Key or password for the Virtual Machine. SSH key is recommended.'
  }
  secure: true
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/mysql-ha-pxc/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}

var dbSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName, dbSubnetName)
var lbPublicIPName = '${lbName}-publicIP'
var lbPublicIPRef = lbPublicIPName_resource.id
var lbName = '${vmNamePrefix}-lb'
var lbID = lbName_resource.id
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
var nicName1 = '${nicName}-1'
var nicName2 = '${nicName}-2'
var nicName3 = '${nicName}-3'
var nicId1 = nicName1_resource.id
var nicId2 = nicName2_resource.id
var nicId3 = nicName3_resource.id
var vmName1 = 'a-${vmNamePrefix}'
var vmName2 = 'k-${vmNamePrefix}'
var vmName3 = 'z-${vmNamePrefix}'
var availabilitySetName = '${vmNamePrefix}-set'
var vmExtensionName = '${vmNamePrefix}-ext'
var pxcClusterAddress = '${vmIP1},${vmIP2},${vmIP3}'
var customScriptCommandCommon = '${customScriptCommandToExecute} ${pxcClusterAddress} '
var mysqlConfigFilePath = uri(artifactsLocation, 'my.cnf.template${artifactsLocationSasToken}')
var customScriptParamVm1 = '${vmIP1} bootstrap-pxc ${mysqlConfigFilePath}'
var vmExtensionName1 = '${vmName1}/${vmExtensionName}'
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

resource lbPublicIPName_resource 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: lbPublicIPName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: dnsName
    }
  }
}

resource availabilitySetName_resource 'Microsoft.Compute/availabilitySets@2017-12-01' = {
  name: availabilitySetName
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

resource nicName1_resource 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName1
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
    lbName_resource
  ]
}

resource nicName2_resource 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName2
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
    lbName_resource
  ]
}

resource nicName3_resource 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName3
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
    lbName_resource
  ]
}

resource vmName1_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName1
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetName_resource.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName1
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
        name: '${vmName1}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          name: '${vmName1}_DataDisk1'
          diskSizeGB: '1000'
          lun: 0
          createOption: 'Empty'
        }
        {
          name: '${vmName1}_DataDisk2'
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
  dependsOn: [
    availabilitySetName_resource
    nicName1_resource
  ]
}

resource vmExtensionName1_resource 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: vmExtensionName1
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
    vmName1_resource
  ]
}

resource vmName2_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName2
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetName_resource.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName2
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
        name: '${vmName2}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          name: '${vmName2}_DataDisk1'
          diskSizeGB: '1000'
          lun: 0
          createOption: 'Empty'
        }
        {
          name: '${vmName2}_DataDisk2'
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
  dependsOn: [
    availabilitySetName_resource
    nicName2_resource
  ]
}

resource vmName2_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName2}/${vmExtensionName}'
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
    vmName2_resource
    'Microsoft.Compute/virtualMachines/${vmName1}/extensions/${vmExtensionName}'
  ]
}

resource vmName3_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName3
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetName_resource.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName3
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
        name: '${vmName3}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          name: '${vmName3}_DataDisk1'
          diskSizeGB: '1000'
          lun: 0
          createOption: 'Empty'
        }
        {
          name: '${vmName3}_DataDisk2'
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
  dependsOn: [
    availabilitySetName_resource
    nicName3_resource
  ]
}

resource vmName3_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName3}/${vmExtensionName}'
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
    vmName3_resource
    'Microsoft.Compute/virtualMachines/${vmName1}/extensions/${vmExtensionName}'
  ]
}

resource lbName_resource 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: lbName
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
  dependsOn: [
    lbPublicIPName_resource
  ]
}