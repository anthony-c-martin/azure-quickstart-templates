@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/301-nested-vms-in-virtual-network/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Resource Name for Public IP address attached to Hyper-V Host')
param HostPublicIPAddressName string = 'HVHOSTPIP'

@description('Hyper-V Host and Guest VMs Virtual Network')
param virtualNetworkName string = 'VirtualNetwork'

@description('Virtual Network Address Space')
param virtualNetworkAddressPrefix string = '10.0.0.0/22'

@description('NAT Subnet Name')
param NATSubnetName string = 'NAT'

@description('NAT Subnet Address Space')
param NATSubnetPrefix string = '10.0.0.0/24'

@description('Hyper-V Host Subnet Name')
param hyperVSubnetName string = 'Hyper-V-LAN'

@description('Hyper-V Host Subnet Address Space')
param hyperVSubnetPrefix string = '10.0.1.0/24'

@description('Ghosted Subnet Name')
param ghostedSubnetName string = 'Ghosted'

@description('Ghosted Subnet Address Space')
param ghostedSubnetPrefix string = '10.0.2.0/24'

@description('Azure VMs Subnet Name')
param azureVMsSubnetName string = 'Azure-VMs'

@description('Azure VMs Address Space')
param azureVMsSubnetPrefix string = '10.0.3.0/24'

@description('Hyper-V Host Network Interface 1 Name, attached to NAT Subnet')
param HostNetworkInterface1Name string = 'HVHOSTNIC1'

@description('Hyper-V Host Network Interface 2 Name, attached to Hyper-V LAN Subnet')
param HostNetworkInterface2Name string = 'HVHOSTNIC2'

@maxLength(15)
@description('Name of Hyper-V Host Virtual Machine, Maximum of 15 characters, use letters and numbers only.')
param HostVirtualMachineName string = 'HVHOST'

@allowed([
  'Standard_D2_v3'
  'Standard_D4_v3'
  'Standard_D8_v3'
  'Standard_D16_v3'
  'Standard_D32_v3'
  'Standard_D2s_v3'
  'Standard_D4s_v3'
  'Standard_D8s_v3'
  'Standard_D16s_v3'
  'Standard_D32s_v3'
  'Standard_D48_v3'
  'Standard_D64_v3'
  'Standard_E2_v3'
  'Standard_E4_v3'
  'Standard_E8_v3'
  'Standard_E16_v3'
  'Standard_E20_v3'
  'Standard_E32_v3'
  'Standard_E48_v3'
  'Standard_E64_v3'
  'Standard_D48s_v3'
  'Standard_D64s_v3'
  'Standard_E2s_v3'
  'Standard_E4s_v3'
  'Standard_E8s_v3'
  'Standard_E16s_v3'
  'Standard_E20s_v3'
  'Standard_E32s_v3'
  'Standard_E48s_v3'
  'Standard_E64s_v3'
])
@description('Size of the Host Virtual Machine')
param HostVirtualMachineSize string = 'Standard_D4s_v3'

@description('Admin Username for the Host Virtual Machine')
param HostAdminUsername string

@description('Admin User Password for the Host Virtual Machine')
@secure()
param HostAdminPassword string

var NATSubnetNSGName_var = '${NATSubnetName}NSG'
var hyperVSubnetNSGName_var = '${hyperVSubnetName}NSG'
var ghostedSubnetNSGName_var = '${ghostedSubnetName}NSG'
var azureVMsSubnetNSGName_var = '${azureVMsSubnetName}NSG'
var azureVMsSubnetUDRName_var = '${azureVMsSubnetName}UDR'
var DSCInstallWindowsFeaturesUri = uri(artifactsLocation, 'dsc/dscinstallwindowsfeatures.zip${artifactsLocationSasToken}')
var HVHostSetupScriptUri = uri(artifactsLocation, 'hvhostsetup.ps1${artifactsLocationSasToken}')

resource HostPublicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2019-04-01' = {
  name: HostPublicIPAddressName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower('${HostVirtualMachineName}-${uniqueString(resourceGroup().id)}')
    }
  }
}

resource NATSubnetNSGName 'Microsoft.Network/networkSecurityGroups@2019-04-01' = {
  name: NATSubnetNSGName_var
  location: location
  properties: {}
}

resource hyperVSubnetNSGName 'Microsoft.Network/networkSecurityGroups@2019-04-01' = {
  name: hyperVSubnetNSGName_var
  location: location
  properties: {}
}

resource ghostedSubnetNSGName 'Microsoft.Network/networkSecurityGroups@2019-04-01' = {
  name: ghostedSubnetNSGName_var
  location: location
  properties: {}
}

resource azureVMsSubnetNSGName 'Microsoft.Network/networkSecurityGroups@2019-04-01' = {
  name: azureVMsSubnetNSGName_var
  location: location
  properties: {}
}

