param siteName string {
  metadata: {
    description: 'DNS of the WebApp'
  }
}
param addressPrefix string {
  metadata: {
    description: 'Address prefix for the Virtual Network'
  }
  default: '10.0.0.0/16'
}
param subnetPrefix string {
  metadata: {
    description: 'Subnet prefix'
  }
  default: '10.0.0.0/28'
}
param administratorLogin string {
  minLength: 1
  metadata: {
    description: 'Database administrator login name'
  }
}
param administratorLoginPassword string {
  minLength: 8
  maxLength: 128
  metadata: {
    description: 'Database administrator password'
  }
  secure: true
}
param databaseSkuName string {
  metadata: {
    description: 'Azure database for MySQL sku name'
  }
  default: 'GP_Gen5_8'
}
param databaseSkuFamily string {
  metadata: {
    description: 'Azure database for MySQL sku family'
  }
  default: 'Gen5'
}
param databaseSkuSizeMB int {
  allowed: [
    102400
    51200
  ]
  metadata: {
    description: 'Azure database for MySQL Sku Size'
  }
  default: 51200
}
param databaseSkuTier string {
  metadata: {
    description: 'Azure database for MySQL pricing tier'
  }
  default: 'GeneralPurpose'
}
param mysqlVersion string {
  allowed: [
    '5.6'
    '5.7'
  ]
  metadata: {
    description: 'MySQL version'
  }
  default: '5.6'
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-application-gateway-webapp-iprestriction/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var applicationGatewayName = '${siteName}-agw'
var publicIPAddressName = '${siteName}-pip'
var virtualNetworkName = 'virtualNetwork1'
var subnetName = 'appGatewaySubnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var publicIPRef = publicIPAddressName_resource.id
var databaseName = '${siteName}db'
var serverName = '${siteName}mysqlserver'
var hostingPlanName = '${siteName}serviceplan'

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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

resource applicationGatewayName_resource 'Microsoft.Network/applicationGateways@2020-05-01' = {
  name: applicationGatewayName
  location: location
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          PublicIPAddress: {
            id: publicIPRef
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          Port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          BackendAddresses: [
            {
              IpAddress: reference(siteName).defaultHostName
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          Port: 80
          Protocol: 'Http'
          CookieBasedAffinity: 'Disabled'
          PickHostNameFromBackendAddress: true
          ProbeEnabled: true
          Probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes/', applicationGatewayName, 'Probe1')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          FrontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations/', applicationGatewayName, 'appGatewayFrontendIP')
          }
          FrontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts/', applicationGatewayName, 'appGatewayFrontendPort')
          }
          Protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        Name: 'rule1'
        properties: {
          RuleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners/', applicationGatewayName, 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools/', applicationGatewayName, 'appGatewayBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection/', applicationGatewayName, 'appGatewayBackendHttpSettings')
          }
        }
      }
    ]
    probes: [
      {
        Name: 'Probe1'
        properties: {
          Protocol: 'Http'
          Path: '/'
          Interval: 30
          Timeout: 10
          UnhealthyThreshold: 3
          MinServers: 0
          PickHostNameFromBackendHttpSettings: true
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
    publicIPAddressName_resource
    siteName_resource
  ]
}

module fetchIpAddress '<failed to parse [uri(parameters(\'_artifactsLocation\'), concat(\'fetchIpAddress.json\', parameters(\'_artifactsLocationSasToken\')))]>' = {
  name: 'fetchIpAddress'
  params: {
    publicIPAddressId: publicIPAddressName_resource.id
  }
  dependsOn: [
    applicationGatewayName_resource
  ]
}

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: hostingPlanName
  location: location
  tags: {
    displayName: 'HostingPlan'
  }
  sku: {
    name: 'S1'
    capacity: '1'
  }
  properties: {
    name: hostingPlanName
  }
}

resource siteName_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: siteName
  location: location
  properties: {
    name: siteName
    serverFarmId: hostingPlanName_resource.id
  }
  dependsOn: [
    hostingPlanName_resource
  ]
}

resource siteName_connectionstrings 'Microsoft.Web/sites/config@2019-08-01' = {
  name: '${siteName}/connectionstrings'
  properties: {
    DefaultConnection: {
      value: 'Database=${databaseName};Data Source=${serverName_resource.properties.fullyQualifiedDomainName};User Id=${administratorLogin}@${serverName};Password=${administratorLoginPassword}'
      type: 'MySql'
    }
  }
  dependsOn: [
    siteName_resource
  ]
}

resource siteName_web 'Microsoft.Web/sites/config@2019-08-01' = {
  name: '${siteName}/web'
  properties: {
    ipSecurityRestrictions: [
      {
        ipAddress: '${reference('fetchIpAddress').outputs.ipAddress.value}/32'
      }
    ]
  }
  dependsOn: [
    siteName_resource
    fetchIpAddress
  ]
}

resource serverName_resource 'Microsoft.DBforMySQL/servers@2017-12-01' = {
  location: location
  name: serverName
  properties: {
    createMode: 'Default'
    version: mysqlVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storageMB: databaseSkuSizeMB
  }
  sku: {
    name: databaseSkuName
    tier: databaseSkuTier
    size: databaseSkuSizeMB
    family: databaseSkuFamily
  }
}

resource serverName_serverName_firewall 'Microsoft.DBforMySQL/servers/firewallrules@2017-12-01' = {
  location: location
  name: '${serverName}/${serverName}firewall'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
  dependsOn: [
    serverName_resource
  ]
}

resource serverName_databaseName 'Microsoft.DBforMySQL/servers/databases@2017-12-01' = {
  name: '${serverName}/${databaseName}'
  properties: {
    charset: 'utf8'
    collation: 'utf8_general_ci'
  }
  dependsOn: [
    serverName_resource
  ]
}