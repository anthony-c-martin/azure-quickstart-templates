@minLength(1)
@maxLength(5)
@description('Define the project name or prefix for all objects.')
param projectName string

@description('What is the username for the admin on VMs and SQL Server?')
param adminUser string

@description('What is the password for the admin on VMs and SQL Server?')
@secure()
param adminPasswd string

@description('The location for resources on template. By default, the same as resource group location.')
param location string = resourceGroup().location

@description('TimeZone ID to be used on VMs. Get available timezones with powershell Get-TimeZone command.')
param timeZoneID string = 'UTC'

@description('External public DNS domain zone. NOT AD domain. This the external domain your certs will point to.')
param externalDnsZone string = 'contosocorp.com'

@description('This will trigger certificate request and HA deployment. If set to false, will not create HA deployment nor request certificates.')
param deployHA bool = false

@description('How many Domain Controllers would you like to deploy?')
param dcCount int = 1

@description('How many RD Connection Brokers would you like to deploy?')
param rdcbCount int = 1

@description('How many RD Web Access/Gateways would you like to deploy?')
param rdwgCount int = 1

@description('How many RD Session Hosts would you like to deploy?')
param rdshCount int = 1

@description('How many License/File Servers would you like to deploy?')
param lsfsCount int = 1

@allowed([
  'Standard_A2_v2'
  'Standard_A4_v2'
  'Standard_A8_v2'
  'Standard_D1_v2'
  'Standard_D2_v2'
  'Standard_D3_v2'
  'Standard_D2_v3'
  'Standard_D4_v3'
  'Standard_DS1_v2'
  'Standard_DS2_v2'
])
@description('What is the VM size for all VMs?')
param vmSize string = 'Standard_A2_v2'

@description('Create Azure Spot VMs?')
param vmSpot bool = true

@allowed([
  'StandardSSD_LRS'
  'Standard_LRS'
])
@description('What is the SKU for the storage to VM managed disks?')
param vmStorageSkuType string = 'Standard_LRS'

@description('What is the new forest/root Active Directory domain name?')
param adDomainName string = 'contoso.com'

@description('What is the prefix for the vnet and first subnet?')
param vNetPrefix string = '10.100'

@description('What is the vnet address space?')
param vNetAddressSpace string = '${vNetPrefix}.0.0/16'

@description('What is the subnet address prefix?')
param vNetSubnetAddress string = '${vNetPrefix}.0.0/24'

@description('Location of all scripts and DSC resources for RDS deployment.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-rds-deployment-full-ha/'

@description('SAS storage token to access _artifactsLocation. No need to change unless you copy or fork this template.')
@secure()
param artifactsLocationSasToken string = ''

var uniqueName = substring(uniqueString(resourceGroup().id, deployment().name), 0, 5)
var dnsEntry = 'remoteapps'
var brokerName = 'broker'
var externalFqdn = '${dnsEntry}.${toLower(externalDnsZone)}'
var brokerFqdn = '${brokerName}.${toLower(externalDnsZone)}'
var vmNames = [
  '${toLower(projectName)}${uniqueName}dc'
  '${toLower(projectName)}${uniqueName}wg'
  '${toLower(projectName)}${uniqueName}cb'
  '${toLower(projectName)}${uniqueName}sh'
  '${toLower(projectName)}${uniqueName}lf'
]
var vmProperties = [
  {
    name: vmNames[0]
    count: dcCount
    intLbBackEndPool: ''
    pubLbBackEndPool: ''
    dscFunction: 'DeployRDSLab.ps1\\CreateRootDomain'
  }
  {
    name: vmNames[1]
    count: rdwgCount
    intLbBackEndPool: 'rds-webgateways-int-pool'
    pubLbBackEndPool: 'rds-webgateways-pub-pool'
    dscFunction: 'DeployRDSLab.ps1\\RDWebGateway'
  }
  {
    name: vmNames[2]
    count: rdcbCount
    intLbBackEndPool: 'rds-brokers-int-pool'
    pubLbBackEndPool: ''
    dscFunction: 'DeployRDSLab.ps1\\RDSDeployment'
  }
  {
    name: vmNames[3]
    count: rdshCount
    intLbBackEndPool: ''
    pubLbBackEndPool: ''
    dscFunction: 'DeployRDSLab.ps1\\RDSessionHost'
  }
  {
    name: vmNames[4]
    count: lsfsCount
    intLbBackEndPool: ''
    pubLbBackEndPool: ''
    dscFunction: 'DeployRDSLab.ps1\\RDLicenseServer'
  }
]
var diagStorageName_var = '${toLower(projectName)}${uniqueName}diag'
var publicLbIpName_var = '${toLower(projectName)}lbpip'
var diagStorageSkuType = 'Standard_LRS'
var vNetName = '${projectName}vnet'
var firstDcIP = '${vNetPrefix}.0.99'
var nsgRef = projectName_nsg.id
var subNetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', vNetName, '${projectName}main')
var sqlServerName_var = '${toLower(projectName)}${uniqueName}sql'
var rdsDBName = 'rdsdb'
var dscScriptName = 'deployrdslab.zip'
var scriptName = 'deploycertha.ps1'

resource diagStorageName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  location: location
  kind: 'StorageV2'
  name: diagStorageName_var
  sku: {
    name: diagStorageSkuType
    tier: 'Standard'
  }
}

