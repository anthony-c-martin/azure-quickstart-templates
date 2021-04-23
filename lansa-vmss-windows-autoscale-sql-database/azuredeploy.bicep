@description('Resource Group Location.')
param location string = resourceGroup().location

@description('URL of the LANSA MSI which will be installed on each virtual machine.')
param msiURL string = 'https://lansalpcmsdn.blob.core.windows.net/app/test/AWAMAPP_v14.1.2_en-us.msi'

@description('Size of the Virtual Machines in the Virtual Machine Scale Set.')
param virtualMachineSize string = 'Standard_B4ms'

@description('Size of the Virtual Machine which manages the database.')
param dbVirtualMachineSize string = 'Standard_B2ms'

@minLength(3)
@maxLength(61)
@description('String used as a base for naming resources. Must be 3-61 characters in length and globally unique across Azure. A hash is prepended to this string for some resources, and resource-specific information is appended. Some identifiers use precisely 9 characters from this name and so it can be useful to use exactly 9. The template pads it out or truncates it as necessary to make it 9 characters long where required.')
param stackName string

@allowed([
  'Standard'
  'WAF'
])
@description('Application Gateway SKU Tier')
param applicationGatewaySkuTier string = 'Standard'

@allowed([
  'Standard_Small'
  'Standard_Medium'
  'Standard_Large'
  'WAF_Medium'
  'WAF_Large'
  'WAF_v2'
])
@description('Application Gateway SKU Name')
param applicationGatewaySkuName string = 'Standard_Medium'

@description('Number of Application Gateway instances')
param applicationGatewayCapacity int = 2

@description('Base 64 encoded String representing the SSL certificate')
param certificateBase64Encoded string

@description('SSL certificate password')
@secure()
param certificatePassword string

@minValue(1)
@maxValue(100)
@description('Minimum number of Virtual Machine instances (1 or more).')
param minimumInstanceCount int = 1

@minValue(1)
@maxValue(100)
@description('Maximum number of Virtual Machine instances (100 or less).')
param maximumInstanceCount int = 100

@allowed([
  'new'
  'existing'
])
@description('Determines whether a new SQL database should be provisioned or to use an existing database. Parameters which are relevant to choosing \'new\' are prefixed \'New DB\'. Parameters which are relevant to choosing \'existing\' are prefixed \'Existing DB\'.')
param databaseNewOrExisting string = 'new'

@allowed([
  'MSSQLS'
  'SQLAZURE'
  'MYSQL'
])
@description('Existing DB. Refer to LANSA documentation for an explanation of each Database Type and the supported versions of the database servers. DO NOT CHANGE THIS IF CREATING A NEW DATABASE. IT MUST BE SET TO SQLAZURE.')
param databaseType string = 'SQLAZURE'

@description('Existing DB. The name of the existing Database Server to connect to. If the name has /MSSQLSERVER appended, omit it.')
param databaseServerName string = 'lansa'

@description('The name of the new database to create or name of the existing database to connect to.')
param databaseName string = 'lansa'

@description('The admin user of the Azure SQL Database')
param databaseLogin string

@description('The password of the admin user of the Azure SQL Database')
@secure()
param databaseLoginPassword string

@description('New DB. The new database collation for governing the proper use of characters.')
param collation string = 'SQL_Latin1_General_CP1_CI_AS'

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
@description('New DB. The type of database to create.')
param edition string = 'Standard'

@allowed([
  'Basic'
  'S0'
  'S1'
  'S2'
  'S3'
  'S4'
  'S6'
  'S7'
  'S9'
  'S12'
  'P1'
  'P2'
  'P4'
  'P6'
  'P11'
  'P15'
])
@description('New DB. Describes the performance level for Edition')
param requestedServiceObjectiveName string = 'S2'

@description('New DB. The maximum size, in bytes, for the new database')
param maxSizeBytes string = '1073741824'

@description('Admin username on all VMs.')
param adminUsername string

@description('Admin password on all VMs.')
@secure()
param adminPassword string

@description('Web Server username on all VMs. This must be different to the Admin Username.')
param webUsername string

@description('Web Server password on all VMs.')
@secure()
param webPassword string

