@description('Unique public DNS prefix for the deployment. The fqdn will look something like \'<dnsname>.westus.cloudapp.azure.com\'. Up to 62 chars, digits or dashes, lowercase, should start with a letter: must conform to \'^[a-z][a-z0-9-]{1,61}[a-z0-9]$\'.')
param publicDnsName string

@description('The name of the administrator of the new VM. Exclusion list: \'admin\',\'administrator\'')
param adminUsername string

@description('The password for the administrator account of the new VM')
@secure()
param adminPassword string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Windows Image VM SKU')
param windowsVmSku string = '2019-Datacenter'

@description('SQL VM Image Offer')
param sqlVmOffer string = 'sql2019-ws2019'

@allowed([
  'standard'
  'enterprise'
])
@description('SQL VM Image SKU')
param sqlVmSku string = 'standard'

@description('SQL VM Size')
param sqlVmSize string = 'Standard_A1'

@description('Windows VM Size')
param windowsVmSize string = 'Standard_A1'

var vnetAddressRange = '10.0.0.0/16'
var subnetAddressRange = '10.0.0.0/24'
var subnetName = 'Subnet'
var vnetName_var = 'VNET'
var numberOfInstances = 2
var availabilitySetName_var = 'myavlset'
var vmName_var = 'vm'
var nicsql_var = '${vmName_var}sql'
var newStorageAccountName_var = 'st${uniqueString(resourceGroup().id)}'
var subnet_id = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetName)
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var SQLimagePublisher = 'MicrosoftSQLServer'
var networkSecurityGroupName_var = 'Subnet-nsg'

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-03-01' = {
  name: 'publicIp'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: publicDnsName
    }
  }
}

resource vmsqlIp 'Microsoft.Network/publicIPAddresses@2020-03-01' = {
  name: 'vmsqlIp'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource availabilitySetName 'Microsoft.Compute/availabilitySets@2019-12-01' = {
  name: availabilitySetName_var
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 2
  }
}

resource newStorageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: newStorageAccountName_var
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

resource vnetName 'Microsoft.Network/virtualNetworks@2020-03-01' = {
  name: vnetName_var
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

resource loadBalancer 'Microsoft.Network/loadBalancers@2020-03-01' = {
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
          backendPort: 3389
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
          backendPort: 3389
          enableFloatingIP: false
        }
      }
    ]
    loadBalancingRules: [
      {
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', 'loadBalancer', 'LBFE')
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

resource vmsql 'Microsoft.Network/networkSecurityGroups@2020-03-01' = {
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

resource vmName 'Microsoft.Network/networkInterfaces@2020-03-01' = [for i in range(0, numberOfInstances): {
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
    vnetName
    loadBalancer
  ]
}]

resource nicsql 'Microsoft.Network/networkInterfaces@2020-03-01' = {
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
    vnetName
  ]
}

resource Microsoft_Compute_virtualMachines_vmName 'Microsoft.Compute/virtualMachines@2019-12-01' = [for i in range(0, numberOfInstances): {
  name: concat(vmName_var, i)
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetName.id
    }
    hardwareProfile: {
      vmSize: windowsVmSize
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
        sku: windowsVmSku
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
        storageUri: reference(newStorageAccountName_var).primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    newStorageAccountName
    availabilitySetName
  ]
}]

resource Microsoft_Compute_virtualMachines_vmsql 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: 'vmsql'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: sqlVmSize
    }
    osProfile: {
      computerName: '${vmName_var}sql'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: SQLimagePublisher
        offer: sqlVmOffer
        sku: sqlVmSku
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
        storageUri: reference(newStorageAccountName_var).primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    newStorageAccountName
  ]
}