@description('The Name of the administrator of the new VM. Exclusion list: \'admin\',\'administrator\'')
param adminUsername string

@description('Unique public DNS prefix for the deployment. The fqdn will look something like \'<dnsname>.westus.cloudapp.azure.com\'. Up to 62 chars, digits or dashes, lowercase, should start with a letter: must conform to \'^[a-z][a-z0-9-]{1,61}[a-z0-9]$\'.')
param publicDnsName string = 'scu${uniqueString(resourceGroup().id)}'

@description('Password for the MySQL \'root\' admin user.')
@secure()
param mySqlPasswordForRootUser string

@description('User name that will be used to create user in MySQL database which has all privileges.')
param mySqlIdpUser string = 'scu'

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
param numberOfInstances int = 2

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

var vnetAddressRange = '10.0.0.0/16'
var subnetAddressRange = '10.0.0.0/24'
var subnetName = 'Subnet'
var availabilitySetName_var = 'AvSet'
var vmName_var = 'VM'
var storageAccountType = 'Standard_LRS'
var nicsql_var = '${vmName_var}sql'
var newStorageAccountName_var = 'st${uniqueString(resourceGroup().id)}'
var subnet_id = resourceId('Microsoft.Network/virtualNetworks/subnets', 'VNET', subnetName)
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var ubuntuOSVersion = '16.04-LTS'
var installScriptName = 'install_shibboleth_idp.sh'
var installScriptUri = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/shibboleth-cluster-ubuntu/${installScriptName}'
var installBackendScriptName = 'install_backend.sh'
var installBackendScriptUri = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/shibboleth-cluster-ubuntu/${installBackendScriptName}'
var installBackendCommand = 'sh ${installBackendScriptName} ${mySqlPasswordForRootUser} ${mySqlIdpUser} ${mySqlPasswordForIdpUser}'
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

resource publicIp 'Microsoft.Network/publicIPAddresses@2018-02-01' = {
  name: 'publicIp'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: publicDnsName
    }
  }
}

resource vmsqlIp 'Microsoft.Network/publicIPAddresses@2018-02-01' = {
  name: 'vmsqlIp'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: '${publicDnsName}db'
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

resource newStorageAccountName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: newStorageAccountName_var
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource VNET 'Microsoft.Network/virtualNetworks@2018-02-01' = {
  name: 'VNET'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressRange
      ]
    }
    subnets: [
      {
        name: 'Subnet'
        properties: {
          addressPrefix: subnetAddressRange
        }
      }
    ]
  }
}

resource loadBalancer 'Microsoft.Network/loadBalancers@2018-02-01' = {
  name: 'loadBalancer'
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LBFE'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'LBBAP'
      }
    ]
    inboundNatRules: [
      {
        name: 'SSH-VM0'
        properties: {
          frontendIPConfiguration: {
            id: '${loadBalancer.id}/frontendIPConfigurations/LBFE'
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
            id: '${loadBalancer.id}/frontendIPConfigurations/LBFE'
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
            id: '${loadBalancer.id}/frontendIPConfigurations/LBFE'
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
            id: '${loadBalancer.id}/frontendIPConfigurations/LBFE'
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
            id: '${loadBalancer.id}/frontendIPConfigurations/LBFE'
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
        properties: {
          frontendIPConfiguration: {
            id: '${loadBalancer.id}/frontendIpConfigurations/LBFE'
          }
          backendAddressPool: {
            id: '${loadBalancer.id}/backendAddressPools/LBBAP'
          }
          probe: {
            id: '${loadBalancer.id}/probes/lbprobe'
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 15
        }
        name: 'lbrule'
      }
      {
        properties: {
          frontendIPConfiguration: {
            id: '${loadBalancer.id}/frontendIpConfigurations/LBFE'
          }
          backendAddressPool: {
            id: '${loadBalancer.id}/backendAddressPools/LBBAP'
          }
          probe: {
            id: '${loadBalancer.id}/probes/lbprobe'
          }
          protocol: 'Tcp'
          frontendPort: 8443
          backendPort: 8443
          idleTimeoutInMinutes: 15
        }
        name: 'lbrule8443'
      }
    ]
    probes: [
      {
        properties: {
          protocol: 'Http'
          port: 8080
          requestPath: '/'
          intervalInSeconds: 15
          numberOfProbes: 2
        }
        name: 'lbprobe'
      }
    ]
  }
}

resource vmsql 'Microsoft.Network/networkSecurityGroups@2018-02-01' = {
  name: 'vmsql'
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-ssh'
        properties: {
          description: 'Allow SSH'
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
      {
        name: 'Port_3306'
        properties: {
          description: 'Allow 3306'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '3306'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vmName 'Microsoft.Network/networkInterfaces@2018-02-01' = [for i in range(0, numberOfInstances): {
  name: concat(vmName_var, i)
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet_id
          }
          loadBalancerBackendAddressPools: [
            {
              id: '${loadBalancer.id}/backendAddressPools/LBBAP'
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: '${loadBalancer.id}/inboundNatRules/SSH-VM${i}'
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    VNET
    loadBalancer
  ]
}]

resource nicsql 'Microsoft.Network/networkInterfaces@2018-02-01' = {
  name: nicsql_var
  location: location
  properties: {
    networkSecurityGroup: {
      id: vmsql.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vmsqlIp.id
          }
          subnet: {
            id: subnet_id
          }
        }
      }
    ]
  }
  dependsOn: [
    VNET
  ]
}

resource Microsoft_Compute_virtualMachines_vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, numberOfInstances): {
  name: concat(vmName_var, i)
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetName.id
    }
    hardwareProfile: {
      vmSize: 'Standard_A0'
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
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(vmName_var, i))
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(newStorageAccountName_var, '2017-10-01').primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    newStorageAccountName
    'Microsoft.Network/networkInterfaces/${vmName_var}${i}'
    availabilitySetName
  ]
}]

resource vmName_db 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: '${vmName_var}db'
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetName_db.id
    }
    hardwareProfile: {
      vmSize: 'Standard_A0'
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
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicsql.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(newStorageAccountName_var, '2017-10-01').primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    newStorageAccountName

    'Microsoft.Compute/availabilitySets/${availabilitySetName_var}db'
  ]
}

resource vmName_db_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2017-12-01' = {
  parent: vmName_db
  name: 'CustomScriptExtension'
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

resource vmName_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2017-12-01' = [for i in range(0, numberOfInstances): {
  name: '${vmName_var}${i}/CustomScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        installScriptUri
      ]
    }
    protectedSettings: {
      commandToExecute: 'mv *.sh /home/${adminUsername} && cd /home/${adminUsername} && sudo chmod 777 *.sh && sudo su && bash ${installScriptName} ${publicDnsName} ${location} ${publicDnsName}db ${mySqlIdpUser} ${mySqlPasswordForIdpUser}'
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${vmName_var}${i}'
  ]
}]