resource projectName_nsg 'Microsoft.Network/networkSecurityGroups@2019-12-01' = {
  location: location
  name: '${projectName}nsg'
  properties: {
    securityRules: [
      {
        name: 'Allow_RDP'
        properties: {
          access: 'Allow'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
          protocol: '*'
          direction: 'Inbound'
          priority: 1000
        }
      }
      {
        name: 'Allow_HTTP'
        properties: {
          access: 'Allow'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
          protocol: 'Tcp'
          direction: 'Inbound'
          priority: 1001
        }
      }
      {
        name: 'Allow_HTTPS'
        properties: {
          access: 'Allow'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          protocol: 'Tcp'
          direction: 'Inbound'
          priority: 1002
        }
      }
      {
        name: 'Allow_UDP_3391'
        properties: {
          access: 'Allow'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3391'
          protocol: 'Udp'
          direction: 'Inbound'
          priority: 1003
        }
      }
    ]
  }
}

resource projectName_vnet 'Microsoft.Network/virtualNetworks@2019-12-01' = {
  location: location
  name: '${projectName}vnet'
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNetAddressSpace
      ]
    }
    subnets: [
      {
        name: '${projectName}main'
        properties: {
          addressPrefix: vNetSubnetAddress
          networkSecurityGroup: {
            id: nsgRef
          }
        }
      }
    ]
  }
  dependsOn: [
    nsgRef
  ]
}

resource projectName_intlb 'Microsoft.Network/loadBalancers@2019-12-01' = {
  location: location
  name: '${projectName}intlb'
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'rds-brokers-frontend'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '${vNetPrefix}.0.4'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: subNetRef
          }
        }
      }
      {
        name: 'rds-webgateways-frontend'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: subNetRef
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'rds-brokers-int-pool'
        properties: {}
      }
      {
        name: 'rds-webgateways-int-pool'
        properties: {}
      }
    ]
    probes: [
      {
        name: 'rds-broker-probe'
        properties: {
          intervalInSeconds: 5
          numberOfProbes: 2
          protocol: 'Tcp'
          port: 3389
        }
      }
      {
        name: 'rds-webgateway-probe'
        properties: {
          intervalInSeconds: 5
          numberOfProbes: 2
          protocol: 'Tcp'
          port: 443
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'rds-brokers-tcp-rule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', '${projectName}intlb', 'rds-brokers-frontend')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', '${projectName}intlb', 'rds-brokers-int-pool')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', '${projectName}intlb', 'rds-broker-probe')
          }
          protocol: 'Tcp'
          frontendPort: 3389
          backendPort: 3389
          idleTimeoutInMinutes: 4
        }
      }
      {
        name: 'rds-brokers-udp-rule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', '${projectName}intlb', 'rds-brokers-frontend')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', '${projectName}intlb', 'rds-brokers-int-pool')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', '${projectName}intlb', 'rds-broker-probe')
          }
          protocol: 'Udp'
          frontendPort: 3389
          backendPort: 3389
          idleTimeoutInMinutes: 4
        }
      }
      {
        name: 'rds-webgateway-http-rule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', '${projectName}intlb', 'rds-webgateways-frontend')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', '${projectName}intlb', 'rds-webgateways-int-pool')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', '${projectName}intlb', 'rds-webgateway-probe')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 4
        }
      }
      {
        name: 'rds-webgateway-https-rule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', '${projectName}intlb', 'rds-webgateways-frontend')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', '${projectName}intlb', 'rds-webgateways-int-pool')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', '${projectName}intlb', 'rds-webgateway-probe')
          }
          protocol: 'Tcp'
          frontendPort: 443
          backendPort: 443
          idleTimeoutInMinutes: 4
        }
      }
      {
        name: 'rds-webgateway-udp-rule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', '${projectName}intlb', 'rds-webgateways-frontend')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', '${projectName}intlb', 'rds-webgateways-int-pool')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', '${projectName}intlb', 'rds-webgateway-probe')
          }
          protocol: 'Udp'
          frontendPort: 3391
          backendPort: 3391
          idleTimeoutInMinutes: 4
        }
      }
    ]
  }
  dependsOn: [
    projectName_vnet
  ]
}

