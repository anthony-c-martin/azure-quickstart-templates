param adminUsername string {
  metadata: {
    description: 'The name of the Administrator of the new VM and Domain'
  }
}
param adminPassword string {
  metadata: {
    description: 'The password for the Administrator account of the new VM and Domain'
  }
  secure: true
}
param domainName string {
  metadata: {
    description: 'The FQDN of the AD Domain created '
  }
}
param dnsPrefix string {
  metadata: {
    description: 'The DNS prefix for the public IP address used by the Load Balancer'
  }
}
param pdcRDPPort int {
  metadata: {
    description: 'The public RDP port for the PDC VM'
  }
  default: 3389
}
param bdcRDPPort int {
  metadata: {
    description: 'The public RDP port for the BDC VM'
  }
  default: 13389
}
param artifactsLocation string {
  metadata: {
    description: 'The location of resources, such as templates and DSC modules, that the template depends on'
  }
  default: deployment().properties.templateLink.uri
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'Auto-generated token to access _artifactsLocation'
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
param adVMSize string {
  metadata: {
    description: 'Size for the VM.  This sample uses premium disk and requires an \'S\' sku.'
  }
  default: 'Standard_DS2_v2'
}

var storageAccountType = 'Premium_LRS'
var adPDCVMName = 'adPDC'
var adBDCVMName = 'adBDC'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var imageSKU = '2016-Datacenter'
var adAvailabilitySetName = 'adAvailabiltySet'
var publicIPAddressName = 'ad-lb-pip'
var adLBFE = 'LBFE'
var adLBBE = 'LBBE'
var adPDCRDPNAT = 'adPDCRDP'
var adBDCRDPNAT = 'adBDCRDP'
var virtualNetworkName = 'adVNET'
var virtualNetworkAddressRange = '10.0.0.0/16'
var adSubnetName = 'adSubnet'
var adSubnet = '10.0.0.0/24'
var adPDCNicName = 'adPDCNic'
var adPDCNicIPAddress = '10.0.0.4'
var adBDCNicName = 'adBDCNic'
var adBDCNicIPAddress = '10.0.0.5'
var adSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, adSubnetName)
var adLBName = 'adLoadBalancer'
var adlbFEConfigID = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', adLBName, adLBFE)
var adPDCRDPNATRuleID = resourceId('Microsoft.Network/loadBalancers/inboundNatRules', adLBName, adPDCRDPNAT)
var adBDCRDPNATRuleID = resourceId('Microsoft.Network/loadBalancers/inboundNatRules', adLBName, adBDCRDPNAT)
var adBEAddressPoolID = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', adLBName, adLBBE)
var adDataDiskSize = 1000
var vnetTemplateUri = uri(artifactsLocation, 'nestedtemplates/vnet.json${artifactsLocationSasToken}')
var nicTemplateUri = uri(artifactsLocation, 'nestedtemplates/nic.json${artifactsLocationSasToken}')
var vnetwithDNSTemplateUri = uri(artifactsLocation, 'nestedtemplates/vnet-with-dns-server.json${artifactsLocationSasToken}')
var configureADBDCTemplateUri = uri(artifactsLocation, 'nestedtemplates/configureADBDC.json${artifactsLocationSasToken}')
var adPDCModulesURL = uri(artifactsLocation, 'DSC/CreateADPDC.zip${artifactsLocationSasToken}')
var adPDCConfigurationFunction = 'CreateADPDC.ps1\\CreateADPDC'
var adBDCPreparationModulesURL = uri(artifactsLocation, 'DSC/PrepareADBDC.zip${artifactsLocationSasToken}')
var adBDCPreparationFunction = 'PrepareADBDC.ps1\\PrepareADBDC'
var adBDCConfigurationModulesURL = uri(artifactsLocation, 'DSC/ConfigureADBDC.zip${artifactsLocationSasToken}')
var adBDCConfigurationFunction = 'ConfigureADBDC.ps1\\ConfigureADBDC'

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-03-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsPrefix
    }
  }
}

