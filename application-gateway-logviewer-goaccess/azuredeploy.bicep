param adminUsername string {
  metadata: {
    description: 'Username you want to use for the VM the template creates'
  }
}
param vmSize string {
  metadata: {
    description: 'Size of the VM'
  }
  default: 'Standard_A2_v2'
}
param dnsNameForPublicIP string {
  metadata: {
    description: 'The DNS name (prefix) you want to use for the VM to map against its public IP'
  }
  default: uniqueString(resourceGroup().id)
}
param appGwAccessLogsBlobSasUri string {
  metadata: {
    description: 'The SAS URL connection string for the storage account blog where your Application Gateway Access Logs are stored'
  }
}
param filterRegexForAppGwAccessLogs string {
  metadata: {
    description: 'A regex to use to filter the Application Gateway Access Logs to a specific subset. For example, if you have multiple application gateways publishing logs to the same storage account blob, and you only want GoAccess to surface traffic stats for say one of the Application Gateways, you can provide a regex for this field to filter to just that instance.'
  }
  default: '.*'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located including a trailing \'/\''
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/application-gateway-logviewer-goaccess/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.'
  }
  secure: true
  default: ''
}
param authenticationType string {
  allowed: [
    'sshPublicKey'
    'password'
  ]
  metadata: {
    description: 'Type of authentication to use on the Virtual Machine. SSH key is recommended.'
  }
  default: 'sshPublicKey'
}
param adminPasswordOrKey string {
  metadata: {
    description: 'SSH Key or password for the Virtual Machine. SSH key is recommended.'
  }
  secure: true
}

var vmName = dnsNameForPublicIP
var nicName = '${dnsNameForPublicIP}_vmnic'
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var subnetName = 'DefaultSubnet'
var publicIPAddressName = '${dnsNameForPublicIP}_publicip'
var virtualNetworkName = '${dnsNameForPublicIP}_vnet'
var networkSecurityGroupName = '${dnsNameForPublicIP}_nsg'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var scriptFileUri = uri(artifactsLocation, 'scripts/setup_vm.sh${artifactsLocationSasToken}')
var appGatewayLogProcessorArtifactUri = uri(artifactsLocation, 'scripts/AppGatewayLogProcessor.zip${artifactsLocationSasToken}')
var appGwAccessLogsBlobSasUriVar = '"${appGwAccessLogsBlobSasUri}"'
var filterRegexForAppGwAccessLogsVar = '"|${filterRegexForAppGwAccessLogs}|"'
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

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2018-08-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2018-08-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'ssh'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 132
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'http'
        properties: {
          provisioningState: 'Succeeded'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 131
          direction: 'Inbound'
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'https'
        properties: {
          provisioningState: 'Succeeded'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'GoAccessSocket'
        properties: {
          provisioningState: 'Succeeded'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 129
          direction: 'Inbound'
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
  dependsOn: []
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2018-08-01' = {
  name: virtualNetworkName
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

resource nicName_resource 'Microsoft.Network/networkInterfaces@2018-08-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName_resource.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroupName_resource.id
    }
  }
  dependsOn: [
    publicIPAddressName_resource
    virtualNetworkName_resource
    networkSecurityGroupName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2018-06-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}_osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          name: '${vmName}_datadisk1'
          diskSizeGB: 1023
          lun: 0
          createOption: 'Empty'
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    nicName_resource
  ]
}

resource vmName_newuserscript 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = {
  name: '${vmName}/newuserscript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        scriptFileUri
        appGatewayLogProcessorArtifactUri
      ]
      commandToExecute: 'sh setup_vm.sh ${appGwAccessLogsBlobSasUriVar} ${filterRegexForAppGwAccessLogsVar}'
    }
  }
  dependsOn: [
    vmName_resource
  ]
}

output goAccessReportUrl string = '${reference(publicIPAddressName).dnsSettings.fqdn}/report.html'
output sshCommand string = 'ssh ${adminUsername}@${reference(publicIPAddressName).dnsSettings.fqdn}'