resource azureVMsSubnetUDRName 'Microsoft.Network/routeTables@2019-04-01' = {
  name: azureVMsSubnetUDRName_var
  location: location
  properties: {}
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-04-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    subnets: [
      {
        name: NATSubnetName
        properties: {
          addressPrefix: NATSubnetPrefix
          networkSecurityGroup: {
            id: NATSubnetNSGName.id
          }
        }
      }
      {
        name: hyperVSubnetName
        properties: {
          addressPrefix: hyperVSubnetPrefix
          networkSecurityGroup: {
            id: hyperVSubnetNSGName.id
          }
        }
      }
      {
        name: ghostedSubnetName
        properties: {
          addressPrefix: ghostedSubnetPrefix
          networkSecurityGroup: {
            id: ghostedSubnetNSGName.id
          }
        }
      }
      {
        name: azureVMsSubnetName
        properties: {
          addressPrefix: azureVMsSubnetPrefix
          networkSecurityGroup: {
            id: azureVMsSubnetNSGName.id
          }
          routeTable: {
            id: azureVMsSubnetUDRName.id
          }
        }
      }
    ]
  }
}

resource HostNetworkInterface1Name_resource 'Microsoft.Network/networkInterfaces@2019-04-01' = {
  name: HostNetworkInterface1Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          primary: 'true'
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, NATSubnetName)
          }
          publicIPAddress: {
            id: HostPublicIPAddressName_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource HostNetworkInterface2Name_resource 'Microsoft.Network/networkInterfaces@2019-04-01' = {
  name: HostNetworkInterface2Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          primary: 'true'
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, hyperVSubnetName)
          }
        }
      }
    ]
    enableIPForwarding: true
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

module UpdateNetworking './nested_UpdateNetworking.bicep' = {
  name: 'UpdateNetworking'
  params: {
    reference_parameters_HostNetworkInterface2Name_ipconfigurations_0_properties_privateIPAddress: reference(HostNetworkInterface2Name)
    reference_parameters_HostNetworkInterface1Name_ipconfigurations_0_properties_privateIPAddress: reference(HostNetworkInterface1Name)
    resourceId_Microsoft_Network_virtualNetworks_subnets_parameters_virtualNetworkName_parameters_NATSubnetName: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, NATSubnetName)
    resourceId_Microsoft_Network_publicIPAddresses_parameters_HostPublicIPAddressName: HostPublicIPAddressName_resource.id
    resourceId_Microsoft_Network_virtualNetworks_subnets_parameters_virtualNetworkName_parameters_hyperVSubnetName: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, hyperVSubnetName)
    variables_azureVMsSubnetUDRName: azureVMsSubnetUDRName_var
    location: location
    ghostedSubnetPrefix: ghostedSubnetPrefix
    HostNetworkInterface1Name: HostNetworkInterface1Name
    HostNetworkInterface2Name: HostNetworkInterface2Name
  }
  dependsOn: [
    HostNetworkInterface1Name_resource
    HostNetworkInterface2Name_resource
  ]
}

resource HostVirtualMachineName_resource 'Microsoft.Compute/virtualMachines@2019-03-01' = {
  location: location
  name: HostVirtualMachineName
  properties: {
    hardwareProfile: {
      vmSize: HostVirtualMachineSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2016-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: '${HostVirtualMachineName}OsDisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        caching: 'ReadWrite'
      }
      dataDisks: [
        {
          lun: 0
          name: '${HostVirtualMachineName}DataDisk1'
          createOption: 'Empty'
          diskSizeGB: 1024
          caching: 'ReadOnly'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
      ]
    }
    osProfile: {
      computerName: HostVirtualMachineName
      adminUsername: HostAdminUsername
      adminPassword: HostAdminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: HostNetworkInterface1Name_resource.id
          properties: {
            primary: true
          }
        }
        {
          id: HostNetworkInterface2Name_resource.id
          properties: {
            primary: false
          }
        }
      ]
    }
  }
  dependsOn: [
    UpdateNetworking
  ]
}

resource HostVirtualMachineName_InstallWindowsFeatures 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = {
  parent: HostVirtualMachineName_resource
  location: location
  name: 'InstallWindowsFeatures'
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    settings: {
      wmfVersion: 'latest'
      configuration: {
        url: DSCInstallWindowsFeaturesUri
        script: 'DSCInstallWindowsFeatures.ps1'
        function: 'InstallWindowsFeatures'
      }
    }
  }
}

resource HostVirtualMachineName_HVHOSTSetup 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = {
  parent: HostVirtualMachineName_resource
  location: location
  name: 'HVHOSTSetup'
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        HVHostSetupScriptUri
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File HVHostSetup.ps1 -NIC1IPAddress ${reference(HostNetworkInterface1Name).ipconfigurations[0].properties.privateIPAddress} -NIC2IPAddress ${reference(HostNetworkInterface2Name).ipconfigurations[0].properties.privateIPAddress} -GhostedSubnetPrefix ${ghostedSubnetPrefix} -VirtualNetworkPrefix ${virtualNetworkAddressPrefix}'
    }
  }
  dependsOn: [
    HostVirtualMachineName_InstallWindowsFeatures
  ]
}