@description('The maximum number of LANSA jobs to run on each Web Server. Setting triggerWebConfig will cause this value to be updated.')
param webServerMaxConnect string = '20'

@description('Install the MSI: Set this to 1 to execute an MSI install. Usually set to 0 when updating the stack')
param installMSI string = '0'

@description('Update Stack: Set this to 1 to execute an MSI Upgrade. Obtains the specified MSI and installs it. Ensure the LansaMSI parameter is set correctly. If the LansaMSI parameter is not different a repair will be performed')
param updateMSI string = '0'

@description('Uninstall the MSI: Set this to 1 to uninstall the MSI. The MSI used to uninstall, is the last one that was installed. It is called c:\\lansa\\MyApp.msi')
param uninstallMSI string = '0'

@description('Update Stack: Set this to 1 to update the web configuration')
param triggerWebConfig string = '0'

@allowed([
  'lansa-scalable-license'
  'lansa-scalable-license-preview'
])
@description('The offer of the image. Allowed values: lansa-scalable-license, lansa-scalable-license-preview')
param imageOffer string = 'lansa-scalable-license'

@description('Git Branch')
param gitBranch string = 'support/L4W14200_scalable'

@allowed([
  'Y'
  'N'
])
@description('Switch tracing on. Allowed values Y or N')
param trace string = 'N'

@description('Re-run licensing. It is unlikely that this parameter needs to be used')
param fixLicense string = '0'

var isNewDatabase = (databaseNewOrExisting == 'new')
var namingInfix_var = toLower(substring(concat(stackName, uniqueString(resourceGroup().id)), 0, 9))
var longNamingInfix = toLower(stackName)
var dblongNamingInfix = toLower('db${stackName}')
var aglongNamingInfix = toLower('ag${stackName}')
var dbvmssName_var = toLower(substring('db${stackName}${uniqueString(resourceGroup().id)}', 0, 9))
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName_var = '${namingInfix_var}vnet'
var publicIPAddressName_var = '${namingInfix_var}pip'
var dbpublicIPAddressName_var = '${namingInfix_var}dbpip'
var subnetName = '${namingInfix_var}subnet'
var loadBalancerName_var = '${namingInfix_var}lb'
var lbFrontEndName = 'LoadBalancerFrontEnd'
var lbProbeName = 'LoadBalancerProbe'
var dbloadBalancerName_var = '${namingInfix_var}dblb'
var dblbFrontEndName = 'dbLoadBalancerFrontEnd'
var dblbProbeName = 'dbLoadBalancerProbe'
var publicIPAddressID = publicIPAddressName.id
var dbpublicIPAddressID = dbpublicIPAddressName.id
var natPoolName = '${namingInfix_var}natpool'
var bePoolName = '${namingInfix_var}bepool'
var dbbePoolName = '${namingInfix_var}dbbepool'
var natStartPort = 50000
var natEndPort = 50119
var natBackendPort = 3389
var nicName = '${namingInfix_var}nic'
var ipConfigName = '${namingInfix_var}ipconfig'
var frontEndIPConfigID = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName_var, lbFrontEndName)
var imagePublisher = 'lansa'
var imageSku = 'lansa-scalable-license-14-2'
var osType = {
  publisher: imagePublisher
  offer: imageOffer
  sku: imageSku
  version: 'latest'
}
var imageReference = osType
var sqlserverName_var = '${namingInfix_var}sqlserver'
var gitRepo = 'https://raw.githubusercontent.com/robe070/cookbooks/'
var gitRefreshName = 'git-pull.ps1'
var gitRefreshUri = '${gitRepo}${gitBranch}/scripts/${gitRefreshName}'
var q = '\''
var agPublicIPAddressName_var = '${namingInfix_var}-agpip'
var agPublicIPAddressID = agPublicIPAddressName.id
var agSubnetPrefix = '10.0.1.0/24'
var agSubnetName = '${namingInfix_var}-agsubnet'
var agSubnetID = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, agSubnetName)
var agName_var = '${namingInfix_var}-ag'
var agHttpListenerName = 'appGatewayHttpListener'
var agFrontendIPName = 'appGatewayFrontendIP'
var agFrontendPortName = 'appGatewayFrontendPort'
var agSslCertName = 'appGatewaySslCert'
var agBackendHttpSettingsName = 'appGatewayBackendHttpSettings'
var agBackendAddressPoolName = '${namingInfix_var}-agpool'

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2019-08-01' = {
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
      {
        name: agSubnetName
        properties: {
          addressPrefix: agSubnetPrefix
        }
      }
    ]
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2019-08-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: longNamingInfix
    }
  }
}

