@allowed([
  'Standard_LRS'
  'Premium_LRS'
])
@description('Set this value for the storage account type')
param appStorageType string = 'Standard_LRS'

@minLength(1)
@description('Set this value for the frontend vmss name')
param frontEndVMSSName string

@minLength(1)
@description('Set this value for the backend or service vmss name')
param serviceVMSSName string

@minLength(1)
@description('Set this value for the admin user name to the vmss')
param appVMAdminUserName string

@description('Set this value for the password for the admin user to the vmss')
@secure()
param appVMAdminPassword string

@allowed([
  '2008-R2-SP1'
  '2012-Datacenter'
  '2012-R2-Datacenter'
  'Windows-Server-Technical-Preview'
])
@description('Set this value for the windows os version')
param appVMWindowsOSVersion string = '2012-R2-Datacenter'

@allowed([
  'Standard_D1'
  'Standard_D2'
  'Standard_D3'
  'Standard_D4'
  'Standard_D11'
  'Standard_D12'
  'Standard_D13'
  'Standard_D14'
  'Standard_DS1_V2'
  'Standard_DS2_V2'
  'Standard_DS3_V2'
  'Standard_DS4_V2'
  'Standard_DS5_V2'
  'Standard_DS11_V2'
  'Standard_DS12_V2'
  'Standard_DS13_V2'
  'Standard_DS14_V2'
  'Standard_DS15_V2'
])
@description('Set this value for the frontend vmss size')
param frontEndVMSize string = 'Standard_DS4_V2'

@allowed([
  'Standard_D1'
  'Standard_D2'
  'Standard_D3'
  'Standard_D4'
  'Standard_D11'
  'Standard_D12'
  'Standard_D13'
  'Standard_D14'
  'Standard_DS1_V2'
  'Standard_DS2_V2'
  'Standard_DS3_V2'
  'Standard_DS4_V2'
  'Standard_DS5_V2'
  'Standard_DS11_V2'
  'Standard_DS12_V2'
  'Standard_DS13_V2'
  'Standard_DS14_V2'
  'Standard_DS15_V2'
])
@description('Set this value for the service or backend vmss size')
param serviceVMSize string = 'Standard_DS4_V2'

@minLength(1)
@description('Set this value for the dns name of the frontend public ip')
param appPublicIPDnsName string

@minLength(1)
@description('Set this value for the dns name of the backend public ip')
param servicePublicIPDnsName string

@description('Auto-generated container in staging storage account to receive post-build staging folder upload')
param artifactsLocation string

@description('Auto-generated token to access _artifactsLocation')
@secure()
param artifactsLocationSasToken string

@description('This value must be changed from a previous deployment to ensure the extension will run')
param appDSCUpdateTagVersion string = '1.0'

@description('Set this value for the signed uri to download the frontend deployment package')
param appWebPackage string = 'https://computeteststore.blob.core.windows.net/deploypackage/deployPackage.zip?sv=2015-04-05&ss=bfqt&srt=sco&sp=r&se=2099-10-16T02:03:39Z&st=2016-10-15T18:03:39Z&spr=https&sig=aSH6yNPEGPWXk6PxTPzS6fyEXMD1ZYIkI0j5E9Hu5%2Fk%3D'

@description('Set this value for the signed uri to download the service deployment package')
param appServicePackage string = 'https://computeteststore.blob.core.windows.net/deploypackage/SampleWcfServices.zip?sv=2015-04-05&ss=bfqt&srt=sco&sp=r&se=2099-10-16T02:03:39Z&st=2016-10-15T18:03:39Z&spr=https&sig=aSH6yNPEGPWXk6PxTPzS6fyEXMD1ZYIkI0j5E9Hu5%2Fk%3D'

@description('Number of VM instances in the vmss')
param instanceCount string

@description('This value must be changed from a previous deployment to ensure the extension will run')
param frontEndDSCVMSSUpdateTagVersion string = '1.0'

@description('This value must be changed from a previous deployment to ensure the extension will run')
param serviceDSCVMSSUpdateTagVersion string = '1.0'

@description('The Azure Key vault where SSL certificates are stored')
param vaultName string

@description('Resource Group of the key vault')
param vaultResourceGroup string

@description('full Key Vault Id to the secret that stores the SSL cert')
param httpssecretUrlWithVersion string

@description('full Key Vault Id to the secret that stores the CA cert')
param httpssecretCaUrlWithVersion string

@description('name of the certificate key secret')
param certificateStore string

@description('name of the domain the certificate is created for')
param certificateDomain string

@description('Location for all resources.')
param location string = resourceGroup().location

