@description('Admin password.')
@secure()
param adminPassword string

@description('Admin username.')
param adminUsername string

@description('DNS for Load Balancer IP.')
param dnsNameforLBIP string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of storage account.')
param storageAccountName string = 'storage${uniqueString(resourceGroup().id)}'

@description('Size of the virtual machine.')
param vmSize string = 'Standard_D2_v2'

var addressPrefix = '10.0.0.0/16'
var imageOffer = 'WindowsServer'
var imagePublisher = 'MicrosoftWindowsServer'
var imageSKU = '2019-Datacenter'
var lbName_var = 'myLB'
var networkSecurityGroupName_var = '${subnetName}-nsg'
var nic1NamePrefix_var = 'nic1'
var nic2NamePrefix_var = 'nic2'
var publicIPAddressName_var = 'myPublicIP'
var publicIPAddressType = 'Dynamic'
var storageAccountType = 'Standard_LRS'
var subnetName = 'Subnet-1'
var subnetPrefix = '10.0.0.0/24'
var vmNamePrefix_var = 'myVM'
var vnetName_var = 'myVNET'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource lbName 'Microsoft.Network/loadBalancers@2020-05-01' = {
  name: lbName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          publicIPAddress: {
            id: publicIPAddressName.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'BackendPool1'
      }
    ]
    inboundNatRules: [
      {
        name: 'RDP-VM0'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName_var, 'LoadBalancerFrontEnd')
          }
          protocol: 'Tcp'
          frontendPort: 50001
          backendPort: 3389
          enableFloatingIP: false
        }
      }
    ]
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {}
}

resource nic1NamePrefix 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: nic1NamePrefix_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetName)
          }
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName_var, 'BackendPool1')
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', lbName_var, 'RDP-VM0')
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
}

resource nic2NamePrefix 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: nic2NamePrefix_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetName
  ]
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameforLBIP
    }
  }
}

resource vmNamePrefix 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmNamePrefix_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmNamePrefix_var
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
          properties: {
            primary: true
          }
          id: nic1NamePrefix.id
        }
        {
          properties: {
            primary: false
          }
          id: nic2NamePrefix.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(storageAccountName, '2019-06-01').primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    storageAccountName_resource
  ]
}

resource vnetName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnetName_var
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
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}