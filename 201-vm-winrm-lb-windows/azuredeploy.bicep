@description('Admin username')
param adminUsername string

@description('Admin password')
@secure()
param adminPassword string

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix string

@description('Virtual machine name prefix for primary vm instances')
param PrimaryVmNamePrefix string = 'myVM'

@description('Virtual machine name prefix for secondary vm instances')
param SecondaryVmNamePrefix string = 'mytestVM'

@allowed([
  '2012-Datacenter'
  '2012-R2-Datacenter'
])
@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version. Allowed values: 2012-Datacenter, 2012-R2-Datacenter.')
param imageSKU string = '2012-R2-Datacenter'

@allowed([
  'Standard_A0'
  'Standard_A1'
  'Standard_A2'
  'Standard_A3'
  'Standard_A4'
])
@description('Virtual machine size')
param vmSize string = 'Standard_A1'

var availabilitySetName_var = 'myAvSet'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet-1'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressType = 'Dynamic'
var vnetName_var = 'myVNET'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetName)
var publicIPAddressName_var = 'myPublicIP'
var publicIPAddressID = publicIPAddressName.id
var lbName_var = 'myLB'
var lbID = lbName.id
var numberOfInstances = 1
var frontEndIPConfigID = '${lbID}/frontendIPConfigurations/loadBalancerFrontend'
var lbPoolID = '${lbID}/backendAddressPools/LoadBalancerBackend'
var lbProbeID = '${lbID}/probes/tcpProbe'
var apiVersion = '2015-06-15'
var hostDNSNameScriptArgument = '*.${resourceGroup().location}.cloudapp.azure.com'
var primaryNicNamePrefix_var = 'nic'
var secondaryNicNamePrefix_var = 'nicN'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'

resource availabilitySetName 'Microsoft.Compute/availabilitySets@2016-04-30-preview' = {
  name: availabilitySetName_var
  location: resourceGroup().location
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 2
    managed: true
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName_var
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource vnetName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
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
        }
      }
    ]
  }
}

resource primaryNicNamePrefix 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, numberOfInstances): {
  name: concat(primaryNicNamePrefix_var, i)
  location: resourceGroup().location
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
              id: '${lbID}/backendAddressPools/LoadBalancerBackend'
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: '${lbID}/inboundNatRules/PRDP-VM${i}'
            }
            {
              id: '${lbID}/inboundNatRules/PWINRM-VM${i}'
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

resource secondaryNicNamePrefix 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, numberOfInstances): {
  name: concat(secondaryNicNamePrefix_var, i)
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig2'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
          loadBalancerBackendAddressPools: [
            {
              id: '${lbID}/backendAddressPools/LoadBalancerBackend'
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: '${lbID}/inboundNatRules/SRDP-VM${i}'
            }
            {
              id: '${lbID}/inboundNatRules/SWINRM-VM${i}'
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

resource lbName 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: lbName_var
  location: resourceGroup().location
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
        name: 'LoadBalancerBackend'
      }
    ]
    inboundNatRules: [
      {
        name: 'PRDP-VM0'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50001
          backendPort: 3389
          enableFloatingIP: false
        }
      }
      {
        name: 'PRDP-VM1'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50002
          backendPort: 3389
          enableFloatingIP: false
        }
      }
      {
        name: 'PWINRM-VM0'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 40001
          backendPort: 5986
          enableFloatingIP: false
        }
      }
      {
        name: 'PWINRM-VM1'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 40002
          backendPort: 5986
          enableFloatingIP: false
        }
      }
      {
        name: 'SRDP-VM0'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50003
          backendPort: 3389
          enableFloatingIP: false
        }
      }
      {
        name: 'SRDP-VM1'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50004
          backendPort: 3389
          enableFloatingIP: false
        }
      }
      {
        name: 'SWINRM-VM0'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 40003
          backendPort: 5986
          enableFloatingIP: false
        }
      }
      {
        name: 'SWINRM-VM1'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 40004
          backendPort: 5986
          enableFloatingIP: false
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'LBRule'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          backendAddressPool: {
            id: lbPoolID
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: lbProbeID
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

resource primaryVmNamePrefix_resource 'Microsoft.Compute/virtualMachines@2016-04-30-preview' = [for i in range(0, numberOfInstances): {
  name: concat(PrimaryVmNamePrefix, i)
  location: resourceGroup().location
  tags: {
    Role: 'Web'
  }
  properties: {
    availabilitySet: {
      id: availabilitySetName.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(PrimaryVmNamePrefix, i)
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
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(primaryNicNamePrefix_var, i))
        }
      ]
    }
  }
  dependsOn: [
    'Microsoft.Network/networkInterfaces/${primaryNicNamePrefix_var}${i}'
    availabilitySetName
  ]
}]

resource primaryVmNamePrefix_WinRMCustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@[variables(\'apiVersion\')]' = [for i in range(0, numberOfInstances): {
  name: '${PrimaryVmNamePrefix}${i}/WinRMCustomScriptExtension'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.4'
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-winrm-lb-windows/ConfigureWinRM.ps1'
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-winrm-lb-windows/makecert.exe'
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-winrm-lb-windows/winrmconf.cmd'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -file ConfigureWinRM.ps1 ${hostDNSNameScriptArgument}'
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${PrimaryVmNamePrefix}${i}'
  ]
}]

resource secondaryVmNamePrefix_resource 'Microsoft.Compute/virtualMachines@2016-04-30-preview' = [for i in range(0, numberOfInstances): {
  name: concat(SecondaryVmNamePrefix, i)
  location: resourceGroup().location
  tags: {
    Role: 'Test'
  }
  properties: {
    availabilitySet: {
      id: availabilitySetName.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(SecondaryVmNamePrefix, i)
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
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(secondaryNicNamePrefix_var, i))
        }
      ]
    }
  }
  dependsOn: [
    'Microsoft.Network/networkInterfaces/${secondaryNicNamePrefix_var}${i}'
    availabilitySetName
  ]
}]

resource secondaryVmNamePrefix_WinRMCustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@[variables(\'apiVersion\')]' = [for i in range(0, numberOfInstances): {
  name: '${SecondaryVmNamePrefix}${i}/WinRMCustomScriptExtension'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.4'
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-winrm-lb-windows/ConfigureWinRM.ps1'
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-winrm-lb-windows/makecert.exe'
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-winrm-lb-windows/winrmconf.cmd'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -file ConfigureWinRM.ps1 ${hostDNSNameScriptArgument}'
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${SecondaryVmNamePrefix}${i}'
  ]
}]