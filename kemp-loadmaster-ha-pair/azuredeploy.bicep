@description('Password for bal account')
@secure()
param balPassword string

@description('Location for all resources.')
param location string = resourceGroup().location

var availabilitySetName_var = 'AvSet'
var vmNamePrefix_var = 'KEMPVLM'
var loadBalancerName_var = 'AzureLB'
var adminUsername = 'bal'
var virtualNetworkName_var = 'VLM_Network'
var subnetName = 'Subnet1'
var vmSize = 'Standard_A1'
var networkinterfacename_var = '${vmNamePrefix_var}-NIC'
var networksecurityname_var = '${vmNamePrefix_var}-NSG'
var publicIPAddressName_var = '${vmNamePrefix_var}-PIP'
var dnsNameforLBIP = 'vlm${uniqueString(resourceGroup().id)}'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/Subnets', virtualNetworkName_var, subnetName)
var numberOfInstances = 2
var lbID = loadBalancerName.id
var imageSKU = 'basic-byol'
var publicIPAddressType = 'Dynamic'
var publicIPAddressID = publicIPAddressName.id
var imageOffer = 'vlm-azure'
var imagePublisher = 'kemptech'
var imageVersion = 'latest'
var storageAccountName_var = 'vhds${uniqueString(resourceGroup().id)}'
var frontEndIPConfigID = '${lbID}/frontendIPConfigurations/loadBalancerFrontEnd'
var imageReference = {
  publisher: imagePublisher
  offer: imageOffer
  sku: imageSKU
  version: imageVersion
}
var imagePlan = {
  name: imageSKU
  product: imageOffer
  publisher: imagePublisher
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
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

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: virtualNetworkName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameforLBIP
    }
  }
}

resource networksecurityname 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: networksecurityname_var
  location: location
  tags: {
    displayName: networksecurityname_var
  }
  properties: {
    securityRules: [
      {
        name: 'wui-rule'
        properties: {
          description: 'Allow WUI'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'ssh-rule'
        properties: {
          description: 'Allow SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
      {
        name: 'ssl-rule'
        properties: {
          description: 'Allow SSL'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 103
          direction: 'Inbound'
        }
      }
      {
        name: 'web-rule'
        properties: {
          description: 'Allow WEB'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 104
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource networkinterfacename 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, numberOfInstances): {
  name: concat(networkinterfacename_var, i)
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
          networkSecurityGroup: {
            id: networksecurityname.id
          }
          loadBalancerBackendAddressPools: [
            {
              id: '${lbID}/backendAddressPools/BackendPool1'
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: '${lbID}/inboundNatRules/VLM-MGMT${i}'
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
    loadBalancerName
    'Microsoft.Network/loadBalancers/${loadBalancerName_var}/inboundNatRules/VLM-MGMT${i}'
    networksecurityname
  ]
}]

resource loadBalancerName 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: loadBalancerName_var
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
        name: 'BackendPool1'
      }
    ]
    loadBalancingRules: [
      {
        properties: {
          frontendIPConfiguration: {
            id: '${loadBalancerName.id}/frontendIpConfigurations/LoadBalancerFrontend'
          }
          backendAddressPool: {
            id: '${loadBalancerName.id}/backendAddressPools/BackendPool1'
          }
          probe: {
            id: '${loadBalancerName.id}/probes/VLM-Health-Probe'
          }
          protocol: 'Tcp'
          frontendPort: 8444
          backendPort: 8444
          idleTimeoutInMinutes: 15
        }
        name: 'HealthCheck'
      }
    ]
    probes: [
      {
        properties: {
          protocol: 'Http'
          port: 8444
          requestPath: '/'
          intervalInSeconds: 5
          numberOfProbes: 2
        }
        name: 'VLM-Health-Probe'
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource loadBalancerName_VLM_MGMT 'Microsoft.Network/loadBalancers/inboundNatRules@2015-06-15' = [for i in range(0, numberOfInstances): {
  name: '${loadBalancerName_var}/VLM-MGMT${i}'
  location: location
  properties: {
    frontendIPConfiguration: {
      id: frontEndIPConfigID
    }
    protocol: 'Tcp'
    frontendPort: (i + 8441)
    backendPort: 8443
    enableFloatingIP: false
  }
  dependsOn: [
    loadBalancerName
  ]
}]

resource vmNamePrefix 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, numberOfInstances): {
  name: concat(vmNamePrefix_var, i)
  plan: imagePlan
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetName.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(vmNamePrefix_var, i)
      adminUsername: adminUsername
      adminPassword: balPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: imageVersion
      }
      osDisk: {
        name: '${vmNamePrefix_var}${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(networkinterfacename_var, i))
        }
      ]
    }
  }
  dependsOn: [
    storageAccountName
    'Microsoft.Network/networkInterfaces/${networkinterfacename_var}${i}'
    availabilitySetName
  ]
}]

output FQDN string = reference(publicIPAddressName.id, '2015-06-15').dnsSettings.fqdn