resource adAvailabilitySetName_resource 'Microsoft.Compute/availabilitySets@2019-12-01' = {
  location: location
  name: adAvailabilitySetName
  properties: {
    PlatformUpdateDomainCount: 20
    PlatformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

module VNet '<failed to parse [variables(\'vnetTemplateUri\')]>' = {
  name: 'VNet'
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressRange: virtualNetworkAddressRange
    subnetName: adSubnetName
    subnetRange: adSubnet
  }
}

resource adLBName_resource 'Microsoft.Network/loadBalancers@2020-03-01' = {
  name: adLBName
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: adLBFE
        properties: {
          publicIPAddress: {
            id: publicIPAddressName_resource.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: adLBBE
      }
    ]
    inboundNatRules: [
      {
        name: adPDCRDPNAT
        properties: {
          frontendIPConfiguration: {
            id: adlbFEConfigID
          }
          protocol: 'Tcp'
          frontendPort: pdcRDPPort
          backendPort: 3389
          enableFloatingIP: false
        }
      }
      {
        name: adBDCRDPNAT
        properties: {
          frontendIPConfiguration: {
            id: adlbFEConfigID
          }
          protocol: 'Tcp'
          frontendPort: bdcRDPPort
          backendPort: 3389
          enableFloatingIP: false
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
  ]
}

resource adPDCNicName_resource 'Microsoft.Network/networkInterfaces@2020-03-01' = {
  name: adPDCNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: adPDCNicIPAddress
          subnet: {
            id: adSubnetRef
          }
          loadBalancerBackendAddressPools: [
            {
              id: adBEAddressPoolID
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: adPDCRDPNATRuleID
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    VNet
    adLBName_resource
  ]
}

resource adBDCNicName_resource 'Microsoft.Network/networkInterfaces@2020-03-01' = {
  name: adBDCNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: adBDCNicIPAddress
          subnet: {
            id: adSubnetRef
          }
          loadBalancerBackendAddressPools: [
            {
              id: adBEAddressPoolID
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: adBDCRDPNATRuleID
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    VNet
    adLBName_resource
  ]
}

resource adPDCVMName_resource 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: adPDCVMName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: adVMSize
    }
    availabilitySet: {
      id: adAvailabilitySetName_resource.id
    }
    osProfile: {
      computerName: adPDCVMName
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
        name: '${adPDCVMName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageAccountType
        }
      }
      dataDisks: [
        {
          name: '${adPDCVMName}_data-disk1'
          caching: 'None'
          diskSizeGB: adDataDiskSize
          lun: 0
          createOption: 'Empty'
          managedDisk: {
            storageAccountType: storageAccountType
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: adPDCNicName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    adPDCNicName_resource
    adAvailabilitySetName_resource
    adLBName_resource
  ]
}

resource adPDCVMName_CreateADForest 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  name: '${adPDCVMName}/CreateADForest'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: adPDCModulesURL
      ConfigurationFunction: adPDCConfigurationFunction
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
  dependsOn: [
    adPDCVMName_resource
  ]
}

module UpdateVNetDNS1 '<failed to parse [variables(\'vnetwithDNSTemplateUri\')]>' = {
  name: 'UpdateVNetDNS1'
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressRange: virtualNetworkAddressRange
    subnetName: adSubnetName
    subnetRange: adSubnet
    DNSServerAddress: [
      adPDCNicIPAddress
    ]
  }
  dependsOn: [
    adPDCVMName_CreateADForest
  ]
}

module UpdateBDCNIC '<failed to parse [variables(\'nicTemplateUri\')]>' = {
  name: 'UpdateBDCNIC'
  params: {
    location: location
    nicName: adBDCNicName
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: adBDCNicIPAddress
          subnet: {
            id: adSubnetRef
          }
          loadBalancerBackendAddressPools: [
            {
              id: adBEAddressPoolID
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: adBDCRDPNATRuleID
            }
          ]
        }
      }
    ]
    dnsServers: [
      adPDCNicIPAddress
    ]
  }
  dependsOn: [
    adBDCNicName_resource
    UpdateVNetDNS1
  ]
}

resource adBDCVMName_resource 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: adBDCVMName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: adVMSize
    }
    availabilitySet: {
      id: adAvailabilitySetName_resource.id
    }
    osProfile: {
      computerName: adBDCVMName
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
        name: '${adBDCVMName}_osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageAccountType
        }
      }
      dataDisks: [
        {
          name: '${adBDCVMName}_data-disk1'
          caching: 'None'
          diskSizeGB: adDataDiskSize
          lun: 0
          createOption: 'Empty'
          managedDisk: {
            storageAccountType: storageAccountType
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: adBDCNicName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    adBDCNicName_resource
    adAvailabilitySetName_resource
    adLBName_resource
  ]
}

resource adBDCVMName_PrepareBDC 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  name: '${adBDCVMName}/PrepareBDC'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: adBDCPreparationModulesURL
      ConfigurationFunction: adBDCPreparationFunction
      Properties: {
        DNSServer: adPDCNicIPAddress
      }
    }
  }
  dependsOn: [
    adBDCVMName_resource
  ]
}

module ConfiguringBackupADDomainController '<failed to parse [variables(\'configureADBDCTemplateUri\')]>' = {
  name: 'ConfiguringBackupADDomainController'
  params: {
    adBDCVMName: adBDCVMName
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
    domainName: domainName
    adBDCConfigurationFunction: adBDCConfigurationFunction
    adBDCConfigurationModulesURL: adBDCConfigurationModulesURL
  }
  dependsOn: [
    adBDCVMName_PrepareBDC
    UpdateBDCNIC
  ]
}

module UpdateVNetDNS2 '<failed to parse [variables(\'vnetwithDNSTemplateUri\')]>' = {
  name: 'UpdateVNetDNS2'
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressRange: virtualNetworkAddressRange
    subnetName: adSubnetName
    subnetRange: adSubnet
    DNSServerAddress: [
      adPDCNicIPAddress
      adBDCNicIPAddress
    ]
  }
  dependsOn: [
    ConfiguringBackupADDomainController
  ]
}