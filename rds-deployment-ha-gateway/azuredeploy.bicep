@description('Unique public DNS prefix for the deployment. The fqdn will look something like \'<dnsname>.westus.cloudapp.azure.com\'. Up to 62 chars, digits or dashes, lowercase, should start with a letter: must conform to \'^[a-z][a-z0-9-]{1,61}[a-z0-9]$\'.')
param dnsLabelPrefix string

@description('The Loadbalancer name must match from the RDS deployment. And default value taken by template is loadbalancer.')
param loadBalancer string = 'loadBalancer'

@description('The backendAddressPools name must match from the RDS deployment. And default value taken by template is LBBAP.')
param backendAddressPools string = 'LBBAP'

@description('The gw-availabilityset name must match from the RDS deployment. And default value taken by template is gw-availabilityset.')
param gw_AvailabilitySet string = 'gw-availabilityset'

@description('The FQDN of the AD domain')
param adDomainName string

@description('The name of the administrator of the new VM and the domain. Exclusion list: \'administrator')
param adminUsername string

@description('The password for the administrator account of the new VM and the domain')
@secure()
param adminPassword string

@description('Number of RD Gateway instances')
param numberOfWebGwInstances int = 2

@description('FQDN for Broker Server')
param brokerServer string

@description('This is RD Gateway external FQDN. This shall be picked from existing basic RDS deploment.')
param WebURL string

@description('Netbios Name for Domain')
param domainNetbios string

@allowed([
  '2012-R2-Datacenter'
  '2016-Datacenter'
])
@description('Windows server SKU')
param imageSKU string = '2016-Datacenter'

@description('Size for the new RD Gateway VMs')
param vmSize string = 'Standard_A2'

@description('The vnet name of AD domain. For example johnvnet1')
param existingVnet string

@description('The subnet name of AD domain. For example johnsubnet1')
param existingSubnet string

@description('The name of the resourceGroup for the vnet')
param existingVnetResourceGroup string

@description('Location for all resources.')
param location string = resourceGroup().location

var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var subnet_id = resourceId(existingVnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', existingVnet, existingSubnet)
var publicIpRef_var = 'publicIp'
var assetLocation = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/rds-deployment'

resource gw_availabilityset_resource 'Microsoft.Compute/availabilitySets@2017-03-30' = {
  location: location
  name: gw_AvailabilitySet
  properties: {
    platformUpdateDomainCount: 20
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource publicIpRef 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIpRef_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource loadBalancer_resource 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: loadBalancer
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LBFE'
        properties: {
          publicIPAddress: {
            id: publicIpRef.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendAddressPools
      }
    ]
    loadBalancingRules: [
      {
        name: 'LBRule01'
        properties: {
          frontendIPConfiguration: {
            id: '${loadBalancer_resource.id}/frontendIPConfigurations/LBFE'
          }
          backendAddressPool: {
            id: '${loadBalancer_resource.id}/backendAddressPools/${backendAddressPools}'
          }
          protocol: 'Tcp'
          frontendPort: 443
          backendPort: 443
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          loadDistribution: 'SourceIPProtocol'
          probe: {
            id: '${loadBalancer_resource.id}/probes/tcpProbe'
          }
        }
      }
      {
        name: 'LBRule02'
        properties: {
          frontendIPConfiguration: {
            id: '${loadBalancer_resource.id}/frontendIPConfigurations/LBFE'
          }
          backendAddressPool: {
            id: '${loadBalancer_resource.id}/backendAddressPools/${backendAddressPools}'
          }
          protocol: 'Tcp'
          frontendPort: 3391
          backendPort: 3391
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          loadDistribution: 'SourceIPProtocol'
          probe: {
            id: '${loadBalancer_resource.id}/probes/tcpProbe'
          }
        }
      }
    ]
    probes: [
      {
        name: 'tcpProbe'
        properties: {
          protocol: 'Tcp'
          port: 443
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
      {
        name: 'tcpProbe01'
        properties: {
          protocol: 'Tcp'
          port: 3391
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
    inboundNatRules: [
      {
        name: 'rdp'
        properties: {
          frontendIPConfiguration: {
            id: '${loadBalancer_resource.id}/frontendIPConfigurations/LBFE'
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

resource gw_nic 'Microsoft.Network/networkInterfaces@2017-06-01' = [for i in range(0, numberOfWebGwInstances): {
  name: 'gw-${i}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet_id
          }
          loadBalancerBackendAddressPools: [
            {
              id: '${resourceId('Microsoft.Network/loadBalancers', 'loadBalancer')}/backendAddressPools/${backendAddressPools}'
            }
          ]
          loadBalancerInboundNatRules: []
        }
      }
    ]
  }
  dependsOn: [
    'Microsoft.Network/loadBalancers/loadBalancer'
  ]
}]

resource gw_vm 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, numberOfWebGwInstances): {
  name: 'gw-vm-${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    availabilitySet: {
      id: resourceId('Microsoft.Compute/availabilitySets', 'gw-availabilityset')
    }
    osProfile: {
      computerName: 'gateway${i}'
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
        name: 'gw-vm-${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'gw-${i}-nic')
        }
      ]
    }
  }
  dependsOn: [
    resourceId('Microsoft.Compute/availabilitySets', 'gw-availabilityset')
    'Microsoft.Network/networkInterfaces/gw-${i}-nic'
  ]
}]

resource gw_vm_Gateway 'Microsoft.Compute/virtualMachines/extensions@2017-12-01' = [for i in range(0, numberOfWebGwInstances): {
  name: 'gw-vm-${i}/Gateway'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.76'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: '${assetLocation}/Configuration.zip'
      ConfigurationFunction: 'Configuration.ps1\\Gateway'
      properties: {
        DomainName: adDomainName
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
    resourceId('Microsoft.Compute/virtualMachines', 'gw-vm-${i}')
  ]
}]

resource gw_vm_WebAndGwFarmAdd_PostConfig1_1 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for i in range(0, numberOfWebGwInstances): {
  name: 'gw-vm-${i}/WebAndGwFarmAdd_PostConfig1.1'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/rds-deployment-ha-gateway/Scripts/WebAndGwFarmAdd_PostConfig1.1.ps1'
      ]
    }
    protectedSettings: {
      Items: {
        AdminPassword: adminPassword
      }
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File WebAndGwFarmAdd_PostConfig1.1.ps1 -username "${adminUsername}" -password "${adminPassword}" -BrokerServer "${brokerServer}" -WebURL "${WebURL}" -Domainname "${adDomainName}" -DomainNetbios "${domainNetbios}" -numberofwebServers ${numberOfWebGwInstances}'
    }
  }
  dependsOn: [
    resourceId('Microsoft.Compute/virtualMachines', 'gw-vm-${i}')
    'Microsoft.Compute/virtualMachines/gw-vm-${i}/extensions/Gateway'
  ]
}]