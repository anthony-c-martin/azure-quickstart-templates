@description('Size of the VM that runs the test.')
param probeVmSize string = 'Standard_A4_v2'

@description('Location of the VM that runs the test.')
param probeVmLocation string

@description('Size of the target VM.')
param targetVmSize string = 'Standard_A4_v2'

@description('Location of the target VM.')
param targetVmLocation string

@allowed([
  '8k'
  '16k'
  '32k'
  '64k'
  '128k'
  '256k'
  '512k'
  '1m'
])
@description('Size of the request to send to the target VM.')
param testRequestSize string = '64k'

@description('Number of the requests to send to the target VM.')
param testRequestCount int = 1000

@description('Username for the probe and target VMs.')
param adminUsername string

@description('Password for the probe and target VMs.')
@secure()
param adminPassword string

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/vm-to-vm-bandwidth-meter/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var vmSettings = [
  {
    name: 'probeVM'
    location: probeVmLocation
    size: probeVmSize
    imageReference: {
      publisher: 'MicrosoftWindowsServer'
      offer: 'WindowsServer'
      sku: '2019-Datacenter'
      version: 'latest'
    }
    subnetRef: resourceId('Microsoft.Network/virtualNetworks/subnets', '${virtualNetworkName}1', subnetName)
  }
  {
    name: 'targetVM'
    location: targetVmLocation
    size: targetVmSize
    imageReference: {
      publisher: 'Canonical'
      offer: 'UbuntuServer'
      sku: '14.04.5-LTS'
      version: 'latest'
    }
    subnetRef: resourceId('Microsoft.Network/virtualNetworks/subnets', '${virtualNetworkName}2', subnetName)
  }
]
var nicName = 'myVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressName = 'publicIP'
var publicIPAddressType = 'Static'
var virtualNetworkName = 'testVNET'
var scriptFolder = 'scripts'
var scriptFileName = 'testBandwidth.ps1'
var frontEndNSGName_var = 'webtestnsg-${uniqueString(resourceGroup().id)}'
var nsgId = {
  id: frontEndNSGName.id
}

resource publicIPAddressName_1 'Microsoft.Network/publicIPAddresses@2019-11-01' = [for i in range(0, 2): {
  name: concat(publicIPAddressName, (i + 1))
  location: vmSettings[i].location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
  }
}]

resource virtualNetworkName_1 'Microsoft.Network/virtualNetworks@2019-11-01' = [for i in range(0, 2): {
  name: concat(virtualNetworkName, (i + 1))
  location: vmSettings[i].location
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
}]

resource frontEndNSGName 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: frontEndNSGName_var
  location: vmSettings[1].location
  tags: {
    displayName: 'NSG - test web server from probe'
  }
  properties: {
    securityRules: [
      {
        name: 'web-rule'
        properties: {
          description: 'Allow Web'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: reference(resourceId('Microsoft.Network/publicIPAddresses', '${publicIPAddressName}1')).ipAddress
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_1
  ]
}

resource nicName_1 'Microsoft.Network/networkInterfaces@2019-11-01' = [for i in range(0, 2): {
  name: concat(nicName, (i + 1))
  location: vmSettings[i].location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', concat(publicIPAddressName, (i + 1)))
          }
          subnet: {
            id: vmSettings[i].subnetRef
          }
        }
      }
    ]
    networkSecurityGroup: ((i == 1) ? nsgId : json('null'))
  }
  dependsOn: [
    publicIPAddressName_1
    virtualNetworkName_1
    frontEndNSGName
  ]
}]

resource vmSettings_name 'Microsoft.Compute/virtualMachines@2019-12-01' = [for i in range(0, 2): {
  name: vmSettings[i].name
  location: vmSettings[i].location
  properties: {
    hardwareProfile: {
      vmSize: vmSettings[i].size
    }
    osProfile: {
      computerName: vmSettings[i].name
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: vmSettings[i].imageReference
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(nicName, (i + 1)))
        }
      ]
    }
  }
  dependsOn: [
    nicName_1
  ]
}]

resource vmSettings_0_name_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  name: '${vmSettings[0].name}/CustomScriptExtension'
  location: vmSettings[0].location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.8'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, concat(scriptFileName, artifactsLocationSasToken))
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File ${scriptFileName} -TestIPPort ${reference(resourceId('Microsoft.Network/publicIPAddresses', '${publicIPAddressName}2')).ipAddress}:80 -TestNumber ${testRequestCount} -PacketSize ${testRequestSize}'
    }
  }
  dependsOn: [
    resourceId('Microsoft.Compute/virtualMachines', vmSettings[0].name)
    publicIPAddressName_1
    vmSettings_1_name_TargetVmCustomScriptExtension
  ]
}

resource vmSettings_1_name_TargetVmCustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  name: '${vmSettings[1].name}/TargetVmCustomScriptExtension'
  location: vmSettings[1].location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: 'sudo bash -c \'apt-get -y update && apt-get -y install apache2\''
    }
  }
  dependsOn: [
    resourceId('Microsoft.Compute/virtualMachines', vmSettings[1].name)
  ]
}

output bandwidthtestresult string = trim(reference('CustomScriptExtension').instanceView.substatuses[0].message)