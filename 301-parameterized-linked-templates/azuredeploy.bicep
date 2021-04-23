param location string = resourceGroup().location

@description('Name of the VNET for all Resources.')
param VirtualNetworkName string = 'examplevnet'

@allowed([
  'Red Hat Enterprise Linux 7 (latest, LVM)'
  'SUSE Enterprise Linux 12 SP5 +Patching'
])
@description('OS Image to use for All VMs.')
param OperatingSystemImage string = 'Red Hat Enterprise Linux 7 (latest, LVM)'

@description('Name of the Proximity Placement Group to use for All Resources.')
param ProximityPlacementGroupName string = 'proxgroup'

@description('Admin User for all VMs.')
param AdminUserForVMAccess string

@description('ssh Public Key used to access all VMs.')
param sshKeyForVMAccess string

@description('Name of the Network Security Group for the Midtier Resources.')
param MidtierNetworkSecurityGroupName string = 'midtierNSG'

@description('Prefix for naming Midtier VMs.')
param MidtierVMNameBase string = 'midtier'

@allowed([
  0
  1
  3
])
@description('How many Midtier VMs to provision.')
param MidtierVMCount int = 1

@allowed([
  'Standard_D2s_v3'
  'Standard_D4s_v3'
  'Standard_D8s_v3'
  'Standard_D16s_v3'
  'Standard_D32s_v3'
])
@description('VM Size for Midtier VMs.')
param MidtierVMSize string = 'Standard_D2s_v3'

@description('Name of the Network Security Group for the Backend Resources.')
param BackendNetworkSecurityGroupName string = 'backendNSG'

@description('Prefix for naming Backend VMs.')
param BackendVMNameBase string = 'backend'

@minValue(0)
@maxValue(100)
@description('How many Backend VMs to provision.')
param BackendVMCount int = 2

@allowed([
  'Standard_D8s_v3 2xP10 (256MB/node)'
  'Standard_D8s_v3 1xP30 (1024MB/node)'
  'Standard_D16s_v3 4xP10 (512MB/node)'
  'Standard_D16s_v3 2xP30 (2048MB/node)'
  'Standard_D32s_v3 8xP10 (1024MB/node)'
  'Standard_D32s_v3 4xP30 (4096MB/node)'
  'Standard_D48s_v3 12xP10 (1536MB/node)'
  'Standard_D48s_v3 6xP30 (6144MB/node)'
  'Standard_D64s_v3 12xP10 (1536MB/node)'
  'Standard_D64s_v3 6xP30 (6144MB/node)'
])
@description('VM Size and Storage Profile for Backend VMs.')
param BackendVMTemplate string = 'Standard_D8s_v3 2xP10 (256MB/node)'

@description('Name of the Network Security Group for the Frontend Resources.')
param FrontendNetworkSecurityGroupName string = 'frontendNSG'

@description('Default value of 0.0.0.0/0 allows management and connections from the entire Internet')
param AllowFrontendConnectionFromIPOrCIDRBlock string = '0.0.0.0/0'

@allowed([
  'No'
  'Yes'
])
@description('Selection to deploy Azure Bastion Frontend')
param DeployAzureBastionFrontend string = 'Yes'

@allowed([
  'No'
  'Yes'
])
@description('Selection to deploy Azure Application Gateway Frontend')
param DeployAppGatewayFrontend string = 'Yes'

@allowed([
  'No'
  'Yes'
])
@description('Selection to deploy Jump Box (VM) Frontend')
param DeployJumpBoxFrontend string = 'Yes'

@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/301-parameterized-linked-templates/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