resource loadBalancerName 'Microsoft.Network/loadBalancers@2019-08-01' = {
  name: loadBalancerName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: lbFrontEndName
        properties: {
          publicIPAddress: {
            id: publicIPAddressID
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: bePoolName
      }
    ]
    inboundNatPools: [
      {
        name: natPoolName
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPortRangeStart: natStartPort
          frontendPortRangeEnd: natEndPort
          backendPort: natBackendPort
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'lbrule'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName_var, bePoolName)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName_var, lbProbeName)
          }
          protocol: 'Tcp'
          loadDistribution: 'SourceIP'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 15
        }
      }
    ]
    probes: [
      {
        name: lbProbeName
        properties: {
          protocol: 'Http'
          port: 80
          intervalInSeconds: 15
          numberOfProbes: 2
          requestPath: 'cgi-bin/probe'
        }
      }
    ]
  }
}

resource dbpublicIPAddressName 'Microsoft.Network/publicIPAddresses@2019-08-01' = {
  name: dbpublicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dblongNamingInfix
    }
  }
}

resource dbloadBalancerName 'Microsoft.Network/loadBalancers@2019-08-01' = {
  name: dbloadBalancerName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: dblbFrontEndName
        properties: {
          publicIPAddress: {
            id: dbpublicIPAddressID
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: dbbePoolName
      }
    ]
    loadBalancingRules: [
      {
        name: 'lbrule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', dbloadBalancerName_var, dblbFrontEndName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', dbloadBalancerName_var, dbbePoolName)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', dbloadBalancerName_var, dblbProbeName)
          }
          protocol: 'Tcp'
          loadDistribution: 'SourceIP'
          frontendPort: 50000
          backendPort: 3389
          idleTimeoutInMinutes: 15
        }
      }
    ]
    probes: [
      {
        name: dblbProbeName
        properties: {
          protocol: 'Tcp'
          port: 3389
          intervalInSeconds: 15
          numberOfProbes: 2
        }
      }
    ]
  }
}