var appVnetPrefix = '10.0.0.0/16'
var appVnetSubnet1Name = 'FrontEndSubNet'
var appVnetSubnet1Prefix = '10.0.0.0/24'
var appVnetSubnet2Name = 'ServiceSubNet'
var appVnetSubnet2Prefix = '10.0.1.0/24'
var appVMImagePublisher = 'MicrosoftWindowsServer'
var appVMImageOffer = 'WindowsServer'
var frontEndVMSize_var = frontEndVMSize
var serviceVMSize_var = serviceVMSize
var appVMSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', appVnetSubnet1Name)
var serviceVMSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', appVnetSubnet1Name)
var appPublicIPName_var = 'appPublicIP'
var servicePublicIPName_var = 'servicePublicIP'
var frontEndVMSSName_var = frontEndVMSSName
var serviceVMSSName_var = serviceVMSSName
var publicIPAddressID = appPublicIPName.id
var publicIPAddressID2 = servicePublicIPName.id
var lbName_var = 'loadBalancer1'
var lbServiceName_var = 'loadBalancer2'
var lbID = lbName.id
var lbServiceID = lbServiceName.id
var lbFEName = 'loadBalancerFrontEndWeb'
var lbFEServiceName = 'loadBalancerFrontEndService'
var lbWebProbeName = 'loadBalancerWebProbe'
var lbWebServiceProbeName = 'loadBalancerWebServiceProbe'
var lbBEAddressPool = 'loadBalancerBEAddressPool'
var lbBEServiceAddressPool = 'loadBalancerBEServiceAddressPool'
var lbFEIPConfigID = '${lbID}/frontendIPConfigurations/${lbFEName}'
var lbFEServiceIPConfigID = '${lbServiceID}/frontendIPConfigurations/${lbFEServiceName}'
var lbBEAddressPoolID = '${lbID}/backendAddressPools/${lbBEAddressPool}'
var lbBEServiceAddressPoolID = '${lbServiceID}/backendAddressPools/${lbBEServiceAddressPool}'
var lbWebServiceProbeID = '${lbServiceID}/probes/${lbWebServiceProbeName}'
var frontEndDSCVMSSArchiveFolder = 'dsc'
var frontEndDSCVMSSArchiveFileName = 'frontEndDSCVMSS.zip'
var serviceDSCVMSSArchiveFolder = 'dsc'
var serviceDSCVMSSArchiveFileName = 'serviceDSCVMSS.zip'
var natPoolNameFrontEnd = 'natpoolfe'
var natStartPortFrontEnd = 50000
var natEndPortFrontEnd = 50119
var natBackendPortFrontEnd = 3389
var natPoolNameService = 'natpoolsvc'
var natStartPortService = 51000
var natEndPortService = 51119
var natBackendPortService = 3389
var frontEndIPConfigIDWeb = '${lbID}/frontendIPConfigurations/${lbFEName}'
var frontEndIPConfigIDService = '${lbServiceID}/frontendIPConfigurations/${lbFEServiceName}'
var lbWebInboundNatPoolId = '${lbID}/inboundNatPools/${natPoolNameFrontEnd}'
var lbServiceInboundNatPoolId = '${lbServiceID}/inboundNatPools/${natPoolNameService}'
var wadProcessorMetricName2 = 'Percentage CPU'
var wadProcessorMetricName3 = 'Percentage CPU'
var lbWebHttpsProbeName = 'loadBalancerWebHttpsProbe'
var lbWebHttpsProbeID = '${lbID}/probes/${lbWebHttpsProbeName}'

resource lbName 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: lbName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: lbFEName
        properties: {
          publicIPAddress: {
            id: publicIPAddressID
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: lbBEAddressPool
      }
    ]
    loadBalancingRules: [
      {
        name: 'weblb'
        properties: {
          backendAddressPool: {
            id: lbBEAddressPoolID
          }
          backendPort: 80
          enableFloatingIP: false
          frontendIPConfiguration: {
            id: lbFEIPConfigID
          }
          frontendPort: 80
          probe: {
            id: lbWebHttpsProbeID
          }
          protocol: 'Tcp'
          loadDistribution: 'SourceIP'
        }
      }
      {
        name: 'webhttpslb'
        properties: {
          backendAddressPool: {
            id: lbBEAddressPoolID
          }
          backendPort: 443
          enableFloatingIP: false
          frontendIPConfiguration: {
            id: lbFEIPConfigID
          }
          frontendPort: 443
          probe: {
            id: lbWebHttpsProbeID
          }
          protocol: 'Tcp'
          loadDistribution: 'SourceIP'
        }
      }
    ]
    probes: [
      {
        name: lbWebProbeName
        properties: {
          protocol: 'Http'
          port: 80
          intervalInSeconds: 15
          numberOfProbes: 5
          requestPath: 'hostingstart.html'
        }
      }
      {
        name: lbWebHttpsProbeName
        properties: {
          protocol: 'Tcp'
          port: 443
          intervalInSeconds: 15
          numberOfProbes: 5
        }
      }
    ]
    inboundNatPools: [
      {
        name: natPoolNameFrontEnd
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigIDWeb
          }
          protocol: 'Tcp'
          frontendPortRangeStart: natStartPortFrontEnd
          frontendPortRangeEnd: natEndPortFrontEnd
          backendPort: natBackendPortFrontEnd
        }
      }
    ]
  }
}

