@description('Location for the VM, only certain regions support zones.')
param location string = resourceGroup().location

@description('Relative DNS name for the traffic manager profile, must be globally unique.')
param uniqueDnsName string

@description('User name for the Virtual Machines.')
param adminUsername string

@description('Relative DNS Name for the Public IPs used to access the Virtual Machines, must be globally unique.  An index will be appended for each instance.')
param uniqueDnsNameForPublicIP string

@allowed([
  '18.04-LTS'
  '16.04.0-LTS'
  '14.04.5-LTS'
])
@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version. Allowed values: 18.04-LTS, 16.04.0-LTS, 14.04.5-LTS.')
param ubuntuOSVersion string = '18.04-LTS'

@description('Size of the virtual machine')
param vmSize string = 'Standard_D1_v2'

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var numVMs = 3
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var nicName_var = 'myVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressName_var = 'myPublicIP'
var publicIPAddressType = 'Dynamic'
var vmName_var = 'MyUbuntuVM'
var virtualNetworkName_var = 'MyVNET'
var networkSecurityGroupName_var = 'MyNSG'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
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

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-05-01' = [for i in range(0, numVMs): {
  name: concat(publicIPAddressName_var, i)
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: concat(uniqueDnsNameForPublicIP, i)
    }
  }
}]

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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

resource nicName 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, numVMs): {
  name: concat(nicName_var, i)
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', concat(publicIPAddressName_var, i))
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroupName.id
    }
  }
  dependsOn: [
    resourceId('Microsoft.Network/publicIPAddresses/', concat(publicIPAddressName_var, i))
    virtualNetworkName
    networkSecurityGroupName
  ]
}]

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'Port_80'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource networkSecurityGroupName_Port_80 'Microsoft.Network/networkSecurityGroups/securityRules@2020-05-01' = {
  parent: networkSecurityGroupName
  name: 'Port_80'
  properties: {
    protocol: '*'
    sourcePortRange: '*'
    destinationPortRange: '80'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 100
    direction: 'Inbound'
  }
}

resource vmName 'Microsoft.Compute/virtualMachines@2020-06-01' = [for i in range(0, numVMs): {
  name: concat(vmName_var, i)
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: ubuntuOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(nicName_var, i))
        }
      ]
    }
  }
  dependsOn: [
    resourceId('Microsoft.Network/networkInterfaces/', concat(nicName_var, i))
  ]
}]

resource vmName_installcustomscript 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = [for i in range(0, numVMs): {
  name: '${vmName_var}${i}/installcustomscript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: 'sudo bash -c \'sudo dpkg --configure -a && sudo apt-get update && sudo apt-get -y install apache2\' '
    }
  }
  dependsOn: [
    resourceId('Microsoft.Compute/virtualMachines/', concat(vmName_var, i))
  ]
}]

resource VMEndpointExample 'Microsoft.Network/trafficManagerProfiles@2018-08-01' = {
  name: 'VMEndpointExample'
  location: 'global'
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: 'Weighted'
    dnsConfig: {
      relativeName: uniqueDnsName
      ttl: 30
    }
    monitorConfig: {
      protocol: 'HTTP'
      port: 80
      path: '/'
    }
    endpoints: [
      {
        name: 'endpoint0'
        type: 'Microsoft.Network/trafficManagerProfiles/azureEndpoints'
        properties: {
          targetResourceId: resourceId('Microsoft.Network/publicIPAddresses', concat(publicIPAddressName_var, 0))
          endpointStatus: 'Enabled'
          weight: 1
        }
      }
      {
        name: 'endpoint1'
        type: 'Microsoft.Network/trafficManagerProfiles/azureEndpoints'
        properties: {
          targetResourceId: resourceId('Microsoft.Network/publicIPAddresses', concat(publicIPAddressName_var, 1))
          endpointStatus: 'Enabled'
          weight: 1
        }
      }
      {
        name: 'endpoint2'
        type: 'Microsoft.Network/trafficManagerProfiles/azureEndpoints'
        properties: {
          targetResourceId: resourceId('Microsoft.Network/publicIPAddresses', concat(publicIPAddressName_var, 2))
          endpointStatus: 'Enabled'
          weight: 1
        }
      }
    ]
  }
  dependsOn: [
    resourceId('Microsoft.Network/publicIPAddresses/', '${publicIPAddressName_var}0')
    resourceId('Microsoft.Network/publicIPAddresses/', '${publicIPAddressName_var}1')
    resourceId('Microsoft.Network/publicIPAddresses/', '${publicIPAddressName_var}2')
  ]
}