@description('Size of VMs in the VM Scale Set.')
param vmSku string = 'Standard_D1_v2'

@maxLength(9)
@description('String used as a base for naming resources (9 characters or less). A hash is prepended to this string for some resources, and resource-specific information is appended.')
param vmssName string

@minValue(1)
@maxValue(100)
@description('Number of VM instances (100 or less).')
param instanceCount int

@description('Admin username on all VMs.')
param adminUsername string

@description('Admin password on all VMs.')
@secure()
param adminPassword string

@allowed([
  'windows'
  'linux'
])
@description('OS Type for the VMSS.')
param osType string = 'windows'

@allowed([
  'BYOL'
  'PAYG'
])
@description('License type, only BYOL is supported in Azure US Government.')
param licenseType string = 'BYOL'

@description('Location for the resources.')
param location string = resourceGroup().location

var vmSkuName = (((environment().name == 'AzureCloud') && (licenseType == 'PAYG')) ? '' : 'byol')
var osType_var = {
  windows: {
    marketplacePlan: {
      name: 'windows2016${vmSkuName}'
      publisher: 'microsoft-ads'
      product: 'windows-data-science-vm'
    }
    imageReference: {
      publisher: 'microsoft-ads'
      offer: 'windows-data-science-vm'
      sku: 'windows2016${vmSkuName}'
      version: 'latest'
    }
    natBackendPort: 3389
  }
  linux: {
    marketplacePlan: {
      name: 'linuxdsvmubuntu${vmSkuName}'
      publisher: 'microsoft-ads'
      product: 'linux-data-science-vm-ubuntu'
    }
    imageReference: {
      publisher: 'microsoft-ads'
      offer: 'linux-data-science-vm-ubuntu'
      sku: 'linuxdsvmubuntu${vmSkuName}'
      version: 'latest'
    }
    natBackendPort: 3389
  }
}
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName_var = '${vmssName}vnet'
var publicIPAddressName_var = '${vmssName}pip'
var subnetName = '${vmssName}subnet'
var loadBalancerName_var = '${vmssName}lb'
var publicIPAddressID = publicIPAddressName.id
var natPoolName = '${vmssName}natpool'
var bePoolName = '${vmssName}bepool'
var natStartPort = 50000
var natEndPort = 50120
var nicName = '${vmssName}nic'
var ipConfigName = '${vmssName}ipconfig'
var frontEndIPConfigID = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName_var, 'loadBalancerFrontEnd')

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2019-04-01' = {
  name: virtualNetworkName_var
  location: location
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

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2019-04-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: vmssName
    }
  }
}

resource loadBalancerName 'Microsoft.Network/loadBalancers@2019-04-01' = {
  name: loadBalancerName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          publicIPAddress: {
            id: publicIPAddressID
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: bePoolName
      }
    ]
    inboundNatPools: [
      {
        name: natPoolName
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPortRangeStart: natStartPort
          frontendPortRangeEnd: natEndPort
          backendPort: osType_var[osType].natBackendPort
        }
      }
    ]
  }
}

resource vmssName_resource 'Microsoft.Compute/virtualMachineScaleSets@2019-07-01' = {
  name: vmssName
  location: location
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: instanceCount
  }
  plan: osType_var[osType].marketplacePlan
  properties: {
    overprovision: false
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
        }
        imageReference: osType_var[osType].imageReference
      }
      osProfile: {
        computerNamePrefix: vmssName
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: nicName
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: ipConfigName
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName_var, bePoolName)
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', loadBalancerName_var, natPoolName)
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    loadBalancerName
    virtualNetworkName
  ]
}