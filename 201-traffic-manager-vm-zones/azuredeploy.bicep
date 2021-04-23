@description('Location for the VM, only certain regions support zones.')
param location string

@description('Relative DNS name for the traffic manager profile, must be globally unique.')
param trafficManagerDnsName string

@description('User name for the Virtual Machines.')
param adminUsername string

@description('Relative DNS Name for the Public IPs used to access the Virtual Machines, must be globally unique.  An index will be appended for each instance.')
param publicIpDnsName string

@minValue(1)
@maxValue(10)
@description('Number of VMs to provision')
param numberOfVms int = 3

@description('Size of the virtual machines')
param vmSize string = 'Standard_A2_v2'

@allowed([
  '18.04-LTS'
  '16.04.0-LTS'
  '14.04.5-LTS'
])
@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version. Allowed values: 18.04-LTS, 16.04.0-LTS, 14.04.5-LTS.')
param ubuntuOSVersion string = '18.04-LTS'

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
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-traffic-manager-vm-zones/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var nicName_var = 'myVMNic'
var subnetName = 'Subnet-1'
var publicIPAddressName_var = 'myPublicIP'
var vmName_var = 'MyUbuntuVM'
var virtualNetworkName_var = 'MyVNET'
var networkSecurityGroupName_var = 'MyNSG'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName_var, subnetName)
var linuxImage = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: ubuntuOSVersion
  version: 'latest'
}
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

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-05-01' = [for i in range(0, numberOfVms): {
  name: concat(publicIPAddressName_var, i)
  zones: split(string(((i % 3) + 1)), ',')
  sku: {
    name: 'Standard'
  }
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: concat(publicIpDnsName, i)
    }
  }
}]

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworkName_var
  location: location
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

resource nicName 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, numberOfVms): {
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
    publicIPAddressName
    virtualNetworkName
    networkSecurityGroupName
  ]
}]

resource vmName 'Microsoft.Compute/virtualMachines@2019-12-01' = [for i in range(0, numberOfVms): {
  name: concat(vmName_var, i)
  zones: split(string(((i % 3) + 1)), ',')
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
      imageReference: linuxImage
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
    nicName
  ]
}]

resource vmName_vmName_installcustomscript 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = [for i in range(0, numberOfVms): {
  name: '${vmName_var}${i}/${vmName_var}${i}-installcustomscript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'install_apache.sh${artifactsLocationSasToken}')
      ]
      commandToExecute: 'sh install_apache.sh'
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
      relativeName: trafficManagerDnsName
      ttl: 30
    }
    monitorConfig: {
      protocol: 'HTTP'
      port: 80
      path: '/'
    }
    endpoints: [for j in range(0, numberOfVms): {
      name: 'endpoint${j}'
      type: 'Microsoft.Network/trafficManagerProfiles/azureEndpoints'
      properties: {
        targetResourceId: resourceId('Microsoft.Network/publicIPAddresses', concat(publicIPAddressName_var, j))
        endpointStatus: 'Enabled'
        weight: 1
      }
    }]
  }
  dependsOn: [
    publicIPAddressName
  ]
}

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

output trafficManagerFqdn string = reference('VMEndpointExample', '2018-04-01').dnsConfig.fqdn
output trafficManagerEndpoints array = reference('VMEndpointExample', '2018-04-01').endpoints