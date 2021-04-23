@description('The Name of the VM Scale Set')
param vmSSName string

@description('Number of VM instances to create in the scale set')
param instanceCount int

@allowed([
  'Standard_D1'
  'Standard_DS1'
  'Standard_D2'
  'Standard_DS2'
  'Standard_D3'
  'Standard_DS3'
  'Standard_D4'
  'Standard_DS4'
  'Standard_D11'
  'Standard_DS11'
  'Standard_D12'
  'Standard_DS12'
  'Standard_D13'
  'Standard_DS13'
  'Standard_D14'
  'Standard_DS14'
])
@description('The size of the VM instances Created')
param vmSize string

@description('The Prefix for the DNS name of the new IP Address created')
param dnsNamePrefix string

@description('The Username of the administrative user for each VM instance created')
param adminUsername string

@description('The Password of the administrative user for each VM instance created')
@secure()
param adminPassword string

@description('The source of the blob containing the custom image')
param sourceImageVhdUri string

@description('The front end port to load balance')
param frontEndLBPort int = 80

@description('The back end port to load balance')
param backEndLBPort int = 80

@description('The interval between load balancer health probes')
param probeIntervalInSeconds int = 15

@description('The number of probes that need to fail before a VM instance is deemed unhealthy')
param numberOfProbes int = 5

@description('The path used for the load balancer health probe')
param probeRequestPath string = '/iisstart.htm'

var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName_var = 'vmssvnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var publicIPAddressName_var = 'publicip1'
var publicIPAddressID = publicIPAddressName.id
var lbName_var = 'loadBalancer1'
var lbID = lbName.id
var lbFEName = 'loadBalancerFrontEnd'
var lbWebProbeName = 'loadBalancerWebProbe'
var lbBEAddressPool = 'loadBalancerBEAddressPool'
var lbFEIPConfigID = '${lbID}/frontendIPConfigurations/${lbFEName}'
var lbBEAddressPoolID = '${lbID}/backendAddressPools/${lbBEAddressPool}'
var lbWebProbeID = '${lbID}/probes/${lbWebProbeName}'
var imageName_var = 'myCustomImage'

resource imageName 'Microsoft.Compute/images@2017-03-30' = {
  name: imageName_var
  location: resourceGroup().location
  properties: {
    storageProfile: {
      osDisk: {
        osType: 'Windows'
        osState: 'Generalized'
        blobUri: sourceImageVhdUri
        storageAccountType: 'Standard_LRS'
      }
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2017-04-01' = {
  name: virtualNetworkName_var
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

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2017-04-01' = {
  name: publicIPAddressName_var
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsNamePrefix
    }
  }
}

resource lbName 'Microsoft.Network/loadBalancers@2017-04-01' = {
  name: lbName_var
  location: resourceGroup().location
  properties: {
    frontendIPConfigurations: [
      {
        name: lbFEName
        properties: {
          publicIPAddress: {
            id: publicIPAddressID
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: lbBEAddressPool
      }
    ]
    loadBalancingRules: [
      {
        name: 'weblb'
        properties: {
          frontendIPConfiguration: {
            id: lbFEIPConfigID
          }
          backendAddressPool: {
            id: lbBEAddressPoolID
          }
          probe: {
            id: lbWebProbeID
          }
          protocol: 'Tcp'
          frontendPort: frontEndLBPort
          backendPort: backEndLBPort
          enableFloatingIP: false
        }
      }
    ]
    probes: [
      {
        name: lbWebProbeName
        properties: {
          protocol: 'Http'
          port: backEndLBPort
          intervalInSeconds: probeIntervalInSeconds
          numberOfProbes: numberOfProbes
          requestPath: probeRequestPath
        }
      }
    ]
  }
}

resource vmSSName_resource 'Microsoft.Compute/virtualMachineScaleSets@2017-03-30' = {
  name: vmSSName
  location: resourceGroup().location
  sku: {
    name: vmSize
    tier: 'Standard'
    capacity: instanceCount
  }
  properties: {
    overprovision: 'true'
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        imageReference: {
          id: imageName.id
        }
      }
      osProfile: {
        computerNamePrefix: vmSSName
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic1'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ip1'
                  properties: {
                    subnet: {
                      id: subnetRef
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: lbBEAddressPoolID
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
    virtualNetworkName
  ]
}

output fqdn string = reference(publicIPAddressID, '2017-04-01').dnsSettings.fqdn