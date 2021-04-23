@description('Location for the resources.')
param location string = resourceGroup().location

@allowed([
  '6.6'
  '7.0'
  '8.0'
])
@description('OpenLogic CentOS version to use')
param imageSku string = '8.0'

@maxLength(9)
@description('String used as a base for naming resources (9 characters or less). A hash is prepended to this string for some resources, and resource-specific information is appended.')
param vmssName string = 'lustre'

@description('Admin username for the virtual machines, optional when scaling and existing vmss')
param adminUsername string = ''

@allowed([
  'password'
  'sshPublicKey'
])
@description('Authentication type for the virtual machines')
param authenticationType string = 'password'

@description('Admin password or SSH public key for the virtual machines, optional when scaling and existing vmss')
@secure()
param adminPasswordOrKey string = ''

@description('Size of the Lustre client VM')
param clientVmSize string = 'Standard_D2_v3'

@minValue(1)
@maxValue(100)
@description('Number of Lustre client instances')
param clientCount int = 2

@description('Name of the Lustre filesystem exposed by the Lustre MGS node')
param filesystemName string = 'lustre'

@description('IP address of the Lustre MGS node')
param mgsIpAddress string = '10.1.0.4'

@allowed([
  'new'
  'existing'
])
@description('Specifies whether to use a new or existing vnet')
param vnetNewOrExisting string = 'new'

@description('Existing Virtual Network Resource Group where Lustre servers are deployed')
param vnetResourceGroupName string = resourceGroup().name

@description('Existing Virtual Network name (e.g. vnet-lustre)')
param vnetName string = 'vnet-lustre'

@description('Lustre clients will be deployed into this subnet within the existing Virtual Network')
param subnetName string = 'subnet-lustre-clients'

@description('Address prefix of the virtual network')
param addressPrefixes array = [
  '10.0.0.0/16'
]

@description('Subnet prefix of the virtual network')
param subnetPrefix string = '10.0.0.0/24'

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/intel-lustre-clients-vmss-centos/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@allowed([
  'Deploy New ScaleSet'
  'Scale Existing VMSS'
])
@description('Determines whether to deploy a new instance or scale and existing scale set up or down.')
param NewOrScaleExisting string = 'Deploy New ScaleSet'

var publicIPAddressName_var = '${vmssName}pip'
var loadBalancerName_var = '${vmssName}lb'
var publicIPAddressID = publicIPAddressName.id
var natPoolName = '${vmssName}natpool'
var bePoolName = '${vmssName}bepool'
var natStartPort = 50000
var natEndPort = 50119
var natBackendPort = 22
var nicName = '${vmssName}nic'
var ipConfigName = '${vmssName}ipconfig'
var frontEndIPConfigID = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName_var, 'loadBalancerFrontEnd')
var osType = {
  publisher: 'openlogic'
  offer: 'CentOS'
  sku: imageSku
  version: 'latest'
}
var imageReference = osType
var sshKeyPath = '/home/${adminUsername}/.ssh/authorized_keys'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: sshKeyPath
        keyData: adminPasswordOrKey
      }
    ]
  }
}
var subnetClientsID = resourceId(vnetResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
var scriptUrlLustreClient = uri(artifactsLocation, 'lustre_client.sh${artifactsLocationSasToken}')

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2019-11-01' = if (vnetNewOrExisting == 'new') {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
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

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2019-11-01' = if (NewOrScaleExisting == 'Deploy New ScaleSet') {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: 'vmss-${vmssName}-${uniqueString(resourceGroup().id)}'
    }
  }
}

resource loadBalancerName 'Microsoft.Network/loadBalancers@2019-11-01' = if (NewOrScaleExisting == 'Deploy New ScaleSet') {
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
          backendPort: natBackendPort
        }
      }
    ]
  }
}

resource NewOrScaleExisting_Deploy_New_ScaleSet_vmssName_none 'Microsoft.Compute/virtualMachineScaleSets@2019-12-01' = if (NewOrScaleExisting == 'Deploy New ScaleSet') {
  name: ((NewOrScaleExisting == 'Deploy New ScaleSet') ? vmssName : 'none')
  location: location
  sku: {
    name: clientVmSize
    tier: 'Standard'
    capacity: clientCount
  }
  properties: {
    upgradePolicy: {
      mode: 'Automatic'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          caching: 'ReadOnly'
          createOption: 'FromImage'
        }
        imageReference: imageReference
      }
      osProfile: {
        computerNamePrefix: vmssName
        adminUsername: adminUsername
        adminPassword: adminPasswordOrKey
        linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
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
                      id: subnetClientsID
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
      extensionProfile: {
        extensions: [
          {
            name: 'lustre_client'
            properties: {
              publisher: 'Microsoft.Azure.Extensions'
              type: 'CustomScript'
              typeHandlerVersion: '2.0'
              autoUpgradeMinorVersion: true
              settings: {
                fileUris: [
                  scriptUrlLustreClient
                ]
                commandToExecute: 'bash lustre_client.sh -n CLIENTCENTOS${imageSku} -i 0 -d 0 -m ${mgsIpAddress} -l 0.0.0.0 -f ${filesystemName}'
              }
            }
          }
        ]
      }
    }
    overprovision: true
  }
  dependsOn: [
    loadBalancerName
  ]
}

resource NewOrScaleExisting_Scale_Existing_VMSS_vmssName_none 'Microsoft.Compute/virtualMachineScaleSets@2019-12-01' = if (NewOrScaleExisting == 'Scale Existing VMSS') {
  name: ((NewOrScaleExisting == 'Scale Existing VMSS') ? vmssName : 'none')
  location: location
  sku: {
    name: clientVmSize
    tier: 'Standard'
    capacity: clientCount
  }
}

output fqdn string = reference(publicIPAddressName.id, '2019-11-01').dnsSettings.fqdn