var AvailabilitySetFaultDomain = {
  eastus: 3
  eastus2: 3
  westus: 3
  centralus: 3
  northcentralus: 3
  southcentralus: 3
  northeurope: 3
  westeurope: 3
  brazilsouth: 3
  CentralIndia: 3
  CanadaCentral: 3
  westus2: 3
  FranceCentral: 3
}
var maxFaultDomainsforLocation = (contains(AvailabilitySetFaultDomain, location) ? AvailabilitySetFaultDomain[location] : 2)
var storageProfileSimple = {
  Standard_D2s_v3: 1
  Standard_D4s_v3: 1
  Standard_D8s_v3: 2
  Standard_D16s_v3: 4
  Standard_D32s_v3: 8
}
var storageProfileAdvanced = {
  'Standard_D8s_v3 2xP10 (256MB/node)': {
    disksize: 128
    vmsize: 'Standard_D8s_v3'
    diskcount: 2
  }
  'Standard_D8s_v3 1xP30 (1024MB/node)': {
    disksize: 1024
    vmsize: 'Standard_D8s_v3'
    diskcount: 1
  }
  'Standard_D16s_v3 4xP10 (512MB/node)': {
    disksize: 128
    vmsize: 'Standard_D16s_v3'
    diskcount: 4
  }
  'Standard_D16s_v3 2xP30 (2048MB/node)': {
    disksize: 1024
    vmsize: 'Standard_D16s_v3'
    diskcount: 2
  }
  'Standard_D32s_v3 8xP10 (1024MB/node)': {
    disksize: 128
    vmsize: 'Standard_D32s_v3'
    diskcount: 8
  }
  'Standard_D32s_v3 4xP30 (4096MB/node)': {
    disksize: 1024
    vmsize: 'Standard_D32s_v3'
    diskcount: 4
  }
  'Standard_D48s_v3 12xP10 (1536MB/node)': {
    disksize: 128
    vmsize: 'Standard_D48s_v3'
    diskcount: 12
  }
  'Standard_D48s_v3 6xP30 (6144MB/node)': {
    disksize: 1024
    vmsize: 'Standard_D48s_v3'
    diskcount: 6
  }
  'Standard_D64s_v3 12xP10 (1536MB/node)': {
    disksize: 128
    vmsize: 'Standard_D64s_v3'
    diskcount: 12
  }
  'Standard_D64s_v3 6xP30 (6144MB/node)': {
    disksize: 1024
    vmsize: 'Standard_D64s_v3'
    diskcount: 6
  }
}
var ostag = ((OperatingSystemImage == 'Red Hat Enterprise Linux 7 (latest, LVM)') ? 'RH7x' : 'SL12')
var osProfile = {
  RH7x: {
    image: {
      publisher: 'RedHat'
      offer: 'RHEL'
      sku: '7-LVM'
      version: 'latest'
    }
    diskscript: 'scripts/rhel_raid_azure_data.sh'
  }
  SL12: {
    image: {
      publisher: 'suse'
      offer: 'sles-12-sp5-basic'
      sku: 'gen1'
      version: 'latest'
    }
    diskscript: 'scripts/sles_raid_azure_data.sh'
  }
}
var postInstallActions = {
  backend: {
    commandToExecute: 'sh ${osProfile[ostag].diskscript}; sh examplepostinstall1.sh; sh examplepostinstall2.sh'
    fileUris: [
      uri(artifactsLocation, concat(osProfile[ostag].diskscript, artifactsLocationSasToken))
      uri(artifactsLocation, 'scripts/examplepostinstall1.sh${artifactsLocationSasToken}')
      uri(artifactsLocation, 'scripts/examplepostinstall2.sh${artifactsLocationSasToken}')
    ]
  }
  midtier: {
    commandToExecute: 'sh ${osProfile[ostag].diskscript}; sh examplepostinstall1.sh'
    fileUris: [
      uri(artifactsLocation, concat(osProfile[ostag].diskscript, artifactsLocationSasToken))
      uri(artifactsLocation, 'scripts/examplepostinstall1.sh${artifactsLocationSasToken}')
    ]
  }
  jump: {
    commandToExecute: 'sh ${osProfile[ostag].diskscript}; sh examplepostinstall3.sh'
    fileUris: [
      uri(artifactsLocation, concat(osProfile[ostag].diskscript, artifactsLocationSasToken))
      uri(artifactsLocation, 'scripts/examplepostinstall3.sh${artifactsLocationSasToken}')
    ]
  }
}

resource ProximityPlacementGroupName_resource 'Microsoft.Compute/proximityPlacementGroups@2019-07-01' = {
  name: ProximityPlacementGroupName
  location: location
  properties: {}
}

resource BackendVMNameBase_AS 'Microsoft.Compute/availabilitySets@2019-07-01' = if (BackendVMCount > 1) {
  name: '${BackendVMNameBase}-AS'
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: maxFaultDomainsforLocation
    platformUpdateDomainCount: 6
    proximityPlacementGroup: {
      id: ProximityPlacementGroupName_resource.id
    }
  }
}