resource dbvmssName 'Microsoft.Compute/virtualMachineScaleSets@2019-07-01' = {
  name: dbvmssName_var
  location: location
  sku: {
    name: dbVirtualMachineSize
    tier: 'Standard'
    capacity: 1
  }
  plan: {
    name: imageSku
    product: imageOffer
    publisher: imagePublisher
  }
  properties: {
    overprovision: false
    upgradePolicy: {
      mode: 'Automatic'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          caching: 'ReadOnly'
          createOption: 'FromImage'
        }
        imageReference: imageReference
      }
      osProfile: {
        computerNamePrefix: dbvmssName_var
        adminUsername: adminUsername
        adminPassword: adminPassword
        windowsConfiguration: {
          provisionVMAgent: true
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'db${nicName}'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'db${ipConfigName}'
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', dbloadBalancerName_var, dbbePoolName)
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
      extensionProfile: {
        extensions: [
          {
            name: 'FirstInstall'
            properties: {
              publisher: 'Microsoft.Compute'
              type: 'CustomScriptExtension'
              typeHandlerVersion: '1.9'
              autoUpgradeMinorVersion: true
              forceUpdateTag: concat(installMSI, updateMSI, triggerWebConfig, uninstallMSI, fixLicense, trace, gitBranch)
              settings: {
                fileUris: [
                  gitRefreshUri
                ]
              }
              protectedSettings: {
                commandToExecute: 'powershell -NoProfile -ExecutionPolicy unrestricted -command "& {pushd;./${gitRefreshName} ${gitBranch};popd;pushd;c:\\lansa\\scripts\\azure-custom-script.ps1 -server_name ${q}${(isNewDatabase ? reference(sqlserverName_var).fullyQualifiedDomainName : databaseServerName)}${q} -DBUT ${q}${databaseType}${q} -dbname ${q}${databaseName}${q} -dbuser ${q}${databaseLogin}${q} -dbpassword ${q}${databaseLoginPassword}${q} -webuser ${q}${webUsername}${q} -webpassword ${q}${webPassword}${q} -MSIuri ${q}${msiURL}${q} -maxconnections ${q}${webServerMaxConnect}${q} -trace ${q}${trace}${q} -installMSI ${q}${installMSI}${q} -updateMSI ${q}${updateMSI}${q} -triggerWebConfig ${q}${triggerWebConfig}${q} -UninstallMSI ${q}${uninstallMSI}${q} -fixLicense ${q}${fixLicense}${q};if ($LASTEXITCODE -ne 0) {Write-Error ("MSI Install failed");exit $LASTEXITCODE}; exit 0;popd;}"'
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    loadBalancerName
    virtualNetworkName
    sqlserverName
    sqlserverName_databaseName
    agName
  ]
}

resource namingInfix 'Microsoft.Compute/virtualMachineScaleSets@2019-07-01' = {
  name: namingInfix_var
  location: location
  sku: {
    name: virtualMachineSize
    tier: 'Standard'
    capacity: minimumInstanceCount
  }
  plan: {
    name: imageSku
    product: imageOffer
    publisher: imagePublisher
  }
  properties: {
    overprovision: false
    upgradePolicy: {
      mode: 'Automatic'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          caching: 'ReadOnly'
          createOption: 'FromImage'
        }
        imageReference: imageReference
      }
      osProfile: {
        computerNamePrefix: namingInfix_var
        adminUsername: adminUsername
        adminPassword: adminPassword
        windowsConfiguration: {
          provisionVMAgent: true
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: nicName
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: ipConfigName
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName_var, bePoolName)
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', loadBalancerName_var, natPoolName)
                      }
                    ]
                    applicationGatewayBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', agName_var, agBackendAddressPoolName)
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
      extensionProfile: {
        extensions: [
          {
            name: 'MainInstall'
            properties: {
              publisher: 'Microsoft.Compute'
              type: 'CustomScriptExtension'
              typeHandlerVersion: '1.9'
              autoUpgradeMinorVersion: true
              forceUpdateTag: concat(installMSI, updateMSI, triggerWebConfig, uninstallMSI, fixLicense, trace, gitBranch)
              settings: {
                fileUris: [
                  gitRefreshUri
                ]
              }
              protectedSettings: {
                commandToExecute: 'powershell -NoProfile -ExecutionPolicy unrestricted -command "& {pushd;./${gitRefreshName} ${gitBranch};popd;pushd;c:\\lansa\\scripts\\azure-custom-script.ps1 -SUDB "0" -server_name ${q}${(isNewDatabase ? reference(sqlserverName_var).fullyQualifiedDomainName : databaseServerName)}${q} -DBUT ${q}${databaseType}${q} -dbname ${q}${databaseName}${q} -dbuser ${q}${databaseLogin}${q} -dbpassword ${q}${databaseLoginPassword}${q} -webuser ${q}${webUsername}${q} -webpassword ${q}${webPassword}${q} -MSIuri ${q}${msiURL}${q} -maxconnections ${q}${webServerMaxConnect}${q} -trace ${q}${trace}${q} -installMSI ${q}${installMSI}${q} -updateMSI ${q}${updateMSI}${q} -triggerWebConfig ${q}${triggerWebConfig}${q} -UninstallMSI ${q}${uninstallMSI}${q} -fixLicense ${q}${fixLicense}${q};if ($LASTEXITCODE -ne 0) {Write-Error ("MSI Install failed");exit $LASTEXITCODE}; exit 0;popd;}"'
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    loadBalancerName
    virtualNetworkName
    sqlserverName
    sqlserverName_databaseName
    dbvmssName
  ]
}

resource autoscalehost 'Microsoft.Insights/autoscaleSettings@2015-04-01' = {
  name: 'autoscalehost'
  location: location
  properties: {
    name: 'autoscalehost'
    targetResourceUri: namingInfix.id
    enabled: true
    profiles: [
      {
        name: 'Profile1'
        capacity: {
          minimum: minimumInstanceCount
          maximum: maximumInstanceCount
          default: minimumInstanceCount
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricResourceUri: namingInfix.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: '60'
            }
            scaleAction: {
              direction: 'Increase'
              type: 'PercentChangeCount'
              value: '10'
              cooldown: 'PT20M'
            }
          }
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricResourceUri: namingInfix.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: '30'
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT20M'
            }
          }
        ]
      }
    ]
  }
}

resource Microsoft_Insights_autoscaleSettings_dbvmssName 'Microsoft.Insights/autoscaleSettings@2015-04-01' = {
  name: dbvmssName_var
  location: location
  properties: {
    name: dbvmssName_var
    targetResourceUri: dbvmssName.id
    enabled: true
    profiles: [
      {
        name: 'Single Fixed Instance'
        capacity: {
          minimum: '1'
          maximum: '1'
          default: '1'
        }
      }
    ]
  }
}

resource agPublicIPAddressName 'Microsoft.Network/publicIPAddresses@2019-08-01' = {
  name: agPublicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: aglongNamingInfix
    }
  }
}

resource agName 'Microsoft.Network/applicationGateways@2019-04-01' = {
  name: agName_var
  location: location
  properties: {
    sku: {
      tier: applicationGatewaySkuTier
      name: applicationGatewaySkuName
      capacity: applicationGatewayCapacity
    }
    sslCertificates: [
      {
        name: agSslCertName
        properties: {
          data: certificateBase64Encoded
          password: certificatePassword
        }
      }
    ]
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: agSubnetID
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: agFrontendIPName
        properties: {
          publicIPAddress: {
            id: agPublicIPAddressID
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: agFrontendPortName
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: agBackendAddressPoolName
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: agBackendHttpSettingsName
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Enabled'
          requestTimeout: 120
        }
      }
    ]
    httpListeners: [
      {
        name: agHttpListenerName
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationgateways/frontendIPConfigurations', agName_var, agFrontendIPName)
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationgateways/frontendPorts', agName_var, agFrontendPortName)
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationgateways/sslCertificates', agName_var, agSslCertName)
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationgateways/httpListeners', agName_var, agHttpListenerName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationgateways/backendAddressPools', agName_var, agBackendAddressPoolName)
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationgateways/backendHttpSettingsCollection', agName_var, agBackendHttpSettingsName)
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource sqlserverName 'Microsoft.Sql/servers@2018-06-01-preview' = if (databaseNewOrExisting == 'new') {
  name: sqlserverName_var
  location: location
  tags: {
    displayName: 'SqlServer'
  }
  properties: {
    administratorLogin: databaseLogin
    administratorLoginPassword: databaseLoginPassword
    version: '12.0'
  }
  dependsOn: [
    loadBalancerName
    virtualNetworkName
  ]
}

resource sqlserverName_databaseName 'Microsoft.Sql/servers/databases@2018-06-01-preview' = if (databaseNewOrExisting == 'new') {
  parent: sqlserverName
  name: '${databaseName}'
  location: location
  tags: {
    displayName: 'Database'
  }
  properties: {
    edition: edition
    collation: collation
    maxSizeBytes: maxSizeBytes
    requestedServiceObjectiveName: requestedServiceObjectiveName
  }
}

resource sqlserverName_AllowAllIps 'Microsoft.Sql/servers/firewallRules@2018-06-01-preview' = if (databaseNewOrExisting == 'new') {
  parent: sqlserverName
  location: location
  name: 'AllowAllIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

output dbServerName string = (isNewDatabase ? reference(sqlserverName_var).fullyQualifiedDomainName : databaseServerName)
output dbName string = databaseName
output lbFqdn string = 'https://${reference(agPublicIPAddressName_var).dnsSettings.fqdn}'
output dbrdpAddress string = '${reference(dbpublicIPAddressName_var).dnsSettings.fqdn}:50000'
output rdpAddress string = '${reference(publicIPAddressName_var).dnsSettings.fqdn}:50000'