@description('Array of disks objects that can be added (see azuredeploy.json for the disk object content)')
param dDisks array = []

@description('Admin password')
@secure()
param adminPassword string

@description('Admin username')
param adminUsername string

@description('The location of resources such as templates and DSC modules that the script is dependent on. Includes the last forward slash')
param assetLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/'

@description('Availibility Set the VM will belong to')
param availabilitySetName string = 'AVSet1'

@description('Computer Name')
param computerName string = 'mbmr'

@description('Image Offer')
param imageOffer string = 'WindowsServer'

@description('Image Publisher')
param imagePublisher string = 'MicrosoftWindowsServer'

@description('Image SKU')
param imageSKU string = '2012-R2-Datacenter'

@description('Image version, \'latest\' by default (recommended)')
param imageVersion string = 'latest'

@description('objects suffix to avoid name collisions')
param indx int = 0

@description('Front End load Balancer Name\'.')
param lbName string = 'lbn'

@description('Prefix for Nat Rules.')
param natRulePrefix string = 'nr-'

@description('Prefix for NICs.')
param nicNamePrefix string = 'nic-'

@description('Public address name, for lb configuration.')
param publicIPAddressName string = 'PublicIP'

@description('Public port, for RDP remote connection. The value of indx parameter will be added')
param publicStartRdpPort int = 5500

@description('Storage to put the disk image on')
param storageAccountName string

@description('list of subnets where the VM will belong to')
param subnets array
param vmNamePrefix string = 'srv-'

@allowed([
  'Standard_A0'
  'Standard_A1'
  'Standard_A2'
  'Standard_A3'
  'Standard_A4'
  'Standard_A10'
  'Standard_A11'
  'Standard_A5'
  'Standard_A6'
  'Standard_A7'
  'Standard_A8'
  'Standard_A9'
  'Standard_D1'
  'Standard_D1_v2'
  'Standard_D11'
  'Standard_D11_v2'
  'Standard_D12'
  'Standard_D12_v2'
  'Standard_D13'
  'Standard_D13_v2'
  'Standard_D14'
  'Standard_D14_v2'
  'Standard_D2'
  'Standard_D2_v2'
  'Standard_D3'
  'Standard_D3_v2'
  'Standard_D4'
  'Standard_D4_v2'
  'Standard_D5_v2'
  'Standard_DS1'
  'Standard_DS11'
  'Standard_DS12'
  'Standard_DS13'
  'Standard_DS14'
  'Standard_DS2'
  'Standard_DS3'
  'Standard_DS4'
  'Standard_G1'
  'Standard_G2'
  'Standard_G3'
  'Standard_G4'
  'Standard_G5'
  'Standard_GS1'
  'Standard_GS2'
  'Standard_GS3'
  'Standard_GS4'
  'Standard_GS5'
])
@description('VM Size, from // Get-AzureRoleSize  | select instanceSize')
param vmSize string = 'Standard_A2'

@description('VNet the VM will belong to')
param vnetName string

@description('Activate boot diagnostics. MUST be set to false is premium storage option is used')
param bootDiagnostics bool = false

@description('Location for all resources.')
param location string = resourceGroup().location

var lbID = resourceId('Microsoft.Network/loadBalancers', lbName)
var frontEndIPConfigID = '${lbID}/frontendIPConfigurations/loadBalancerFrontend'
var natRuleName = concat(natRulePrefix, computerName, indx)
var inboundNatName_var = '${lbName}/${natRuleName}'
var subnetIndex = (indx % length(subnets))
var subnetRef = subnets[subnetIndex].id
var vmName_var = concat(vmNamePrefix, computerName, indx)
var nicName_var = concat(nicNamePrefix, computerName, indx)
var rdpPort = (publicStartRdpPort + indx)
var apiVersion = '2015-06-15'

resource inboundNatName 'Microsoft.Network/loadBalancers/inboundNatRules@2015-06-15' = {
  name: inboundNatName_var
  location: location
  properties: {
    frontendIPConfiguration: {
      id: frontEndIPConfigID
    }
    protocol: 'Tcp'
    frontendPort: rdpPort
    backendPort: 3389
    enableFloatingIP: false
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
          loadBalancerBackendAddressPools: [
            {
              id: '${lbID}/backendAddressPools/LoadBalancerBackend'
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: '${lbID}/inboundNatRules/${natRuleName}'
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    'Microsoft.Network/loadBalancers/${lbName}/inboundNatRules/${natRuleName}'
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName_var
  location: location
  properties: {
    availabilitySet: {
      id: resourceId('Microsoft.Compute/availabilitySets', availabilitySetName)
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(computerName, indx)
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: imageVersion
      }
      osDisk: {
        name: 'osdisk${vmName_var}'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: dDisks
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: bootDiagnostics
        storageUri: 'http://${storageAccountName}.blob.core.windows.net'
      }
    }
  }
}

resource vmName_BgInfo 'Microsoft.Compute/virtualMachines/extensions@[variables(\'apiVersion\')]' = {
  name: '${vmName_var}/BgInfo'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'BGInfo'
    typeHandlerVersion: '2.1'
    settings: {
      properties: []
    }
  }
  dependsOn: [
    vmName
  ]
}

resource vmName_MyCustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@[variables(\'apiVersion\')]' = {
  name: '${vmName_var}/MyCustomScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.4'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${assetLocation}start.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File start.ps1'
    }
  }
  dependsOn: [
    vmName
    vmName_BgInfo
  ]
}

output vmIPAddress string = reference(nicName_var).ipConfigurations[0].properties.privateIPAddress