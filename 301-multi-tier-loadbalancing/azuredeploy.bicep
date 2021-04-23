@minLength(1)
@description('Azure Region valid name')
param region1_Location_Name string

@minLength(1)
@description('Azure Region valid name')
param region2_Location_Name string

@minLength(1)
@description('Traffice Manager profile name')
param trafficManagerProfile_name string = 'gentm'

@minLength(1)
@description('Admin username')
param adminuser string

@minLength(1)
@description('Admin Password')
@secure()
param adminuserPassword string

@minLength(1)
@description('Application prefix name, should be <= 10 characters')
param app_prefix string

@allowed([
  '2019-Datacenter'
  '2016-Datacenter'
  '2008-R2-SP1'
  '2012-Datacenter'
  '2012-R2-Datacenter'
])
@description('The Windows version for the VM')
param imageSKU string = '2019-Datacenter'

@minLength(1)
@description('Size of the virtual machine, must be available in the virtual machine\'s location')
param vmSize string = 'Standard_D1_v2'

@minValue(1)
@maxValue(10)
@description('Number of VM instances to be created behind internal load balancer control')
param numberOfVMInstances int = 2

@minLength(1)
@description('Loadbalancer dns name should be lowercase letters')
param loadbalancer_dns_prefix string

@allowed([
  'Standard_Small'
  'Standard_Medium'
  'Standard_Large'
])
@description('Choose Application gateway SKU!')
param appGW_skuName string = 'Standard_Small'

@minValue(1)
@maxValue(10)
@description('Number of Application Gateway instances')
param appGW_capacity int = 4

@description('Path match string for Path Rule 1')
param appGW_pathMatch1 string

@description('Path match string for Path Rule 2')
param appGW_pathMatch2 string

var app_prefix_var = toLower(replace(replace(substring(app_prefix, 0, 4), ' ', ''), '-', ''))
var front_end_subnetref1 = '${region1_vnet_id}/subnets/${vnet_front_end_subnet}'
var imageOffer = 'WindowsServer'
var imagePublisher = 'MicrosoftWindowsServer'
var region = [
  region1_Location_Name
  region2_Location_Name
]
var region1_vnet_id = resourceId('Microsoft.Network/virtualNetworks', '${region_vnet_name_var}0')
var region1_web_vm_nic_var = '${app_prefix_var}-web-vm-nic-rg1-'
var region1_web_vm_pip_var = '${app_prefix_var}-web-vm-pip-rg1-'
var region1_web_vmsprefix_var = '${app_prefix_var}webvmrg1'
var region2_web_vm_nic_var = '${app_prefix_var}-web-vm-nic-rg2-'
var region2_web_vm_pip_var = '${app_prefix_var}-web-vm-pip-rg2-'
var region2_web_vmsprefix_var = '${app_prefix_var}webvmrg2'
var region_appgw_name_var = 'region-appgw-'
var region_appgw_pip_var = 'region-appgw-pip-'
var region_availabilitySet_var = 'region_AvSet'
var region_storage_account_var = 'rg${uniqueString(resourceGroup().id)}'
var region_tm_test_vm_var = '${app_prefix_var}-tm-vm-rg'
var region_tm_vm_nic_var = '${region_tm_test_vm_var}-nic'
var region_tm_vm_pip_var = '${region_tm_test_vm_var}-pip'
var region_vnet_name_var = 'region-multitierlb-vnet'
var region_web_ilb_pip_var = '${loadbalancer_dns_prefix}rg'
var region_web_lb_var = '${loadbalancer_dns_prefix}rg'
var vnet_appGW_subnet = 'appGatewaySubnet'
var vnet_front_end_subnet = 'front-end-subnet'
var vnet_lb_subnet = 'lb-subnet'
var networkSecurityGroupNames = {
  defaultSubnet: [for j in range(0, 2): '${region_vnet_name_var}${j}-default-nsg']
  frontEndSubnet: [for j in range(0, 2): '${region_vnet_name_var}${j}-${vnet_front_end_subnet}-nsg']
}
var networkSecurityGroupAllowRdpRule = [
  {
    name: 'Allow-RDP'
    properties: {
      priority: 1000
      access: 'Allow'
      direction: 'Inbound'
      destinationPortRange: '3389'
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
    }
  }
]

