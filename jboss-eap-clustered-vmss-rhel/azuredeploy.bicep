@description('User name for the Virtual Machine')
param adminUsername string

@allowed([
  'password'
  'sshPublicKey'
])
@description('Type of authentication to use on the Virtual Machine')
param authenticationType string = 'password'

@minLength(12)
@description('Password or SSH key for the Virtual Machine')
@secure()
param adminPasswordOrSSHKey string

@description('Location for all resources')
param location string = resourceGroup().location

@allowed([
  'JBoss-EAP7.2-on-RHEL7.7'
  'JBoss-EAP7.2-on-RHEL8.0'
  'JBoss-EAP7.3-on-RHEL8.0'
])
@description('Version of EAP on RHEL')
param eapOnRHELVersion string = 'JBoss-EAP7.2-on-RHEL8.0'

@description('User name for the JBoss EAP Manager')
param jbossEAPUserName string

@minLength(12)
@description('Password for the JBoss EAP Manager')
@secure()
param jbossEAPPassword string

@allowed([
  'PAYG'
  'BYOS'
])
@description('Select the of RHEL OS License Type for deploying your Virtual Machine. Please read through the guide and make sure you follow the steps mentioned under section \'Licenses, Subscriptions and Costs\' if you are selecting BYOS')
param rhelOSLicenseType string = 'PAYG'

@description('User name for Red Hat subscription Manager')
param rhsmUserName string

@description('Password for Red Hat subscription Manager')
@secure()
param rhsmPassword string

@description('Red Hat Subscription Manager Pool ID (Should have EAP entitlement)')
param rhsmPoolEAP string

@description('Red Hat Subscription Manager Pool ID (Should have RHEL entitlement). Mandartory if you select the BYOS RHEL OS License Type')
param rhsmPoolRHEL string = ''

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/jboss-eap-clustered-vmss-rhel/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated')
@secure()
param artifactsLocationSasToken string = ''

@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Premium_LRS'
])
@description('Select the Replication Strategy for the Storage account')
param storageReplication string = 'Standard_LRS'

@maxLength(9)
@description('String used as a base for naming resources (9 characters or less). A hash is prepended to this string for some resources, and resource-specific information is appended')
param vmssName string

@minValue(2)
@maxValue(100)
@description('Number of VM instances (100 or less)')
param instanceCount int = 2

@allowed([
  'Standard_DS2_v2'
  'Standard_DS3_v2'
  'Standard_DS4_v2'
  'Standard_E2S_v3'
  'Standard_E4S_v3'
  'Standard_E8S_v3'
  'Standard_F2S_v2'
  'Standard_F4S_v2'
  'Standard_F8S_v2'
])
@description('The size of the Virtual Machine scale set')
param vmSize string = 'Standard_DS2_v2'

var containerName = 'eapblobcontainer'
var loadBalancersName_var = 'jbosseap-lb'
var vmssInstanceName_var = 'jbosseap-server${vmssName}'
var nicName = 'jbosseap-server-nic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'jbosseap-server-subnet'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName_var = 'jbosseap-vnet'
var backendPoolName = 'jbosseap-server'
var frontendName = 'LoadBalancerFrontEnd'
var natRuleName = 'adminconsolerule'
var natStartPort = 9000
var natEndPort = 9120
var adminBackendPort = 9990
var healthProbe = 'eap-lb-health'
var bootStorageAccountName_var = 'bootstrg${uniqueString(resourceGroup().id)}'
var storageAccountType = 'Standard_LRS'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrSSHKey
      }
    ]
  }
}
var skuMap = {
  BYOS: {
    'JBoss-EAP7.2-on-RHEL7.7': 'rhel-lvm77'
    'JBoss-EAP7.2-on-RHEL8.0': 'rhel-lvm8'
    'JBoss-EAP7.3-on-RHEL8.0': 'rhel-lvm8'
  }
  PAYG: {
    'JBoss-EAP7.2-on-RHEL7.7': '7.7'
    'JBoss-EAP7.2-on-RHEL8.0': '8'
    'JBoss-EAP7.3-on-RHEL8.0': '8'
  }
}
var imageSku = skuMap[rhelOSLicenseType][eapOnRHELVersion]
var offerMap = {
  BYOS: 'rhel-byos'
  PAYG: 'rhel'
}
var imageOffer = offerMap[rhelOSLicenseType]
var imageReference = {
  publisher: 'redhat'
  offer: imageOffer
  sku: imageSku
  version: 'latest'
}
var plan = {
  name: imageSku
  publisher: 'redhat'
  product: 'rhel-byos'
}
var guidMap = {
  'JBoss-EAP7.2-on-RHEL7.7': 'pid-92abde63-f331-4e50-96ca-e0e5c2339caa'
  'JBoss-EAP7.2-on-RHEL8.0': 'pid-4d9c78a6-451b-467d-a6da-d86c71c4a6c7'
  'JBoss-EAP7.3-on-RHEL8.0': 'pid-8c47eaba-ad48-4d3b-b2f8-9f69a44b57f5'
}
var guid_var = guidMap[eapOnRHELVersion]
var storageAccountName_var = 'jbosstrg${uniqueString(resourceGroup().id)}'
var scriptFolder = 'scripts'
var fileToBeDownloaded = 'eap-session-replication.war'
var scriptArgs = '-a ${uri(artifactsLocation, '.')} -t "${artifactsLocationSasToken}" -p ${scriptFolder} -f ${fileToBeDownloaded}'

