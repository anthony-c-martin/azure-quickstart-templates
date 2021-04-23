@description('User name for the Virtual Machine')
param adminUsername string

@allowed([
  'password'
  'sshPublicKey'
])
@description('Type of authentication to use on the Virtual Machine')
param authenticationType string = 'password'

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

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/jboss-eap-clustered-multivm-rhel/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
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
@description('The size of the Virtual Machine')
param vmSize string = 'Standard_DS2_v2'

@description('Number of VMs to deploy')
param numberOfInstances int = 2

var containerName = 'eapblobcontainer'
var loadBalancersName_var = 'jbosseap-lb'
var vmNameMap = {
  BYOS: 'jbosseap-byos-server'
  PAYG: 'jbosseap-payg-server'
}
var vmName_var = vmNameMap[rhelOSLicenseType]
var asName_var = 'jbosseap-as'
var skuName = 'Aligned'
var nicName_var = 'jbosseap-server-nic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'jbosseap-server-subnet'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName_var = 'jbosseap-vnet'
var backendPoolName = 'jbosseap-server'
var frontendName = 'LoadBalancerFrontEnd'
var healthProbeEAP = 'eap-jboss-health'
var healthProbeAdmin = 'eap-admin-health'
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
  'JBoss-EAP7.2-on-RHEL7.7': 'pid-9c48eb09-c7f5-4cc1-9ee5-033abb031ff0'
  'JBoss-EAP7.2-on-RHEL8.0': 'pid-d269e266-aa09-4080-b4af-84d641b0b81c'
  'JBoss-EAP7.3-on-RHEL8.0': 'pid-43604955-685a-4680-bfb0-5bf4ced404c0'
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
    QuickstartName: 'JBoss EAP on RHEL (clustered, multi-VM)'
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: virtualNetworkName_var
  location: location
  tags: {
    QuickstartName: 'JBoss EAP on RHEL (clustered, multi-VM)'
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

resource nicName 'Microsoft.Network/networkInterfaces@2019-11-01' = [for i in range(0, numberOfInstances): {
  name: concat(nicName_var, i)
  location: location
  tags: {
    QuickstartName: 'JBoss EAP on RHEL (clustered, multi-VM)'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
          }
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancersName_var, backendPoolName)
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
    loadBalancersName
  ]
}]

resource vmName 'Microsoft.Compute/virtualMachines@2019-12-01' = [for i in range(0, numberOfInstances): {
  name: concat(vmName_var, i)
  location: location
  plan: ((rhelOSLicenseType == 'PAYG') ? json('null') : plan)
  tags: {
    QuickstartName: 'JBoss EAP on RHEL (clustered, multi-VM)'
  }
  properties: {
    availabilitySet: {
      id: asName.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(nicName_var, i))
        }
      ]
    }
    osProfile: {
      computerName: concat(vmName_var, i)
      adminUsername: adminUsername
      adminPassword: adminPasswordOrSSHKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
      }
      imageReference: imageReference
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(bootStorageAccountName_var, '2019-06-01').primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    nicName
    storageAccountName
    asName
    bootStorageAccountName
  ]
}]

resource vmName_jbosseap_setup_extension 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = [for i in range(0, numberOfInstances): {
  name: '${vmName_var}${i}/jbosseap-setup-extension-${i}'
  location: location
  tags: {
    QuickstartName: 'JBoss EAP on RHEL (clustered, multi-VM)'
  }
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
      commandToExecute: 'sh jbosseap-setup-redhat.sh ${scriptArgs} ${jbossEAPUserName} \'${jbossEAPPassword}\' ${rhelOSLicenseType} ${rhsmUserName} \'${rhsmPassword}\' ${rhsmPoolEAP} ${storageAccountName_var} ${containerName} ${base64(listKeys(storageAccountName.id, '2019-04-01').keys[0].value)} ${eapOnRHELVersion} ${rhsmPoolRHEL}'
    }
  }
  dependsOn: [
    resourceId('Microsoft.Compute/virtualMachines', concat(vmName_var, i))
  ]
}]

resource loadBalancersName 'Microsoft.Network/loadBalancers@2019-11-01' = {
  name: loadBalancersName_var
  location: location
  sku: {
    name: 'Basic'
  }
  tags: {
    QuickstartName: 'JBoss EAP on RHEL (clustered, multi-VM)'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: frontendName
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendPoolName
      }
    ]
    loadBalancingRules: [
      {
        name: '${loadBalancersName_var}-rule1'
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
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancersName_var, healthProbeEAP)
          }
        }
      }
      {
        name: '${loadBalancersName_var}-rule2'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancersName_var, frontendName)
          }
          frontendPort: 9990
          backendPort: 9990
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          protocol: 'Tcp'
          enableTcpReset: false
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancersName_var, backendPoolName)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancersName_var, healthProbeAdmin)
          }
        }
      }
    ]
    probes: [
      {
        name: healthProbeEAP
        properties: {
          protocol: 'Tcp'
          port: 8080
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
      {
        name: healthProbeAdmin
        properties: {
          protocol: 'Tcp'
          port: 9990
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

resource asName 'Microsoft.Compute/availabilitySets@2019-03-01' = {
  name: asName_var
  location: location
  sku: {
    name: skuName
  }
  tags: {
    QuickstartName: 'JBoss EAP on RHEL (clustered, multi-VM)'
  }
  properties: {
    platformUpdateDomainCount: 2
    platformFaultDomainCount: 2
  }
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: storageReplication
  }
  kind: 'Storage'
  tags: {
    QuickstartName: 'JBoss EAP on RHEL (clustered, multi-VM)'
  }
}

resource storageAccountName_default_containerName 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = {
  name: '${storageAccountName_var}/default/${containerName}'
  dependsOn: [
    storageAccountName
  ]
}

output appURL string = 'http://${reference(loadBalancersName_var).frontendIPConfigurations[0].properties.privateIPAddress}/eap-session-replication/'