resource region_storage_account 'Microsoft.Storage/storageAccounts@2016-01-01' = [for i in range(0, 2): {
  name: concat(region_storage_account_var, i)
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'Storage'
  location: region[i]
  tags: {
    displayName: 'storage-accounts'
  }
  properties: {}
}]

resource networkSecurityGroupNames_defaultSubnet 'Microsoft.Network/networkSecurityGroups@2019-08-01' = [for i in range(0, 2): {
  name: networkSecurityGroupNames.defaultSubnet[i]
  location: region[i]
  properties: {
    securityRules: networkSecurityGroupAllowRdpRule
  }
}]

resource networkSecurityGroupNames_frontEndSubnet 'Microsoft.Network/networkSecurityGroups@2019-08-01' = [for i in range(0, 2): {
  name: networkSecurityGroupNames.frontEndSubnet[i]
  location: region[i]
  properties: {
    securityRules: networkSecurityGroupAllowRdpRule
  }
}]

resource region_vnet_name 'Microsoft.Network/virtualNetworks@2016-03-30' = [for i in range(0, 2): {
  name: concat(region_vnet_name_var, i)
  location: region[i]
  tags: {
    displayName: 'vnetloop'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.4.0/24'
          networkSecurityGroup: {
            id: resourceId('Microsoft.Network/networkSecurityGroups', networkSecurityGroupNames.defaultSubnet[i])
          }
        }
      }
      {
        name: vnet_front_end_subnet
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: {
            id: resourceId('Microsoft.Network/networkSecurityGroups', networkSecurityGroupNames.frontEndSubnet[i])
          }
        }
      }
      {
        name: vnet_lb_subnet
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: vnet_appGW_subnet
        properties: {
          addressPrefix: '10.0.3.0/28'
        }
      }
    ]
  }
  dependsOn: [
    networkSecurityGroupNames_defaultSubnet
    networkSecurityGroupNames_frontEndSubnet
  ]
}]

resource region_web_ilb_pip 'Microsoft.Network/publicIPAddresses@2015-06-15' = [for i in range(0, 2): {
  name: concat(region_web_ilb_pip_var, i)
  location: region[i]
  tags: {
    displayName: 'region-web-ilb-pips'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: toLower(concat(region_web_lb_var, i))
    }
  }
}]

resource region_web_lb 'Microsoft.Network/loadBalancers@2015-06-15' = [for i in range(0, 2): {
  name: concat(region_web_lb_var, i)
  location: region[i]
  tags: {
    displayName: 'region-web-lbs'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontend'
        properties: {
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', concat(region_web_ilb_pip_var, i))
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'BackendPool1'
      }
    ]
    probes: [
      {
        name: 'lbprobe'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 15
          numberOfProbes: 2
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'lbrule'
        properties: {
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/loadBalancers', concat(region_web_lb_var, i))}/frontendIPConfigurations/LoadBalancerFrontend'
          }
          backendAddressPool: {
            id: '${resourceId('Microsoft.Network/loadBalancers', concat(region_web_lb_var, i))}/backendAddressPools/BackendPool1'
          }
          probe: {
            id: '${resourceId('Microsoft.Network/loadBalancers', concat(region_web_lb_var, i))}/probes/lbprobe'
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 15
        }
      }
    ]
  }
  dependsOn: [
    region_web_ilb_pip
  ]
}]

resource region_tm_vm_pip 'Microsoft.Network/publicIPAddresses@2016-03-30' = [for i in range(0, 2): {
  name: concat(region_tm_vm_pip_var, i)
  location: region[i]
  tags: {
    displayName: 'region-tm-vm-pips'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: toLower(concat(region_tm_test_vm_var, i))
    }
    idleTimeoutInMinutes: 4
  }
}]