resource lbServiceName 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: lbServiceName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: lbFEServiceName
        properties: {
          publicIPAddress: {
            id: publicIPAddressID2
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: lbBEServiceAddressPool
      }
    ]
    loadBalancingRules: [
      {
        name: 'wcflb'
        properties: {
          backendAddressPool: {
            id: lbBEServiceAddressPoolID
          }
          backendPort: 80
          enableFloatingIP: false
          frontendIPConfiguration: {
            id: lbFEServiceIPConfigID
          }
          frontendPort: 80
          probe: {
            id: lbWebServiceProbeID
          }
          protocol: 'Tcp'
          loadDistribution: 'Default'
        }
      }
    ]
    probes: [
      {
        name: lbWebServiceProbeName
        properties: {
          protocol: 'Http'
          port: 80
          intervalInSeconds: 15
          numberOfProbes: 5
          requestPath: 'hostingstart.html'
        }
      }
    ]
    inboundNatPools: [
      {
        name: natPoolNameService
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigIDService
          }
          protocol: 'Tcp'
          frontendPortRangeStart: natStartPortService
          frontendPortRangeEnd: natEndPortService
          backendPort: natBackendPortService
        }
      }
    ]
  }
}

resource frontEndVMSSName_resource 'Microsoft.Compute/virtualMachineScaleSets@2016-04-30-preview' = {
  name: frontEndVMSSName_var
  location: location
  tags: {
    vmsstag1: 'Rev VMSS FE'
  }
  sku: {
    name: frontEndVMSize_var
    tier: 'Standard'
    capacity: instanceCount
  }
  properties: {
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          caching: 'ReadWrite'
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: appStorageType
          }
        }
        imageReference: {
          publisher: appVMImagePublisher
          offer: appVMImageOffer
          sku: appVMWindowsOSVersion
          version: 'latest'
        }
      }
      osProfile: {
        computerNamePrefix: frontEndVMSSName_var
        adminUsername: appVMAdminUserName
        adminPassword: appVMAdminPassword
        secrets: [
          {
            sourceVault: {
              id: resourceId(vaultResourceGroup, 'Microsoft.KeyVault/vaults', vaultName)
            }
            vaultCertificates: [
              {
                certificateUrl: httpssecretUrlWithVersion
                certificateStore: certificateStore
              }
            ]
          }
        ]
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic1'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ip1'
                  properties: {
                    subnet: {
                      id: appVMSubnetRef
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: lbBEAddressPoolID
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: lbWebInboundNatPoolId
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
            name: 'Microsoft.Powershell.DSC'
            properties: {
              publisher: 'Microsoft.Powershell'
              type: 'DSC'
              typeHandlerVersion: '2.9'
              autoUpgradeMinorVersion: true
              forceUpdateTag: frontEndDSCVMSSUpdateTagVersion
              settings: {
                configuration: {
                  url: '${artifactsLocation}/${frontEndDSCVMSSArchiveFolder}/${frontEndDSCVMSSArchiveFileName}'
                  script: 'frontEndDSCVMSS.ps1'
                  function: 'Main'
                }
                configurationArguments: {
                  nodeName: 'localhost'
                  webDeployPackage: appWebPackage
                  certStoreName: certificateStore
                  certDomain: certificateDomain
                }
              }
              protectedSettings: {
                configurationUrlSasToken: artifactsLocationSasToken
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    appVnet
  ]
}

resource serviceVMSSName_resource 'Microsoft.Compute/virtualMachineScaleSets@2016-04-30-preview' = {
  name: serviceVMSSName_var
  location: location
  tags: {
    vmsstag1: 'rev Service'
  }
  sku: {
    name: serviceVMSize_var
    tier: 'Standard'
    capacity: instanceCount
  }
  properties: {
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          caching: 'ReadWrite'
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: appStorageType
          }
        }
        imageReference: {
          publisher: appVMImagePublisher
          offer: appVMImageOffer
          sku: appVMWindowsOSVersion
          version: 'latest'
        }
      }
      osProfile: {
        computerNamePrefix: serviceVMSSName_var
        adminUsername: appVMAdminUserName
        adminPassword: appVMAdminPassword
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nics1'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ips1'
                  properties: {
                    subnet: {
                      id: serviceVMSubnetRef
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: lbBEServiceAddressPoolID
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: lbServiceInboundNatPoolId
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
            name: 'Microsoft.Powershell.DSC'
            properties: {
              publisher: 'Microsoft.Powershell'
              type: 'DSC'
              typeHandlerVersion: '2.9'
              autoUpgradeMinorVersion: true
              forceUpdateTag: serviceDSCVMSSUpdateTagVersion
              settings: {
                configuration: {
                  url: '${artifactsLocation}/${serviceDSCVMSSArchiveFolder}/${serviceDSCVMSSArchiveFileName}'
                  script: 'serviceDSCVMSS.ps1'
                  function: 'Main'
                }
                configurationArguments: {
                  nodeName: 'localhost'
                  webDeployPackage: appServicePackage
                }
              }
              protectedSettings: {
                configurationUrlSasToken: artifactsLocationSasToken
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    appVnet
  ]
}

resource appNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: 'appNetworkSecurityGroup'
  location: location
  properties: {
    securityRules: [
      {
        name: 'webrule'
        properties: {
          description: 'This rule allows traffic in on port 80'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'INTERNET'
          destinationAddressPrefix: appVnetSubnet1Prefix
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'webHttpsRule'
        properties: {
          description: 'This rule allows traffic in on port 443'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'INTERNET'
          destinationAddressPrefix: appVnetSubnet1Prefix
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'rdprule'
        properties: {
          description: 'This rule allows traffic on port 3389 from the web'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: 'INTERNET'
          destinationAddressPrefix: appVnetSubnet1Prefix
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource appVnet 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: 'appVnet'
  location: location
  tags: {
    displayName: 'appVnet'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        appVnetPrefix
      ]
    }
    subnets: [
      {
        name: appVnetSubnet1Name
        properties: {
          addressPrefix: appVnetSubnet1Prefix
          networkSecurityGroup: {
            id: appNetworkSecurityGroup.id
          }
        }
      }
      {
        name: appVnetSubnet2Name
        properties: {
          addressPrefix: appVnetSubnet2Prefix
          networkSecurityGroup: {
            id: appNetworkSecurityGroup.id
          }
        }
      }
    ]
  }
}

resource appPublicIPName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: appPublicIPName_var
  location: location
  tags: {
    displayName: 'appPublicIP'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: appPublicIPDnsName
    }
  }
  dependsOn: []
}

resource servicePublicIPName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: servicePublicIPName_var
  location: location
  tags: {
    displayName: 'servicePublicIP'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: servicePublicIPDnsName
    }
  }
  dependsOn: []
}

resource frontEndVMSSName_autoscale 'Microsoft.Insights/autoscaleSettings@2015-04-01' = {
  location: location
  name: '${frontEndVMSSName_var}autoscale'
  properties: {
    name: '${frontEndVMSSName_var}autoscale'
    targetResourceUri: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Compute/virtualMachineScaleSets/${frontEndVMSSName_var}'
    enabled: true
    profiles: [
      {
        name: 'Profile1'
        capacity: {
          default: '2'
          maximum: '10'
          minimum: '2'
        }
        rules: [
          {
            metricTrigger: {
              metricName: wadProcessorMetricName2
              metricNamespace: ''
              metricResourceUri: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Compute/virtualMachineScaleSets/${frontEndVMSSName_var}'
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 50
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: wadProcessorMetricName2
              metricNamespace: ''
              metricResourceUri: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Compute/virtualMachineScaleSets/${frontEndVMSSName_var}'
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT1M'
            }
          }
        ]
      }
    ]
  }
  tags: {
    displayName: '${frontEndVMSSName_var}autoscale'
  }
  dependsOn: [
    frontEndVMSSName_resource
  ]
}

resource serviceVMSSName_autoscale 'Microsoft.Insights/autoscaleSettings@2015-04-01' = {
  name: '${serviceVMSSName_var}autoscale'
  location: location
  tags: {
    displayName: '${serviceVMSSName_var}autoscale'
  }
  properties: {
    name: '${serviceVMSSName_var}autoscale'
    targetResourceUri: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Compute/virtualMachineScaleSets/${serviceVMSSName_var}'
    enabled: true
    profiles: [
      {
        name: 'Profile1'
        capacity: {
          minimum: '2'
          maximum: '10'
          default: '2'
        }
        rules: [
          {
            metricTrigger: {
              metricName: wadProcessorMetricName3
              metricNamespace: ''
              metricResourceUri: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Compute/virtualMachineScaleSets/${serviceVMSSName_var}'
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 50
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: wadProcessorMetricName3
              metricNamespace: ''
              metricResourceUri: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Compute/virtualMachineScaleSets/${serviceVMSSName_var}'
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT1M'
            }
          }
        ]
      }
    ]
  }
  dependsOn: [
    serviceVMSSName_resource
  ]
}