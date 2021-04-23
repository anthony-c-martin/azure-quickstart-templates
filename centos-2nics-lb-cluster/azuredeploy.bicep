@description('Admin username for VM')
param adminUsername string

@description('Unique storage account name. Must be between 3 and 24 characters in length and use numbers and lower-case letters only.')
param newStorageAccountName string

@allowed([
  2
  3
  4
  5
  6
  7
  8
  9
  10
])
@description('Number of VMs to deploy (2-10)')
param numberOfInstances int = 2

@allowed([
  'Standard_A3'
  'Standard_A6'
  'Standard_A7'
  'Standard_A8'
  'Standard_A9'
  'Standard_A10'
  'Standard_A11'
  'Standard_D2'
  'Standard_D3'
  'Standard_D4'
  'Standard_D11'
  'Standard_D12'
  'Standard_D13'
  'Standard_D14'
])
@description('Size of the Virtual Machine.')
param vmSize string = 'Standard_D2'

@description('DNS name for Load Balancer IP')
param dnsNameforLBIP string

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/centos-2nics-lb-cluster/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var imagePublisher = 'OpenLogic'
var imageOffer = 'CentOS'
var imageSKU = '7.1'
var customScriptFilePath = uri(artifactsLocation, 'deploy.sh${artifactsLocationSasToken}')
var customScriptCommandToExecute = 'bash deploy.sh'
var publicIPAddressName_var = 'myPublicIP'
var virtualNetworkName_var = 'myVNET'
var availabilitySetName_var = 'myAvSet'
var vnetID = virtualNetworkName.id
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var subnet2Name = 'Subnet-2'
var subnet2Prefix = '10.0.1.0/24'
var subnet2Ref = '${vnetID}/subnets/${subnet2Name}'
var vmStorageAccountContainerName = 'vhds'
var lbName_var = 'myLB'
var lbID = lbName.id
var frontEndIPConfigID = '${lbID}/frontendIPConfigurations/LoadBalancerFrontEnd'
var lbPoolID = '${lbID}/backendAddressPools/BackendPool1'
var lbProbeID = '${lbID}/probes/tcpProbe'
var publicIPAddressID = publicIPAddressName.id
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource newStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2015-05-01-preview' = {
  name: newStorageAccountName
  location: location
  properties: {
    accountType: 'Standard_LRS'
  }
}

resource availabilitySetName 'Microsoft.Compute/availabilitySets@2017-12-01' = {
  name: availabilitySetName_var
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
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
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2Prefix
        }
      }
    ]
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsNameforLBIP
    }
  }
}

resource nic1 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = [for i in range(0, numberOfInstances): {
  name: 'nic1${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet1Ref
          }
          loadBalancerBackendAddressPools: [
            {
              id: '${lbID}/backendAddressPools/BackendPool1'
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: '${lbID}/inboundNatRules/ssh${i}'
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
    lbName
  ]
}]

resource nic2 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = [for i in range(0, numberOfInstances): {
  name: 'nic2${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig2'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet2Ref
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}]

resource lbName 'Microsoft.Network/loadBalancers@2015-05-01-preview' = {
  name: lbName_var
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
        name: 'BackendPool1'
      }
    ]
    inboundNatRules: [
      {
        name: 'ssh0'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50000
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: 'ssh1'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50001
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: 'ssh2'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50002
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: 'ssh3'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50003
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: 'ssh4'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50004
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: 'ssh5'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50005
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: 'ssh6'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50006
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: 'ssh7'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50007
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: 'ssh8'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50008
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: 'ssh9'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50009
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: 'ssh10'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPort: 50010
          backendPort: 22
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
          idleTimeoutInMinutes: 10
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
          intervalInSeconds: '5'
          numberOfProbes: '2'
        }
      }
    ]
  }
}

resource myvm 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, numberOfInstances): {
  name: 'myvm${i}'
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetName.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'vm${i}'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        name: 'myvm${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary: true
          }
          id: resourceId('Microsoft.Network/networkInterfaces', 'nic1${i}')
        }
        {
          properties: {
            primary: false
          }
          id: resourceId('Microsoft.Network/networkInterfaces', 'nic2${i}')
        }
      ]
    }
  }
  dependsOn: [
    'Microsoft.Network/networkInterfaces/nic1${i}'
    'Microsoft.Network/networkInterfaces/nic2${i}'
    newStorageAccountName_resource
    availabilitySetName
  ]
}]

resource myvm_extension 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = [for i in range(0, numberOfInstances): {
  name: 'myvm${i}/extension'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        customScriptFilePath
      ]
      commandToExecute: '${customScriptCommandToExecute} ${i} ${numberOfInstances}'
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/myvm${i}'
  ]
}]