resource region_tm_vm_nic 'Microsoft.Network/networkInterfaces@2016-03-30' = [for i in range(0, 2): {
  name: concat(region_tm_vm_nic_var, i)
  location: region[i]
  tags: {
    displayName: 'region-tm-vm-nics'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: '10.0.4.4'
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', concat(region_tm_vm_pip_var, i))
          }
          subnet: {
            id: '${resourceId('Microsoft.Network/virtualNetworks', concat(region_vnet_name_var, i))}/subnets/default'
          }
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableIPForwarding: false
  }
  dependsOn: [
    region_vnet_name
    region_tm_vm_pip
  ]
}]

resource region_tm_test_vm 'Microsoft.Compute/virtualMachines@2016-04-30-preview' = [for i in range(0, 2): {
  name: concat(region_tm_test_vm_var, i)
  location: region[i]
  tags: {
    displayName: 'regions-test-vms'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2012-R2-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
      }
      dataDisks: []
    }
    osProfile: {
      computerName: replace(replace(concat(region_tm_test_vm_var, i), '_', ''), '-', '')
      adminUsername: adminuser
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
      secrets: []
      adminPassword: adminuserPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(region_tm_vm_nic_var, i))
        }
      ]
    }
  }
  dependsOn: [
    region_tm_vm_pip
    region_tm_vm_nic
  ]
}]

resource region_availabilitySet 'Microsoft.Compute/availabilitySets@2017-12-01' = [for i in range(0, 2): {
  name: concat(region_availabilitySet_var, i)
  location: region[i]
  tags: {
    displayName: 'Region-availabilitySets'
  }
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 2
  }
}]

resource region1_web_vm_nic 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, numberOfVMInstances): {
  name: concat(region1_web_vm_nic_var, i)
  location: region[0]
  tags: {
    displayName: 'region1-web-vm-nics'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: front_end_subnetref1
          }
          loadBalancerBackendAddressPools: [
            {
              id: '${resourceId('Microsoft.Network/loadBalancers', '${region_web_lb_var}0')}/backendAddressPools/BackendPool1'
            }
          ]
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', concat(region1_web_vm_pip_var, i))
          }
        }
      }
    ]
  }
  dependsOn: [
    region_vnet_name
    region_web_lb
    region1_web_vm_pip
  ]
}]

resource region1_web_vmsprefix 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, numberOfVMInstances): {
  name: concat(region1_web_vmsprefix_var, i)
  location: region[0]
  tags: {
    displayName: 'Region1-web-vms'
  }
  properties: {
    availabilitySet: {
      id: resourceId('Microsoft.Compute/availabilitySets', '${region_availabilitySet_var}0')
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: replace(concat(region1_web_vmsprefix_var, i), '-', '')
      adminUsername: adminuser
      adminPassword: adminuserPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(region1_web_vm_nic_var, i))
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: concat(reference('Microsoft.Storage/storageAccounts/${region_storage_account_var}0', '2015-06-15').primaryEndpoints.blob)
      }
    }
  }
  dependsOn: [
    region_storage_account
    region1_web_vm_nic
    region1_web_vm_pip
    region_availabilitySet
  ]
}]

resource region1_web_vm_pip 'Microsoft.Network/publicIPAddresses@2015-06-15' = [for i in range(0, numberOfVMInstances): {
  name: concat(region1_web_vm_pip_var, i)
  location: region[0]
  tags: {
    displayName: 'region1-web-vm-pip'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: concat(region1_web_vmsprefix_var, i)
    }
  }
}]