module guid './nested_guid.bicep' = {
  name: guid_var
  params: {}
}

resource bootStorageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: bootStorageAccountName_var
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  tags: {
    QuickstartName: 'JBoss EAP on RHEL (clustered, VMSS)'
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: virtualNetworkName_var
  location: location
  tags: {
    QuickstartName: 'JBoss EAP on RHEL (clustered, VMSS)'
  }
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

resource vmssInstanceName 'Microsoft.Compute/virtualMachineScaleSets@2019-07-01' = {
  name: vmssInstanceName_var
  location: location
  sku: {
    name: vmSize
    tier: 'Standard'
    capacity: instanceCount
  }
  plan: ((rhelOSLicenseType == 'PAYG') ? json('null') : plan)
  tags: {
    QuickstartName: 'JBoss EAP on RHEL (clustered, VMSS)'
  }
  properties: {
    overprovision: 'false'
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
        }
        imageReference: imageReference
      }
      osProfile: {
        computerNamePrefix: vmssInstanceName_var
        adminUsername: adminUsername
        adminPassword: adminPasswordOrSSHKey
        linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: nicName
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig'
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancersName_var, backendPoolName)
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', loadBalancersName_var, natRuleName)
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
          storageUri: reference(bootStorageAccountName_var, '2019-06-01').primaryEndpoints.blob
        }
      }
      extensionProfile: {
        extensions: [
          {
            name: 'jbosseap-setup-extension'
            properties: {
              publisher: 'Microsoft.Azure.Extensions'
              type: 'CustomScript'
              typeHandlerVersion: '2.0'
              autoUpgradeMinorVersion: true
              settings: {
                fileUris: [
                  uri(artifactsLocation, 'scripts/jbosseap-setup-redhat.sh${artifactsLocationSasToken}')
                ]
              }
              protectedSettings: {
                commandToExecute: 'sh jbosseap-setup-redhat.sh ${scriptArgs} ${jbossEAPUserName} \'${jbossEAPPassword}\' ${rhsmUserName} \'${rhsmPassword}\' ${rhelOSLicenseType} ${rhsmPoolEAP} ${storageAccountName_var} ${containerName} ${base64(listKeys(storageAccountName.id, '2019-04-01').keys[0].value)} ${eapOnRHELVersion} ${rhsmPoolRHEL}'
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    loadBalancersName
    virtualNetworkName

    bootStorageAccountName
  ]
}

resource loadBalancersName 'Microsoft.Network/loadBalancers@2019-11-01' = {
  name: loadBalancersName_var
  location: location
  sku: {
    name: 'Basic'
  }
  tags: {
    QuickstartName: 'JBoss EAP on RHEL (clustered, VMSS)'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: frontendName
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
          }
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendPoolName
      }
    ]
    inboundNatPools: [
      {
        name: natRuleName
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancersName_var, frontendName)
          }
          protocol: 'Tcp'
          frontendPortRangeStart: natStartPort
          frontendPortRangeEnd: natEndPort
          backendPort: adminBackendPort
        }
      }
    ]
    loadBalancingRules: [
      {
        name: '${loadBalancersName_var}-rule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancersName_var, frontendName)
          }
          frontendPort: 80
          backendPort: 8080
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          protocol: 'Tcp'
          enableTcpReset: false
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancersName_var, backendPoolName)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancersName_var, healthProbe)
          }
        }
      }
    ]
    probes: [
      {
        name: healthProbe
        properties: {
          protocol: 'Tcp'
          port: 8080
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: storageReplication
  }
  kind: 'Storage'
  tags: {
    QuickstartName: 'JBoss EAP on RHEL (clustered, VMSS)'
  }
}

resource storageAccountName_default_containerName 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = {
  name: '${storageAccountName_var}/default/${containerName}'
  dependsOn: [
    storageAccountName
  ]
}

output appURL string = 'http://${reference(loadBalancersName_var).frontendIPConfigurations[0].properties.privateIPAddress}/eap-session-replication/'