resource MidtierVMNameBase_AS 'Microsoft.Compute/availabilitySets@2019-07-01' = if (MidtierVMCount > 1) {
  name: '${MidtierVMNameBase}-AS'
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: maxFaultDomainsforLocation
    platformUpdateDomainCount: 6
    proximityPlacementGroup: {
      id: ProximityPlacementGroupName_resource.id
    }
  }
}

resource BackendNetworkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-12-01' = {
  name: BackendNetworkSecurityGroupName
  location: location
  properties: {}
  dependsOn: [
    ProximityPlacementGroupName_resource
  ]
}

resource MidtierNetworkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-12-01' = {
  name: MidtierNetworkSecurityGroupName
  location: location
  properties: {}
  dependsOn: [
    ProximityPlacementGroupName_resource
  ]
}

resource FrontendNetworkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-12-01' = {
  name: FrontendNetworkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow_http_from_ip_or_range_forwebhttp'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: AllowFrontendConnectionFromIPOrCIDRBlock
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 500
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_ssh_from_ip_or_range_for_jumpboxssh'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: AllowFrontendConnectionFromIPOrCIDRBlock
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 510
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_https_from_ip_or_range_for_bastion'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: AllowFrontendConnectionFromIPOrCIDRBlock
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 520
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_ssh_to_vnet_for_bastion'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 530
          direction: 'Outbound'
        }
      }
      {
        name: 'allow_rdp_to_vnet_for_bastion'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 540
          direction: 'Outbound'
        }
      }
      {
        name: 'allow_https_to_azurecloud_for_bastion'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 550
          direction: 'Outbound'
        }
      }
      {
        name: 'allow_management_from_gateway_manager_for_appgateway'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 560
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_https_from_gateway_manager_for_appgateway'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 570
          direction: 'Inbound'
        }
      }
    ]
  }
  dependsOn: [
    ProximityPlacementGroupName_resource
  ]
}

module ParameterizedAppGateway '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('nested/paramappgateway.json', parameters('_artifactsLocationSasToken')))]*/ = if (DeployAppGatewayFrontend == 'Yes') {
  name: 'ParameterizedAppGateway'
  params: {
    location: location
    appgateway_name: 'frontend-appgateway'
    public_ip: frontend_appgateway_ip.id
    vnet_name: VirtualNetworkName
    vnet_subnet_name: 'AppGatewaySubnet'
  }
  dependsOn: [
    VirtualNetworkName_resource
    ProximityPlacementGroupName_resource
  ]
}

module ParameterizedBackendVM_Loop './nested_ParameterizedBackendVM_Loop.bicep' = {
  name: 'ParameterizedBackendVM-Loop'
  params: {
    templateUri: uri(artifactsLocation, 'nested/paramvm.json${artifactsLocationSasToken}')
    location: location
    'Backend VM Template': BackendVMTemplate
    'Backend VM Name Base': BackendVMNameBase
    'Backend VM Count': BackendVMCount
    'Proximity PlacementGroup Name': ProximityPlacementGroupName
    'Admin User for VM Access': AdminUserForVMAccess
    'ssh Key for VM Access': sshKeyForVMAccess
    'Virtual Network Name': VirtualNetworkName
    storageProfileAdvanced: storageProfileAdvanced
    osProfile: osProfile
    ostag: ostag
    postInstallActions: postInstallActions
    availabilityset_id_or_empty: ((BackendVMCount > 1) ? BackendVMNameBase_AS.id : '')
    appgatewaybackend_id_or_empty: ((DeployAppGatewayFrontend == 'Yes') ? resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'frontend-appgateway', 'default-backend') : '')
  }
  dependsOn: [
    VirtualNetworkName_resource
    ProximityPlacementGroupName_resource
    ParameterizedAppGateway
  ]
}

module ParameterizedMidtierVM '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('nested/paramvm.json', parameters('_artifactsLocationSasToken')))]*/ = [for i in range(0, MidtierVMCount): {
  name: 'ParameterizedMidtierVM-${i}'
  params: {
    location: location
    vm_name: '${MidtierVMNameBase}-${i}'
    vm_size: MidtierVMSize
    datadisk_size: 128
    datadisk_count: storageProfileSimple[MidtierVMSize]
    proximity_group_name: ProximityPlacementGroupName
    admin_user: AdminUserForVMAccess
    ssh_pub_key: sshKeyForVMAccess
    vnet_name: VirtualNetworkName
    vnet_subnet_name: 'midtierSubnet'
    os_image: osProfile[ostag].image
    post_install_actions: postInstallActions.midtier
    enable_enhanced_networking: (!(MidtierVMSize == 'Standard_D2s_v3'))
    publicip_id_or_empty: ''
    appgatewaybackend_id_or_empty: ''
    availabilityset_id_or_empty: ((MidtierVMCount > 1) ? MidtierVMNameBase_AS.id : '')
  }
  dependsOn: [
    VirtualNetworkName_resource
    ProximityPlacementGroupName_resource
    MidtierVMNameBase_AS
  ]
}]

