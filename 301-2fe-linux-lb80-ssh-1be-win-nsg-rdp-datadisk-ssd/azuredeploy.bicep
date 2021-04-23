@description('Unique public DNS prefix for the deployment. Up to 62 chars, digits or dashes, lowercase, should start with a letter: must conform to \'^[a-z][a-z0-9-]{1,61}[a-z0-9]$\'.')
param publicDnsName string

@description('The name of the administrator of the new VM. Exclusion list: \'admin\',\'administrator\'')
param adminUsername string

@description('The password for the administrator account of the new VM')
@secure()
param adminPassword string

@minValue(128)
@maxValue(1024)
@description('Size of data disk in GB 128-1024')
param sizeOfDiskInGB int = 128

@description('VM size allowed for Front End')
param vmSizeFE string = 'Standard_D2s_v3'

@description('VM size allowed for SQL Server Back End')
param vmSizeSQL string = 'Standard_D2s_v3'

@description('Location for all resources.')
param location string = resourceGroup().location

var vnetAddressRange = '10.0.0.0/16'
var subnetAddressRange = '10.0.0.0/24'
var subnetName = 'Subnet'
var numberOfInstances = 2
var availabilitySetName = 'myavlset'
var vmName_var = 'vm'
var nicsql_var = '${vmName_var}sql'
var storageAccountNameDiag_var = 'diag${uniqueString(resourceGroup().id)}'
var subnet_id = resourceId('Microsoft.Network/virtualNetworks/subnets', 'VNET', subnetName)
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var imageSku = '14.04.5-LTS'
var SQLimagePublisher = 'MicrosoftSQLServer'
var SQLimageOffer = 'sql2019-ws2019'
var SQLimageSku = 'Standard'
var networkSecurityGroupName_var = 'Subnet-nsg'

resource publicIp 'Microsoft.Network/publicIPAddresses@2019-08-01' = {
  name: 'publicIp'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: publicDnsName
    }
  }
}

resource vmsqlIp 'Microsoft.Network/publicIPAddresses@2019-08-01' = {
  name: 'vmsqlIp'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource myavlset 'Microsoft.Compute/availabilitySets@2019-12-01' = {
  name: 'myavlset'
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 2
  }
}

resource storageAccountNameDiag 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountNameDiag_var
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {}
}

resource VNET 'Microsoft.Network/virtualNetworks@2019-08-01' = {
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
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource loadBalancer 'Microsoft.Network/loadBalancers@2018-10-01' = {
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
        name: 'rdp0'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'loadBalancer', 'LBFE')
          }
          protocol: 'Tcp'
          frontendPort: 6001
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: 'rdp1'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'loadBalancer', 'LBFE')
          }
          protocol: 'Tcp'
          frontendPort: 6002
          backendPort: 22
          enableFloatingIP: false
        }
      }
    ]
    loadBalancingRules: [
      {
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'loadBalancer', 'LBFE')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'loadBalancer', 'LBBAP')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'loadBalancer', 'lbprobe')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 15
        }
        name: 'lbrule'
      }
    ]
    probes: [
      {
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 15
          numberOfProbes: 2
        }
        name: 'lbprobe'
      }
    ]
  }
}

resource vmsql 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: 'vmsql'
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-rdp'
        properties: {
          description: 'Allow RDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vmName 'Microsoft.Network/networkInterfaces@2019-08-01' = [for i in range(0, numberOfInstances): {
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
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'loadBalancer', 'LBBAP')
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', 'loadBalancer', 'rdp${i}')
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

resource nicsql 'Microsoft.Network/networkInterfaces@2019-08-01' = {
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

resource Microsoft_Compute_virtualMachines_vmName 'Microsoft.Compute/virtualMachines@2019-12-01' = [for i in range(0, numberOfInstances): {
  name: concat(vmName_var, i)
  location: location
  properties: {
    availabilitySet: {
      id: resourceId('Microsoft.Compute/availabilitySets', availabilitySetName)
    }
    hardwareProfile: {
      vmSize: vmSizeFE
    }
    osProfile: {
      computerName: concat(vmName_var, i)
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
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
        storageUri: reference(storageAccountNameDiag_var, '2019-06-01').primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    storageAccountNameDiag
    resourceId('Microsoft.Network/networkInterfaces', concat(vmName_var, i))
    resourceId('Microsoft.Compute/availabilitySets', availabilitySetName)
  ]
}]

resource Microsoft_Compute_virtualMachines_vmsql 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: 'vmsql'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSizeSQL
    }
    osProfile: {
      computerName: '${vmName_var}sql'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: SQLimagePublisher
        offer: SQLimageOffer
        sku: SQLimageSku
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          diskSizeGB: sizeOfDiskInGB
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
        }
        {
          diskSizeGB: sizeOfDiskInGB
          lun: 1
          createOption: 'Empty'
        }
      ]
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
        storageUri: reference(storageAccountNameDiag_var, '2019-06-01').primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    storageAccountNameDiag
  ]
}