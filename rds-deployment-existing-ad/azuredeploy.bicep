@description('Unique public DNS prefix for the deployment. The fqdn will look something like \'<dnsname>.westus.cloudapp.azure.com\'. Up to 62 chars, digits or dashes, lowercase, should start with a letter: must conform to \'^[a-z][a-z0-9-]{1,61}[a-z0-9]$\'. For example johndns1 will result the final RDWEB access url like https://johndns1.westus.cloudapp.azure.com/RDWeb')
param dnsLabelPrefix string = 'rds-${uniqueString(resourceGroup().id)}'

@description('The name of the AD domain. For example contoso.com')
param adDomainName string

@description('The vnet name of AD domain. For example johnvnet1')
param adVnetName string

@description('The Resource Group containing the existing Virtual Network resource')
param adVnetRG string

@description('The subscription containing the existing Virtual Network resource')
param adVnetSubscriptionId string = subscription().subscriptionId

@description('The subnet name of AD domain')
param adSubnetName string

@description('The private IP address of the ad dns server')
param dnsServerPrivateIp string

@description('The name of the administrator of the new VM and the domain. Exclusion list: \'administrator\'. For example johnadmin')
param adminUsername string

@description('The password for the administrator account of the new VM and the domain')
@secure()
param adminPassword string

@allowed([
  '2012-R2-Datacenter'
  '2016-Datacenter'
  '2019-Datacenter'
])
@description('Windows server SKU')
param imageSKU string = '2019-Datacenter'

@description('Number of RemoteDesktopSessionHosts')
param numberOfRdshInstances int = 1

@description('The size of the RDSH VMs')
param rdshVmSize string = 'Standard_D4s_v3'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var gwdnsLabelPrefix = 'gwd-${uniqueString(resourceGroup().id)}'
var cbdnsLabelPrefix = 'cbd-${uniqueString(resourceGroup().id)}'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var subnet_id = resourceId(adVnetSubscriptionId, adVnetRG, 'Microsoft.Network/virtualNetworks/subnets', adVnetName, adSubnetName)
var publicIpRef_var = 'publicIp'
var brokerIpRef_var = 'brokerpublicIp'
var gatewayIpRef_var = 'gatewaypublicIp'

resource publicIpRef 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIpRef_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource gatewayIpRef 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: gatewayIpRef_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: gwdnsLabelPrefix
    }
  }
}

resource brokerIpRef 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: brokerIpRef_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: cbdnsLabelPrefix
    }
  }
}

resource gw_availabilityset 'Microsoft.Compute/availabilitySets@2020-06-01' = {
  location: location
  name: 'gw-availabilityset'
  properties: {
    platformUpdateDomainCount: 20
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource cb_availabilityset 'Microsoft.Compute/availabilitySets@2020-06-01' = {
  location: location
  name: 'cb-availabilityset'
  properties: {
    platformUpdateDomainCount: 20
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource rdsh_availabilityset 'Microsoft.Compute/availabilitySets@2020-06-01' = {
  location: location
  name: 'rdsh-availabilityset'
  properties: {
    platformUpdateDomainCount: 20
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource loadBalancer 'Microsoft.Network/loadBalancers@2020-06-01' = {
  name: 'loadBalancer'
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LBFE'
        properties: {
          publicIPAddress: {
            id: publicIpRef.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'LBBAP'
      }
    ]
    loadBalancingRules: [
      {
        name: 'LBRule01'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'loadbalancer', 'LBFE')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools/', 'loadbalancer', 'LBBAP')
          }
          protocol: 'Tcp'
          frontendPort: 443
          backendPort: 443
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          loadDistribution: 'SourceIPProtocol'
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'loadbalancer', 'tcpProbe')
          }
        }
      }
      {
        name: 'LBRule02'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'loadbalancer', 'LBFE')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'loadbalancer', 'LBBAP')
          }
          protocol: 'Udp'
          frontendPort: 3391
          backendPort: 3391
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          loadDistribution: 'SourceIPProtocol'
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'loadbalancer', 'tcpProbe')
          }
        }
      }
    ]
    probes: [
      {
        name: 'tcpProbe'
        properties: {
          protocol: 'Tcp'
          port: 443
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
      {
        name: 'tcpProbe01'
        properties: {
          protocol: 'Tcp'
          port: 3391
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
    inboundNatRules: [
      {
        name: 'rdp'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'loadBalancer', 'LBFE')
          }
          protocol: 'Tcp'
          frontendPort: 3389
          backendPort: 3389
          enableFloatingIP: false
        }
      }
    ]
  }
}