module ParameterizedJumpVM '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('nested/paramvm.json', parameters('_artifactsLocationSasToken')))]*/ = if (DeployJumpBoxFrontend == 'Yes') {
  name: 'ParameterizedJumpVM'
  params: {
    location: location
    vm_name: 'frontend-jumpvm'
    vm_size: 'Standard_B2ms'
    datadisk_size: 128
    datadisk_count: 1
    proximity_group_name: ProximityPlacementGroupName
    admin_user: AdminUserForVMAccess
    ssh_pub_key: sshKeyForVMAccess
    vnet_name: VirtualNetworkName
    vnet_subnet_name: 'frontendSubnet'
    os_image: osProfile[ostag].image
    post_install_actions: {
      commandToExecute: '${postInstallActions.jump.commandToExecute} ${string(reference('ParameterizedBackendVM-Loop').outputs.backendIp.value)}'
      fileUris: postInstallActions.jump.fileUris
    }
    enable_enhanced_networking: false
    publicip_id_or_empty: frontend_jumpvm_ip.id
    appgatewaybackend_id_or_empty: ''
    availabilityset_id_or_empty: ''
  }
  dependsOn: [
    VirtualNetworkName_resource
    ProximityPlacementGroupName_resource

    ParameterizedBackendVM_Loop
  ]
}

resource VirtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-12-01' = {
  name: VirtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.2.0.224/27'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.2.0.192/27'
          networkSecurityGroup: {
            id: FrontendNetworkSecurityGroupName_resource.id
          }
        }
      }
      {
        name: 'frontendSubnet'
        properties: {
          addressPrefix: '10.2.0.160/27'
          networkSecurityGroup: {
            id: FrontendNetworkSecurityGroupName_resource.id
          }
        }
      }
      {
        name: 'AppGatewaySubnet'
        properties: {
          addressPrefix: '10.2.0.128/27'
          networkSecurityGroup: {
            id: FrontendNetworkSecurityGroupName_resource.id
          }
        }
      }
      {
        name: 'backendSubnet'
        properties: {
          addressPrefix: '10.2.1.0/24'
          networkSecurityGroup: {
            id: BackendNetworkSecurityGroupName_resource.id
          }
        }
      }
      {
        name: 'midtierSubnet'
        properties: {
          addressPrefix: '10.2.0.0/28'
          networkSecurityGroup: {
            id: MidtierNetworkSecurityGroupName_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    ProximityPlacementGroupName_resource
  ]
}

resource frontend_bastion_ip 'Microsoft.Network/publicIPAddresses@2019-12-01' = if (DeployAzureBastionFrontend == 'Yes') {
  name: 'frontend-bastion-ip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  dependsOn: [
    ProximityPlacementGroupName_resource
  ]
}

resource frontend_jumpvm_ip 'Microsoft.Network/publicIPAddresses@2019-12-01' = if (DeployJumpBoxFrontend == 'Yes') {
  name: 'frontend-jumpvm-ip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  dependsOn: [
    ProximityPlacementGroupName_resource
  ]
}

resource frontend_appgateway_ip 'Microsoft.Network/publicIPAddresses@2019-12-01' = if (DeployAppGatewayFrontend == 'Yes') {
  name: 'frontend-appgateway-ip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  dependsOn: [
    ProximityPlacementGroupName_resource
  ]
}

resource bastion 'Microsoft.Network/bastionHosts@2019-12-01' = if (DeployAzureBastionFrontend == 'Yes') {
  name: 'bastion'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: frontend_bastion_ip.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', VirtualNetworkName, 'AzureBastionSubnet')
          }
        }
      }
    ]
  }
  dependsOn: [
    VirtualNetworkName_resource
    ProximityPlacementGroupName_resource
  ]
}