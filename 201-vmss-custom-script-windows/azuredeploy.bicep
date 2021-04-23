@description('Size of VMs in the VM Scale Set.')
param vmSku string = 'Standard_D1'

@maxLength(61)
@description('String used as a base for naming resources. Must be 3-61 characters in length and globally unique across Azure. A hash is prepended to this string for some resources, and resource-specific information is appended.')
param vmssName string

@maxValue(100)
@description('Number of VM instances (100 or less).')
param instanceCount int = 2

@description('Admin username on all VMs.')
param adminUsername string

@description('Admin password on all VMs.')
@secure()
param adminPassword string

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vmss-custom-script-windows'

@description('The sasToken required to access _artifactsLocation. When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var vnetName_var = 'vnet'
var subnetName = 'subnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetName)
var publicIPAddressName_var = 'pip'
var loadBalancerName_var = 'loadBalancer'
var loadBalancerFrontEndName = 'loadBalancerFrontEnd'
var loadBalancerBackEndName = 'loadBalancerBackEnd'
var loadBalancerProbeName = 'loadBalancerHttpProbe'
var loadBalancerNatPoolName = 'loadBalancerNatPool'

resource vmssName_resource 'Microsoft.Compute/virtualMachineScaleSets@2017-03-30' = {
  name: vmssName
  location: resourceGroup().location
  sku: {
    name: vmSku
    capacity: instanceCount
  }
  properties: {
    overprovision: 'true'
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
        }
        imageReference: {
          publisher: 'MicrosoftWindowsServer'
          offer: 'WindowsServer'
          sku: '2016-Datacenter'
          version: 'latest'
        }
      }
      osProfile: {
        computerNamePrefix: vmssName
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig'
                  properties: {
                    subnet: {
                      id: subnetRef
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/loadBalancers/${loadBalancerName_var}/backendAddressPools/${loadBalancerBackEndName}'
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/loadBalancers/${loadBalancerName_var}/inboundNatPools/${loadBalancerNatPoolName}'
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
      extensionProfile: {
        extensions: [
          {
            name: 'customScript'
            properties: {
              publisher: 'Microsoft.Compute'
              settings: {
                fileUris: [
                  '${artifactsLocation}/scripts/helloWorld.ps1'
                ]
              }
              typeHandlerVersion: '1.8'
              autoUpgradeMinorVersion: true
              protectedSettings: {
                commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File helloWorld.ps1'
              }
              type: 'CustomScriptExtension'
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    vnetName
    loadBalancerName
  ]
}

resource vnetName 'Microsoft.Network/virtualNetworks@2017-04-01' = {
  name: vnetName_var
  location: resourceGroup().location
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
        }
      }
    ]
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2017-04-01' = {
  name: publicIPAddressName_var
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower(vmssName)
    }
  }
}

resource loadBalancerName 'Microsoft.Network/loadBalancers@2017-04-01' = {
  name: loadBalancerName_var
  location: resourceGroup().location
  properties: {
    frontendIPConfigurations: [
      {
        name: loadBalancerFrontEndName
        properties: {
          publicIPAddress: {
            id: publicIPAddressName.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: loadBalancerBackEndName
      }
    ]
    loadBalancingRules: [
      {
        name: 'roundRobinLBRule'
        properties: {
          frontendIPConfiguration: {
            id: '${loadBalancerName.id}/frontendIPConfigurations/${loadBalancerFrontEndName}'
          }
          backendAddressPool: {
            id: '${loadBalancerName.id}/backendAddressPools/${loadBalancerBackEndName}'
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: '${loadBalancerName.id}/probes/${loadBalancerProbeName}'
          }
        }
      }
    ]
    probes: [
      {
        name: loadBalancerProbeName
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: '5'
          numberOfProbes: '2'
        }
      }
    ]
    inboundNatPools: [
      {
        name: loadBalancerNatPoolName
        properties: {
          frontendIPConfiguration: {
            id: '${loadBalancerName.id}/frontendIPConfigurations/${loadBalancerFrontEndName}'
          }
          protocol: 'Tcp'
          frontendPortRangeStart: 50000
          frontendPortRangeEnd: 50019
          backendPort: 3389
        }
      }
    ]
  }
}