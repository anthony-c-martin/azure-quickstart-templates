@description('Username you want to use for the VM the template creates')
param adminUsername string

@description('Size of the VM')
param vmSize string = 'Standard_A2_v2'

@description('The DNS name (prefix) you want to use for the VM to map against its public IP')
param dnsNameForPublicIP string = uniqueString(resourceGroup().id)

@description('The SAS URL connection string for the storage account blog where your Application Gateway Access Logs are stored')
param appGwAccessLogsBlobSasUri string

@description('A regex to use to filter the Application Gateway Access Logs to a specific subset. For example, if you have multiple application gateways publishing logs to the same storage account blob, and you only want GoAccess to surface traffic stats for say one of the Application Gateways, you can provide a regex for this field to filter to just that instance.')
param filterRegexForAppGwAccessLogs string = '.*'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/application-gateway-logviewer-goaccess/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var vmName_var = dnsNameForPublicIP
var nicName_var = '${dnsNameForPublicIP}_vmnic'
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var subnetName = 'DefaultSubnet'
var publicIPAddressName_var = '${dnsNameForPublicIP}_publicip'
var virtualNetworkName_var = '${dnsNameForPublicIP}_vnet'
var networkSecurityGroupName_var = '${dnsNameForPublicIP}_nsg'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
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

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2018-08-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2018-08-01' = {
  name: networkSecurityGroupName_var
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

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2018-08-01' = {
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

resource nicName 'Microsoft.Network/networkInterfaces@2018-08-01' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName.id
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
    virtualNetworkName
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2018-06-01' = {
  name: vmName_var
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
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName_var}_osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          name: '${vmName_var}_datadisk1'
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
          id: nicName.id
        }
      ]
    }
  }
}

resource vmName_newuserscript 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = {
  parent: vmName
  name: 'newuserscript'
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
}

output goAccessReportUrl string = '${reference(publicIPAddressName_var).dnsSettings.fqdn}/report.html'
output sshCommand string = 'ssh ${adminUsername}@${reference(publicIPAddressName_var).dnsSettings.fqdn}'