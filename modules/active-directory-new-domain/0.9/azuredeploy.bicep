param adminUsername string {
  metadata: {
    description: 'The name of the administrator account of the new VM and domain'
  }
}
param adminPassword string {
  metadata: {
    description: 'The password for the administrator account of the new VM and domain'
  }
  secure: true
}
param domainName string {
  metadata: {
    description: 'The FQDN of the Active Directory Domain to be created'
  }
}
param dnsPrefix string {
  metadata: {
    description: 'The DNS prefix for the public IP address used by the Load Balancer'
  }
  default: 'ad-${uniqueString(resourceGroup().id)}'
}
param vmSize string {
  metadata: {
    description: 'Size of the VM for the controller'
  }
  default: 'Standard_D2s_v3'
}
param artifactsLocation string {
  metadata: {
    description: 'The location of resources, such as templates and DSC modules, that the template depends on'
  }
  default: deployment().properties.templateLink.uri
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'Auto-generated token to access _artifactsLocation. Leave it blank unless you need to provide your own value.'
  }
  secure: true
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param virtualMachineName string {
  metadata: {
    description: 'Virtual machine name.'
  }
  default: 'ad-vm'
}
param virtualNetworkAddressRange string {
  metadata: {
    description: 'Virtual network address range.'
  }
  default: '10.0.0.0/16'
}
param virtualNetworkName string {
  metadata: {
    description: 'The name of the virtualNetwork.'
  }
  default: 'ad-vnet'
}
param subnetName string {
  metadata: {
    description: 'The name of the subnet.'
  }
  default: 'ad-vnet-subnet'
}
param privateIPAddress string {
  metadata: {
    description: 'Private IP address.'
  }
  default: '10.0.0.4'
}
param subnetRange string {
  metadata: {
    description: 'Subnet IP range.'
  }
  default: '10.0.0.0/24'
}

var loadBalancerFrontEndIPName = 'ad-LBFE'
var backendAddressPoolName = 'ad-LBBE'
var inboundNatRulesName = 'ad-RDP'
var networkInterfaceName_var = 'ad-nic'
var publicIPAddressName_var = 'ad-ip'
var availabilitySetName_var = 'ad-AvailabiltySet'
var loadBalancerName_var = 'ad-LoadBalancer'

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: dnsPrefix
    }
  }
}

resource availabilitySetName 'Microsoft.Compute/availabilitySets@2020-06-01' = {
  location: location
  name: availabilitySetName_var
  properties: {
    platformUpdateDomainCount: 20
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

module VNet '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('nestedtemplates/vnet.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'VNet'
  params: {
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressRange: virtualNetworkAddressRange
    subnetName: subnetName
    subnetRange: subnetRange
    location: location
  }
}

resource loadBalancerName 'Microsoft.Network/loadBalancers@2020-06-01' = {
  name: loadBalancerName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: loadBalancerFrontEndIPName
        properties: {
          publicIPAddress: {
            id: publicIPAddressName.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendAddressPoolName
      }
    ]
    inboundNatRules: [
      {
        name: inboundNatRulesName
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName_var, loadBalancerFrontEndIPName)
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

resource networkInterfaceName 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: networkInterfaceName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: privateIPAddress
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName_var, backendAddressPoolName)
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', loadBalancerName_var, inboundNatRulesName)
            }
          ]
        }
      }
    ]
  }
}

resource virtualMachineName_res 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    availabilitySet: {
      id: availabilitySetName.id
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2016-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: '${virtualMachineName}_OSDisk'
        caching: 'ReadOnly'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          name: '${virtualMachineName}_DataDisk'
          caching: 'ReadWrite'
          createOption: 'Empty'
          diskSizeGB: 20
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
          lun: 0
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName.id
        }
      ]
    }
  }
}

resource virtualMachineName_CreateADForest 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${virtualMachineName}/CreateADForest'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: uri(artifactsLocation, 'DSC/CreateADPDC.zip${artifactsLocationSasToken}')
      ConfigurationFunction: 'CreateADPDC.ps1\\CreateADPDC'
      Properties: {
        DomainName: domainName
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

module UpdateVNetDNS '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('nestedtemplates/vnet.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'UpdateVNetDNS'
  params: {
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressRange: virtualNetworkAddressRange
    subnetName: subnetName
    subnetRange: subnetRange
    DNSServerAddress: [
      privateIPAddress
    ]
    location: location
  }
  dependsOn: [
    virtualMachineName_CreateADForest
  ]
}

output dnsIpAddress string = privateIPAddress
output domainName_out string = domainName
output virtualNetworkSubscriptionId string = subscription().subscriptionId
output virtualNetworkResourceGroupName string = resourceGroup().name
output virtualNetworkName_out string = virtualNetworkName
output virtualNetworkSubnetName string = subnetName
output virtualNetworkAddressPrefixes string = virtualNetworkAddressRange