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
var adPDCVMName_var = 'adPDC'
var adBDCVMName_var = 'adBDC'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var imageSKU = '2016-Datacenter'
var adAvailabilitySetName_var = 'adAvailabiltySet'
var publicIPAddressName_var = 'ad-lb-pip'
var adLBFE = 'LBFE'
var adLBBE = 'LBBE'
var adPDCRDPNAT = 'adPDCRDP'
var adBDCRDPNAT = 'adBDCRDP'
var virtualNetworkName = 'adVNET'
var virtualNetworkAddressRange = '10.0.0.0/16'
var adSubnetName = 'adSubnet'
var adSubnet = '10.0.0.0/24'
var adPDCNicName_var = 'adPDCNic'
var adPDCNicIPAddress = '10.0.0.4'
var adBDCNicName_var = 'adBDCNic'
var adBDCNicIPAddress = '10.0.0.5'
var adSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, adSubnetName)
var adLBName_var = 'adLoadBalancer'
var adlbFEConfigID = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', adLBName_var, adLBFE)
var adPDCRDPNATRuleID = resourceId('Microsoft.Network/loadBalancers/inboundNatRules', adLBName_var, adPDCRDPNAT)
var adBDCRDPNATRuleID = resourceId('Microsoft.Network/loadBalancers/inboundNatRules', adLBName_var, adBDCRDPNAT)
var adBEAddressPoolID = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', adLBName_var, adLBBE)
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

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-03-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsPrefix
    }
  }
}

resource adAvailabilitySetName 'Microsoft.Compute/availabilitySets@2019-12-01' = {
  location: location
  name: adAvailabilitySetName_var
  properties: {
    platformUpdateDomainCount: 20
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

module VNet '?' /*TODO: replace with correct path to [variables('vnetTemplateUri')]*/ = {
  name: 'VNet'
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressRange: virtualNetworkAddressRange
    subnetName: adSubnetName
    subnetRange: adSubnet
  }
}

resource adLBName 'Microsoft.Network/loadBalancers@2020-03-01' = {
  name: adLBName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: adLBFE
        properties: {
          publicIPAddress: {
            id: publicIPAddressName.id
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
}

resource adPDCNicName 'Microsoft.Network/networkInterfaces@2020-03-01' = {
  name: adPDCNicName_var
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
    adLBName
  ]
}

resource adBDCNicName 'Microsoft.Network/networkInterfaces@2020-03-01' = {
  name: adBDCNicName_var
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
    adLBName
  ]
}

resource adPDCVMName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: adPDCVMName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: adVMSize
    }
    availabilitySet: {
      id: adAvailabilitySetName.id
    }
    osProfile: {
      computerName: adPDCVMName_var
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
        name: '${adPDCVMName_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageAccountType
        }
      }
      dataDisks: [
        {
          name: '${adPDCVMName_var}_data-disk1'
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
          id: adPDCNicName.id
        }
      ]
    }
  }
  dependsOn: [
    adLBName
  ]
}

resource adPDCVMName_CreateADForest 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  name: '${adPDCVMName_var}/CreateADForest'
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
    adPDCVMName
  ]
}

module UpdateVNetDNS1 '?' /*TODO: replace with correct path to [variables('vnetwithDNSTemplateUri')]*/ = {
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

module UpdateBDCNIC '?' /*TODO: replace with correct path to [variables('nicTemplateUri')]*/ = {
  name: 'UpdateBDCNIC'
  params: {
    location: location
    nicName: adBDCNicName_var
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
    adBDCNicName
    UpdateVNetDNS1
  ]
}

resource adBDCVMName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: adBDCVMName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: adVMSize
    }
    availabilitySet: {
      id: adAvailabilitySetName.id
    }
    osProfile: {
      computerName: adBDCVMName_var
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
        name: '${adBDCVMName_var}_osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageAccountType
        }
      }
      dataDisks: [
        {
          name: '${adBDCVMName_var}_data-disk1'
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
          id: adBDCNicName.id
        }
      ]
    }
  }
  dependsOn: [
    adLBName
  ]
}

resource adBDCVMName_PrepareBDC 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  name: '${adBDCVMName_var}/PrepareBDC'
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
    adBDCVMName
  ]
}

module ConfiguringBackupADDomainController '?' /*TODO: replace with correct path to [variables('configureADBDCTemplateUri')]*/ = {
  name: 'ConfiguringBackupADDomainController'
  params: {
    adBDCVMName: adBDCVMName_var
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

module UpdateVNetDNS2 '?' /*TODO: replace with correct path to [variables('vnetwithDNSTemplateUri')]*/ = {
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