resource region2_web_vm_nic 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, numberOfVMInstances): {
  name: concat(region2_web_vm_nic_var, i)
  location: region[1]
  tags: {
    displayName: 'region2-web-vm-nics'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${resourceId('Microsoft.Network/virtualNetworks', '${region_vnet_name_var}1')}/subnets/front-end-subnet'
          }
          loadBalancerBackendAddressPools: [
            {
              id: '${resourceId('Microsoft.Network/loadBalancers', '${region_web_lb_var}1')}/backendAddressPools/BackendPool1'
            }
          ]
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', concat(region2_web_vm_pip_var, i))
          }
        }
      }
    ]
  }
  dependsOn: [
    region_vnet_name
    region_web_lb
    region2_web_vm_pip
  ]
}]

resource region2_web_vmsprefix 'Microsoft.Compute/virtualMachines@2016-04-30-preview' = [for i in range(0, numberOfVMInstances): {
  name: concat(region2_web_vmsprefix_var, i)
  location: region[1]
  tags: {
    displayName: 'region2-web-vms'
  }
  properties: {
    availabilitySet: {
      id: resourceId('Microsoft.Compute/availabilitySets', '${region_availabilitySet_var}1')
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: replace(concat(region2_web_vmsprefix_var, i), '-', '')
      adminUsername: adminuser
      adminPassword: adminuserPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(region2_web_vm_nic_var, i))
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: concat(reference('Microsoft.Storage/storageAccounts/${region_storage_account_var}1', '2015-06-15').primaryEndpoints.blob)
      }
    }
  }
  dependsOn: [
    region_storage_account
    region2_web_vm_nic
    region2_web_vm_pip
    region_availabilitySet
  ]
}]

resource region2_web_vm_pip 'Microsoft.Network/publicIPAddresses@2015-06-15' = [for i in range(0, numberOfVMInstances): {
  name: concat(region2_web_vm_pip_var, i)
  location: region[1]
  tags: {
    displayName: 'region2-web-vm-pip'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: concat(region2_web_vmsprefix_var, i)
    }
  }
}]