resource gw_nic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: 'gw-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: gatewayIpRef.id
          }
          subnet: {
            id: subnet_id
          }
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'loadBalancer', 'LBBAP')
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', 'loadBalancer', 'rdp')
            }
          ]
        }
      }
    ]
    dnsSettings: {
      dnsServers: [
        dnsServerPrivateIp
      ]
    }
  }
  dependsOn: [
    loadBalancer
  ]
}

resource cb_nic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: 'cb-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: brokerIpRef.id
          }
          subnet: {
            id: subnet_id
          }
        }
      }
    ]
    dnsSettings: {
      dnsServers: [
        dnsServerPrivateIp
      ]
    }
  }
  dependsOn: [
    loadBalancer
  ]
}

resource rdsh_nic 'Microsoft.Network/networkInterfaces@2020-06-01' = [for i in range(0, numberOfRdshInstances): {
  name: 'rdsh-${i}-nic'
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
        }
      }
    ]
    dnsSettings: {
      dnsServers: [
        dnsServerPrivateIp
      ]
    }
  }
  dependsOn: [
    loadBalancer
  ]
}]

resource gw_vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: 'gw-vm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: rdshVmSize
    }
    availabilitySet: {
      id: gw_availabilityset.id
    }
    osProfile: {
      computerName: 'gateway'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        name: 'gw_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: gw_nic.id
        }
      ]
    }
  }
}

resource gw_vm_gateway 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  parent: gw_vm
  name: 'gateway'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.11'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: uri(artifactsLocation, 'Configuration.zip${artifactsLocationSasToken}')
      ConfigurationFunction: 'Configuration.ps1\\Gateway'
      Properties: {
        DomainName: adDomainName
        AdminCreds: {
          UserName: adminUsername
          Password: 'PrivateSettingsRef:AdminPassword'
        }
      }
    }
    protectedSettings: {
      Items: {
        AdminPassword: adminPassword
      }
    }
  }
}

resource rdsh 'Microsoft.Compute/virtualMachines@2020-06-01' = [for i in range(0, numberOfRdshInstances): {
  name: 'rdsh-${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: rdshVmSize
    }
    availabilitySet: {
      id: rdsh_availabilityset.id
    }
    osProfile: {
      computerName: 'rdsh-${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        name: 'rdsh-${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'rdsh-${i}-nic')
        }
      ]
    }
  }
  dependsOn: [
    rdsh_availabilityset
    resourceId('Microsoft.Network/networkInterfaces/', 'rdsh-${i}-nic')
  ]
}]

resource rdsh_sessionhost 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = [for i in range(0, numberOfRdshInstances): {
  name: 'rdsh-${i}/sessionhost'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.11'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: uri(artifactsLocation, 'Configuration.zip${artifactsLocationSasToken}')
      ConfigurationFunction: 'Configuration.ps1\\SessionHost'
      Properties: {
        DomainName: adDomainName
        AdminCreds: {
          UserName: adminUsername
          Password: 'PrivateSettingsRef:AdminPassword'
        }
      }
    }
    protectedSettings: {
      Items: {
        AdminPassword: adminPassword
      }
    }
  }
  dependsOn: [
    resourceId('Microsoft.Compute/virtualMachines', 'rdsh-${i}')
  ]
}]

resource cb_vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: 'cb-vm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: rdshVmSize
    }
    availabilitySet: {
      id: cb_availabilityset.id
    }
    osProfile: {
      computerName: 'broker'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        name: 'cb_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: cb_nic.id
        }
      ]
    }
  }
  dependsOn: [
    rdsh
  ]
}

resource cb_vm_rdsdeployment 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  parent: cb_vm
  name: 'rdsdeployment'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.11'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: uri(artifactsLocation, 'Configuration.zip${artifactsLocationSasToken}')
      configurationFunction: 'Configuration.ps1\\RDSDeployment'
      properties: {
        adminCreds: {
          UserName: adminUsername
          Password: 'PrivateSettingsRef:adminPassword'
        }
        connectionBroker: 'broker.${adDomainName}'
        domainName: adDomainName
        externalfqdn: reference(gatewayIpRef_var).dnsSettings.fqdn
        numberOfRdshInstances: numberOfRdshInstances
        sessionHostNamingPrefix: 'rdsh-'
        webAccessServer: 'gateway.${adDomainName}'
      }
    }
    protectedSettings: {
      Items: {
        adminPassword: adminPassword
      }
    }
  }
  dependsOn: [
    gw_vm_gateway
    rdsh
  ]
}