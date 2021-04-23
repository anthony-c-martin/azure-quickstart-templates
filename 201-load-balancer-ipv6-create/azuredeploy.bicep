@description('Admin username')
param adminUsername string

@description('Admin password')
@secure()
param adminPassword string

@description('DNS prefix for IPv4 IP Address of the load balancer. It must be lowercase and match the regex: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$.')
param dnsNameforIPv4LbIP string

@description('DNS prefix for IPv6 IP Address of the load balancer. It must be lowercase and match the regex: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$.')
param dnsNameforIPv6LbIP string

var vmNamePrefix_var = 'myIPv6VM'
var nicNamePrefix_var = 'IPv6Nic'
var availabilitySetName_var = 'myIPv6AvSet'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'myIPv4Subnet'
var subnetPrefix = '10.0.0.0/24'
var vnetName_var = 'myIPv4VNet'
var ipv4PrivateIPAddressType = 'Dynamic'
var ipv6PrivateIPAddressType = 'Dynamic'
var numberOfInstances = 2
var ipv6PublicIPAddressName_var = 'myIPv6PublicIP'
var ipv4PublicIPAddressName_var = 'myIPv4PublicIP'
var ipv4PublicIPAddressType = 'Dynamic'
var ipv6PublicIPAddressType = 'Dynamic'
var lbName_var = 'myIPv4IPv6LB'
var lbID = lbName.id
var ipv4FrontEndIPConfigID = '${lbID}/frontendIPConfigurations/LoadBalancerFrontEndIPv4'
var ipv6FrontEndIPConfigID = '${lbID}/frontendIPConfigurations/LoadBalancerFrontEndIPv6'
var ipv4LbBackendPoolID = '${lbID}/backendAddressPools/BackendPoolIPv4'
var ipv6LbBackendPoolID = '${lbID}/backendAddressPools/BackendPoolIPv6'
var ipv4ipv6lbProbeName = 'tcpProbeIPv4IPv6'
var ipv4ipv6lbProbeID = '${lbID}/probes/${ipv4ipv6lbProbeName}'
var networkSecurityGroupName_var = '${subnetName}-nsg'

resource availabilitySetName 'Microsoft.Compute/availabilitySets@2016-04-30-preview' = {
  name: availabilitySetName_var
  location: resourceGroup().location
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 2
    managed: true
  }
}

resource ipv4PublicIPAddressName 'Microsoft.Network/publicIPAddresses@2016-03-30' = {
  name: ipv4PublicIPAddressName_var
  location: resourceGroup().location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: ipv4PublicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameforIPv4LbIP
    }
  }
}

resource ipv6PublicIPAddressName 'Microsoft.Network/publicIPAddresses@2016-03-30' = {
  name: ipv6PublicIPAddressName_var
  location: resourceGroup().location
  properties: {
    publicIPAddressVersion: 'IPv6'
    publicIPAllocationMethod: ipv6PublicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameforIPv6LbIP
    }
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName_var
  location: resourceGroup().location
  properties: {}
}

resource vnetName 'Microsoft.Network/virtualNetworks@2016-03-30' = {
  name: vnetName_var
  location: resourceGroup().location
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
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource nicNamePrefix 'Microsoft.Network/networkInterfaces@2018-01-01' = [for i in range(0, numberOfInstances): {
  name: concat(nicNamePrefix_var, i)
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipv4IPConfig'
        properties: {
          privateIPAddressVersion: 'IPv4'
          privateIPAllocationMethod: ipv4PrivateIPAddressType
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetName)
          }
          loadBalancerBackendAddressPools: [
            {
              id: ipv4LbBackendPoolID
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: '${lbID}/inboundNatRules/RDP-VM${i}'
            }
          ]
        }
      }
      {
        name: 'ipv6IPConfig'
        properties: {
          privateIPAddressVersion: 'IPv6'
          privateIPAllocationMethod: ipv6PrivateIPAddressType
          loadBalancerBackendAddressPools: [
            {
              id: ipv6LbBackendPoolID
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    vnetName
    lbName
  ]
}]

resource lbName 'Microsoft.Network/loadBalancers@2016-03-30' = {
  name: lbName_var
  location: resourceGroup().location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEndIPv4'
        properties: {
          publicIPAddress: {
            id: ipv4PublicIPAddressName.id
          }
        }
      }
      {
        name: 'LoadBalancerFrontEndIPv6'
        properties: {
          publicIPAddress: {
            id: ipv6PublicIPAddressName.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'BackendPoolIPv4'
      }
      {
        name: 'BackendPoolIPv6'
      }
    ]
    inboundNatRules: [
      {
        name: 'RDP-VM0'
        properties: {
          frontendIPConfiguration: {
            id: ipv4FrontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50001
          backendPort: 3389
          enableFloatingIP: false
        }
      }
      {
        name: 'RDP-VM1'
        properties: {
          frontendIPConfiguration: {
            id: ipv4FrontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50002
          backendPort: 3389
          enableFloatingIP: false
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'LBRuleIPv4'
        properties: {
          frontendIPConfiguration: {
            id: ipv4FrontEndIPConfigID
          }
          backendAddressPool: {
            id: ipv4LbBackendPoolID
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: ipv4ipv6lbProbeID
          }
        }
      }
      {
        name: 'LBRuleIPv6'
        properties: {
          frontendIPConfiguration: {
            id: ipv6FrontEndIPConfigID
          }
          backendAddressPool: {
            id: ipv6LbBackendPoolID
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 8080
          probe: {
            id: ipv4ipv6lbProbeID
          }
        }
      }
    ]
    probes: [
      {
        name: ipv4ipv6lbProbeName
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

resource vmNamePrefix 'Microsoft.Compute/virtualMachines@2016-04-30-preview' = [for i in range(0, numberOfInstances): {
  name: concat(vmNamePrefix_var, i)
  location: resourceGroup().location
  properties: {
    availabilitySet: {
      id: availabilitySetName.id
    }
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
    osProfile: {
      computerName: concat(vmNamePrefix_var, i)
      adminUsername: adminUsername
      adminPassword: adminPassword
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
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(nicNamePrefix_var, i))
        }
      ]
    }
  }
  dependsOn: [
    'Microsoft.Network/networkInterfaces/${nicNamePrefix_var}${i}'
    availabilitySetName
  ]
}]