resource region_appgw_pip 'Microsoft.Network/publicIPAddresses@2016-03-30' = [for i in range(0, 2): {
  name: concat(region_appgw_pip_var, i)
  location: region[i]
  tags: {
    displayName: 'region-appgw-pips'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}]

resource region_appgw_name 'Microsoft.Network/applicationGateways@2017-06-01' = [for i in range(0, 2): {
  name: concat(region_appgw_name_var, i)
  location: region[i]
  tags: {
    displayName: 'region-appgws'
  }
  properties: {
    sku: {
      name: appGW_skuName
      tier: 'Standard'
      capacity: appGW_capacity
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: '${resourceId('Microsoft.Network/virtualNetworks', concat(region_vnet_name_var, i))}/subnets/${vnet_appGW_subnet}'
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGateway-Frontend-PIP'
        properties: {
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', concat(region_appgw_pip_var, i))
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPoolDefault'
        properties: {
          backendAddresses: [
            {
              fqdn: reference('Microsoft.Network/publicIPAddresses/${region_web_ilb_pip_var}${i}').dnsSettings.fqdn
            }
          ]
          requestRoutingRules: [
            {
              Id: '${resourceId('Microsoft.Network/applicationGateways', concat(region_appgw_name_var, i))}/requestRoutingRules/rule1'
            }
          ]
        }
      }
      {
        name: 'appGatewayBackendPool1'
        properties: {
          backendAddresses: [
            {
              fqdn: reference('Microsoft.Network/publicIPAddresses/${region1_web_vm_pip_var}0').dnsSettings.fqdn
            }
          ]
          requestRoutingRules: [
            {
              Id: '${resourceId('Microsoft.Network/applicationGateways', concat(region_appgw_name_var, i))}/requestRoutingRules/rule1'
            }
          ]
        }
      }
      {
        name: 'appGatewayBackendPool2'
        properties: {
          backendAddresses: []
          requestRoutingRules: [
            {
              Id: '${resourceId('Microsoft.Network/applicationGateways', concat(region_appgw_name_var, i))}/requestRoutingRules/rule1'
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/applicationGateways', concat(region_appgw_name_var, i))}/frontendIPConfigurations/appGateway-Frontend-PIP'
          }
          frontendPort: {
            id: '${resourceId('Microsoft.Network/applicationGateways', concat(region_appgw_name_var, i))}/frontendPorts/appGatewayFrontendPort80'
          }
          protocol: 'Http'
          requireServerNameIndication: false
          sslCertificate: null
        }
      }
    ]
    urlPathMaps: [
      {
        name: 'urlPathMap1'
        properties: {
          defaultBackendAddressPool: {
            id: '${resourceId('Microsoft.Network/applicationGateways', concat(region_appgw_name_var, i))}/backendAddressPools/appGatewayBackendPoolDefault'
          }
          defaultBackendHttpSettings: {
            id: '${resourceId('Microsoft.Network/applicationGateways', concat(region_appgw_name_var, i))}/backendHttpSettingsCollection/appGatewayBackendHttpSettings'
          }
          pathRules: [
            {
              name: 'pathRule1'
              properties: {
                paths: [
                  appGW_pathMatch1
                ]
                backendAddressPool: {
                  id: '${resourceId('Microsoft.Network/applicationGateways', concat(region_appgw_name_var, i))}/backendAddressPools/appGatewayBackendPool1'
                }
                backendHttpSettings: {
                  id: '${resourceId('Microsoft.Network/applicationGateways', concat(region_appgw_name_var, i))}/backendHttpSettingsCollection/appGatewayBackendHttpSettings'
                }
              }
            }
            {
              name: 'pathRule2'
              properties: {
                paths: [
                  appGW_pathMatch2
                ]
                backendAddressPool: {
                  id: '${resourceId('Microsoft.Network/applicationGateways', concat(region_appgw_name_var, i))}/backendAddressPools/appGatewayBackendPool2'
                }
                backendHttpSettings: {
                  id: '${resourceId('Microsoft.Network/applicationGateways', concat(region_appgw_name_var, i))}/backendHttpSettingsCollection/appGatewayBackendHttpSettings'
                }
              }
            }
          ]
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'PathBasedRouting'
          httpListener: {
            id: '${resourceId('Microsoft.Network/applicationGateways', concat(region_appgw_name_var, i))}/httpListeners/appGatewayHttpListener'
          }
          urlPathMap: {
            id: '${resourceId('Microsoft.Network/applicationGateways', concat(region_appgw_name_var, i))}/urlPathMaps/urlPathMap1'
          }
        }
      }
    ]
  }
  dependsOn: [
    region_vnet_name
    region_appgw_pip
    region_web_lb
  ]
}]

resource trafficManagerProfile_name_resource 'Microsoft.Network/trafficManagerProfiles@2015-11-01' = {
  name: trafficManagerProfile_name
  location: 'global'
  tags: {
    displayName: 'Global-TrafficProfile'
  }
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: 'Performance'
    dnsConfig: {
      relativeName: trafficManagerProfile_name
      ttl: 300
    }
    monitorConfig: {
      protocol: 'HTTP'
      port: 80
      path: '/'
    }
    endpoints: [
      {
        name: 'region1-endpoint'
        type: 'Microsoft.Network/trafficManagerProfiles/azureEndpoints'
        properties: {
          endpointStatus: 'Enabled'
          targetResourceId: resourceId('Microsoft.Network/publicIPAddresses', '${region_appgw_pip_var}0')
          target: '${region_appgw_pip_var}0'
          weight: 1
          priority: 1
          endpointLocation: region[0]
        }
      }
      {
        name: 'region2-endpoint'
        type: 'Microsoft.Network/trafficManagerProfiles/azureEndpoints'
        properties: {
          endpointStatus: 'Enabled'
          targetResourceId: resourceId('Microsoft.Network/publicIPAddresses', '${region_appgw_pip_var}1')
          target: '${region_appgw_pip_var}1'
          weight: 1
          priority: 2
          endpointLocation: region[1]
        }
      }
    ]
  }
  dependsOn: [
    region_appgw_name
  ]
}