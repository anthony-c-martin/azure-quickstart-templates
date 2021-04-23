@description('Location for the VMs, only certain regions support zones.')
param location string = resourceGroup().location

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Unique DNS Name for the Public IP for the frontend load balancer.')
param dnsName string

@allowed([
  'Windows'
  'Ubuntu'
])
@description('Operation System for the Virtual Machine.')
param windowsOrUbuntu string = 'Ubuntu'

@minValue(1)
@maxValue(10)
@description('Number of VMs to provision')
param numberOfVms int = 3

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('Size of the virtual machine')
param vmSize string = 'Standard_A2_v2'

var storageAccountName_var = 'diags${uniqueString(resourceGroup().id)}'
var nicName_var = 'myVMNic'
var subnetName = 'Subnet-1'
var publicIPAddressName_var = 'myPublicIP'
var virtualNetworkName_var = 'MyVNET'
var networkSecurityGroupName_var = 'allowRemoting'
var lbName_var = 'multiVMLB'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName_var, subnetName)
var frontEndIPConfigID = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName_var, 'loadBalancerFrontend')
var inboundNatRuleName = 'remoting'
var windowsImage = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2019-Datacenter'
  version: 'latest'
}
var linuxImage = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: '18.04-LTS'
  version: 'latest'
}
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

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {}
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName_var
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: dnsName
    }
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'RemoteConnection'
        properties: {
          description: 'Allow RDP/SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: ((windowsOrUbuntu == 'Windows') ? 3389 : 22)
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, numberOfVms): {
  name: concat(nicName_var, i)
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
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName_var, 'LoadBalancerBackend')
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', lbName_var, concat(inboundNatRuleName, i))
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
    lbName
    lbName_inboundNatRuleName
  ]
}]

resource lbName 'Microsoft.Network/loadBalancers@2020-05-01' = {
  name: lbName_var
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontend'
        properties: {
          publicIPAddress: {
            id: publicIPAddressName.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'LoadBalancerBackend'
      }
    ]
    loadBalancingRules: [
      {
        name: 'port80'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName_var, 'LoadBalancerBackend')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName_var, 'tcpProbe')
          }
        }
      }
    ]
    probes: [
      {
        name: 'tcpProbe'
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

resource lbName_inboundNatRuleName 'Microsoft.Network/loadBalancers/inboundNatRules@2020-05-01' = [for i in range(0, numberOfVms): {
  name: '${lbName_var}/${inboundNatRuleName}${i}'
  location: location
  properties: {
    frontendIPConfiguration: {
      id: frontEndIPConfigID
    }
    protocol: 'Tcp'
    frontendPort: (i + 50000)
    backendPort: ((windowsOrUbuntu == 'Windows') ? 3389 : 22)
    enableFloatingIP: false
  }
  dependsOn: [
    lbName
  ]
}]

resource dnsName_resource 'Microsoft.Compute/virtualMachines@2019-12-01' = [for i in range(0, numberOfVms): {
  name: concat(dnsName, i)
  zones: split(string(((i % 3) + 1)), ',')
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(dnsName, i)
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: ((windowsOrUbuntu == 'Windows') ? windowsImage : linuxImage)
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(nicName_var, i))
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccountName.properties.primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    nicName
  ]
}]

output hostname string = reference(publicIPAddressName_var).dnsSettings.fqdn