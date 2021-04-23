@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/kubernetes-on-ubuntu-vmss/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('The name of your VM master node.')
param vmName string

@description('The name of your VMSS cluster.')
param vmssName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Username for the Virtual Machine.')
param adminUsername string

@description('SSH Key for the Virtual Machine.')
@secure()
param adminKey string

@description('The initial node size of your VMSS cluster.')
param defaultNodeCount int = 1

@description('The min node size of your VMSS cluster.')
param minNodeCount int = 1

@description('The max node size of your VMSS cluster.')
param maxNodeCount int = 20

@description('ServicePrincipal ClientID')
param spClientId string

@description('ServicePrincipal Secret')
@secure()
param spClientSecret string

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix string = toLower('k8s-cluster-${uniqueString(resourceGroup().id)}')

@description('Unique DNS Name for the Public IP used to access the VMSS.')
param vmssDnsLabelPrefix string = toLower('k8s-vmss-cluster-${uniqueString(resourceGroup().id)}')

@description('The size of the VM')
param vmSize string = 'Standard_DS2_v2'

@description('Name of the VNET')
param virtualNetworkName string = 'vNet'

@description('Name of the subnet in the virtual network')
param subnetName string = 'Subnet'

@description('Name of the VMSS subnet in the virtual network')
param vmssSubnetName string = 'VMSSSubnet'

var publicIpAddressName_var = '${vmName}PublicIP'
var vmssPublicIpAddressName = '${vmssName}PublicIP'
var networkInterfaceName_var = '${vmName}NetInt'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var vmssSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, vmssSubnetName)
var osDiskType = 'Standard_LRS'
var scriptsDir = 'scripts'
var masterScriptFileName = 'cloud-init-master.sh'
var vmssScriptFileName = 'cloud-init-vmss.sh'
var subscriptionId = subscription().subscriptionId
var tenantId = subscription().tenantId

resource networkInterfaceName 'Microsoft.Network/networkInterfaces@2019-11-01' = {
  name: networkInterfaceName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpAddressName.id
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: vmssSubnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

resource publicIpAddressName 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: publicIpAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
    idleTimeoutInMinutes: 10
  }
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminKey
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminKey
            }
          ]
        }
      }
    }
  }
}

resource vmName_customScript 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  parent: vmName_resource
  name: 'customScript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      commandToExecute: 'bash ${masterScriptFileName} ${spClientId} ${spClientSecret} ${resourceGroup().name} ${subscriptionId} ${tenantId}'
      fileUris: [
        '${artifactsLocation}${scriptsDir}/${masterScriptFileName}${artifactsLocationSasToken}'
      ]
    }
  }
}

resource vmssName_resource 'Microsoft.Compute/virtualMachineScaleSets@2019-07-01' = {
  name: vmssName
  tags: {
    'cluster-autoscaler-enabled': 'true'
    'cluster-autoscaler-name': resourceGroup().name
    min: minNodeCount
    max: maxNodeCount
    poolName: vmssName
  }
  location: location
  sku: {
    name: vmSize
    tier: 'Standard'
    capacity: defaultNodeCount
  }
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
        imageReference: {
          publisher: 'Canonical'
          offer: 'UbuntuServer'
          sku: '18.04-LTS'
          version: 'latest'
        }
      }
      osProfile: {
        computerNamePrefix: vmssName
        adminUsername: adminUsername
        adminPassword: adminKey
        linuxConfiguration: {
          disablePasswordAuthentication: true
          ssh: {
            publicKeys: [
              {
                path: '/home/${adminUsername}/.ssh/authorized_keys'
                keyData: adminKey
              }
            ]
          }
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic${vmssName}'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfigVmss${vmssName}'
                  properties: {
                    subnet: {
                      id: vmssSubnetRef
                    }
                    publicIPAddressConfiguration: {
                      name: vmssPublicIpAddressName
                      properties: {
                        idleTimeoutInMinutes: 10
                        dnsSettings: {
                          domainNameLabel: vmssDnsLabelPrefix
                        }
                      }
                    }
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
            name: 'customVmssScript'
            properties: {
              publisher: 'Microsoft.Azure.Extensions'
              type: 'CustomScript'
              typeHandlerVersion: '2.0'
              autoUpgradeMinorVersion: true
              protectedSettings: {
                commandToExecute: 'bash ${vmssScriptFileName} ${spClientId} ${spClientSecret} ${resourceGroup().name} ${subscriptionId} ${tenantId} ${location} ${vmssSubnetName} ${virtualNetworkName}'
                fileUris: [
                  '${artifactsLocation}${scriptsDir}/${vmssScriptFileName}${artifactsLocationSasToken}'
                ]
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    networkInterfaceName
  ]
}

output adminUsername string = adminUsername
output hostname string = reference(publicIpAddressName_var).dnsSettings.fqdn
output sshCommand string = 'ssh ${adminUsername}@${reference(publicIpAddressName_var).dnsSettings.fqdn}'