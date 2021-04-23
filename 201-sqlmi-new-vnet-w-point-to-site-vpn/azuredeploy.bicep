@description('Enter managed instance name.')
param managedInstanceName string

@description('Enter user name.')
param administratorLogin string

@description('Enter password.')
@secure()
param administratorLoginPassword string

@description('Client root certificate data used to authenticate VPN clients.')
param publicRootCertData string

@description('Enter location. If you leave this field blank resource group location would be used.')
param location string = resourceGroup().location

@description('Enter virtual network name. If you leave this field blank name will be created by the template.')
param virtualNetworkName string = 'SQLMI-VNET'

@description('Enter virtual network address prefix.')
param addressPrefix string = '10.0.0.0/16'

@description('Enter subnet name.')
param subnetName string = 'ManagedInstance'

@description('Enter subnet address prefix.')
param subnetPrefix string = '10.0.0.0/24'

@description('The prefix for the GatewaySubnet where the VirtualNetworkGateway will be deployed. This must be at least /29.')
param gatewaySubnetPrefix string = '10.0.1.0/28'

@description('The IP address range from which VPN clients will receive an IP address when connected. Range specified must not overlap with on-premise network.')
param vpnClientAddressPoolPrefix string = '192.168.0.0/24'

@allowed([
  'GP_Gen5'
  'BC_Gen5'
])
@description('Enter sku name.')
param skuName string = 'GP_Gen5'

@allowed([
  8
  16
  24
  32
  40
  64
  80
])
@description('Enter number of vCores.')
param vCores int = 16

@minValue(32)
@maxValue(8192)
@description('Enter storage size.')
param storageSizeInGB int = 256

@allowed([
  'BasePrice'
  'LicenseIncluded'
])
@description('Enter license type.')
param licenseType string = 'LicenseIncluded'

var networkSecurityGroupName_var = 'SQLMI-${managedInstanceName}-NSG'
var routeTableName_var = 'SQLMI-${managedInstanceName}-Route-Table'
var gatewayPublicIpAddressName_var = 'SQLMI-${managedInstanceName}-Gateway-IP'
var gatewayName_var = 'SQLMI-${managedInstanceName}-Gateway'
var gatewaySku = 'Basic'
var gatewaySubnetName = 'GatewaySubnet'
var clientRootCertName = 'RootCert'

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-06-01' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow_tds_inbound'
        properties: {
          description: 'Allow access to data'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_redirect_inbound'
        properties: {
          description: 'Allow inbound redirect traffic to Managed Instance inside the virtual network'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '11000-11999'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1100
          direction: 'Inbound'
        }
      }
      {
        name: 'deny_all_inbound'
        properties: {
          description: 'Deny all other inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_misubnet_outbound'
        properties: {
          description: 'Allow outbound traffic inside the subnet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: subnetPrefix
          access: 'Allow'
          priority: 200
          direction: 'Outbound'
        }
      }
      {
        name: 'deny_all_outbound'
        properties: {
          description: 'Deny all other outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource routeTableName 'Microsoft.Network/routeTables@2019-06-01' = {
  name: routeTableName_var
  location: location
  properties: {
    disableBgpRoutePropagation: false
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-06-01' = {
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
          routeTable: {
            id: routeTableName.id
          }
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
          delegations: [
            {
              name: 'miDelegation'
              properties: {
                serviceName: 'Microsoft.Sql/managedInstances'
              }
            }
          ]
        }
      }
      {
        name: gatewaySubnetName
        properties: {
          addressPrefix: gatewaySubnetPrefix
        }
      }
    ]
  }
}

resource managedInstanceName_resource 'Microsoft.Sql/managedInstances@2019-06-01-preview' = {
  identity: {
    type: 'SystemAssigned'
  }
  location: location
  name: managedInstanceName
  sku: {
    name: skuName
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
    storageSizeInGB: storageSizeInGB
    vCores: vCores
    licenseType: licenseType
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource gatewayPublicIpAddressName 'Microsoft.Network/publicIPAddresses@2019-06-01' = {
  name: gatewayPublicIpAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource gatewayName 'Microsoft.Network/virtualNetworkGateways@2019-06-01' = {
  name: gatewayName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, gatewaySubnetName)
          }
          publicIPAddress: {
            id: gatewayPublicIpAddressName.id
          }
        }
        name: 'vnetGatewayConfig'
      }
    ]
    sku: {
      name: gatewaySku
      tier: gatewaySku
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: 'false'
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          vpnClientAddressPoolPrefix
        ]
      }
      vpnClientRootCertificates: [
        {
          name: clientRootCertName
          properties: {
            publicCertData: publicRootCertData
          }
        }
      ]
    }
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}