resource publicLbIpName 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: publicLbIpName_var
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: publicLbIpName_var
    }
  }
}

resource projectName_publb 'Microsoft.Network/loadBalancers@2019-11-01' = {
  name: '${projectName}publb'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'rds-webgateways-frontend'
        properties: {
          publicIPAddress: {
            id: publicLbIpName.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'rds-webgateways-pub-pool'
      }
    ]
    probes: [
      {
        name: 'rds-webgateways-probe'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'rds-webgateways-http-rule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', '${projectName}publb', 'rds-webgateways-frontend')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', '${projectName}publb', 'rds-webgateways-pub-pool')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', '${projectName}publb', 'rds-webgateways-probe')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
        }
      }
      {
        name: 'rds-webgateways-https-rule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', '${projectName}publb', 'rds-webgateways-frontend')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', '${projectName}publb', 'rds-webgateways-pub-pool')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', '${projectName}publb', 'rds-webgateways-probe')
          }
          protocol: 'Tcp'
          frontendPort: 443
          backendPort: 443
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
        }
      }
      {
        name: 'rds-webgateways-udp-rule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', '${projectName}publb', 'rds-webgateways-frontend')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', '${projectName}publb', 'rds-webgateways-pub-pool')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', '${projectName}publb', 'rds-webgateways-probe')
          }
          protocol: 'Udp'
          frontendPort: 3391
          backendPort: 3391
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
        }
      }
    ]
  }
  dependsOn: [
    projectName_vnet
  ]
}

resource sqlServerName 'Microsoft.Sql/servers@2019-06-01-preview' = {
  name: sqlServerName_var
  location: location
  properties: {
    administratorLogin: adminUser
    administratorLoginPassword: adminPasswd
  }
}

resource sqlServerName_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2019-06-01-preview' = {
  parent: sqlServerName
  location: location
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlServerName_rdsDBName 'Microsoft.Sql/servers/databases@2019-06-01-preview' = {
  parent: sqlServerName
  name: '${rdsDBName}'
  location: location
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    edition: 'Basic'
    maxSizeBytes: '1073741824'
    requestedServiceObjectiveName: 'Basic'
  }
}

module vmProperties_name_Deployment './nested_vmProperties_name_Deployment.bicep' = [for item in vmProperties: {
  name: '${item.name}Deployment'
  params: {
    projectName: projectName
    location: location
    timeZoneID: timeZoneID
    loopCount: item.count
    storageDiagUrl: diagStorageName.properties.primaryEndpoints.blob
    vmName: item.name
    subNetRef: subNetRef
    vmSize: vmSize
    vmSpot: vmSpot
    vmStorageSkuType: vmStorageSkuType
    adminUser: adminUser
    adminPasswd: adminPasswd
    intLbName: '${projectName}intlb'
    intLbBackEndPool: item.intLbBackEndPool
    intLbBrokerIP: projectName_intlb.properties.frontendIPConfigurations[0].properties.privateIPAddress
    intLbWebGWIP: projectName_intlb.properties.frontendIPConfigurations[1].properties.privateIPAddress
    pubLbName: '${projectName}publb'
    pubLbBackEndPool: item.pubLbBackEndPool
    adDomainName: adDomainName
    firstDcIP: firstDcIP
    dcName: vmProperties[0].name
    MainConnectionBroker: '${vmProperties[2].name}1'
    WebAccessServerName: vmProperties[1].name
    WebAccessServerCount: vmProperties[1].count
    SessionHostName: vmProperties[3].name
    SessionHostCount: vmProperties[3].count
    LicenseServerName: vmProperties[4].name
    LicenseServerCount: vmProperties[4].count
    externalFqdn: externalFqdn
    brokerFqdn: brokerFqdn
    externalDnsZone: externalDnsZone
    dscFunction: item.dscFunction
    dscLocation: artifactsLocation
    dscScriptName: dscScriptName
    scriptName: scriptName
    deployHA: deployHA
    rdsDBName: rdsDBName
    azureSQLFqdn: sqlServerName.properties.fullyQualifiedDomainName
    webGwName: dnsEntry
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    projectName_vnet
    projectName_intlb
    projectName_publb
    diagStorageName
    sqlServerName_rdsDBName
  ]
}]

output adminUser string = adminUser
output WebAccessFQDN string = publicLbIpName.properties.dnsSettings.fqdn
output ExternalFQDN string = externalFqdn