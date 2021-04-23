@description('Linux VM user account name')
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

@allowed([
  'JBoss-EAP7.2-on-RHEL7.7'
  'JBoss-EAP7.2-on-RHEL8.0'
  'JBoss-EAP7.3-on-RHEL8.0'
])
@description('Version of EAP on RHEL')
param eapOnRHELVersion string = 'JBoss-EAP7.2-on-RHEL8.0'

@description('User name for JBoss EAP Manager')
param jbossEAPUserName string

@minLength(12)
@description('Password for JBoss EAP Manager')
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

@description('Password for Red Hat subscription  Manager')
@secure()
param rhsmPassword string

@description('Red Hat Subscription Manager Pool ID (Should have EAP entitlement)')
param rhsmPoolEAP string

@description('Red Hat Subscription Manager Pool ID (Should have RHEL entitlement). Mandartory if you select the BYOS RHEL OS License Type')
param rhsmPoolRHEL string = ''

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/jboss-eap-standalone-rhel/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources')
param location string = resourceGroup().location

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

var nicName_var = 'jbosseap-server-nic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'jbosseap-server-subnet'
var subnetPrefix = '10.0.0.0/24'
var vmNameMap = {
  BYOS: 'jbosseap-byos-server'
  PAYG: 'jbosseap-payg-server'
}
var vmName_var = vmNameMap[rhelOSLicenseType]
var virtualNetworkName_var = 'jbosseap-vnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
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
  'JBoss-EAP7.2-on-RHEL7.7': 'pid-9a72dd7b-3568-469b-a84f-d953207f2a1a'
  'JBoss-EAP7.2-on-RHEL8.0': 'pid-cf1bb11d-01b8-449d-9052-aae316c75698'
  'JBoss-EAP7.3-on-RHEL8.0': 'pid-32c5d1f7-1ff7-43fc-a113-a64831e5e32e'
}
var guid_var = guidMap[eapOnRHELVersion]
var scriptFolder = 'scripts'
var fileToBeDownloaded = 'JBoss-EAP_on_Azure.war'
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
    QuickstartName: 'JBoss EAP on RHEL (stand-alone VM)'
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: virtualNetworkName_var
  location: location
  tags: {
    QuickstartName: 'JBoss EAP on RHEL (stand-alone VM)'
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

resource nicName 'Microsoft.Network/networkInterfaces@2019-11-01' = {
  name: nicName_var
  location: location
  tags: {
    QuickstartName: 'JBoss EAP on RHEL (stand-alone VM)'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName_var
  location: location
  plan: ((rhelOSLicenseType == 'PAYG') ? json('null') : plan)
  tags: {
    QuickstartName: 'JBoss EAP on RHEL (stand-alone VM)'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      adminPassword: adminPasswordOrSSHKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      osDisk: {
        name: '${vmName_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      imageReference: imageReference
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
        enabled: true
        storageUri: reference(bootStorageAccountName_var, '2019-06-01').primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    bootStorageAccountName
  ]
}

resource vmName_jbosseap_setup_extension 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  parent: vmName
  name: 'jbosseap-setup-extension'
  location: location
  tags: {
    QuickstartName: 'JBoss EAP on RHEL (stand-alone VM)'
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
      commandToExecute: 'sh jbosseap-setup-redhat.sh ${scriptArgs} ${jbossEAPUserName} \'${jbossEAPPassword}\' ${rhsmUserName} \'${rhsmPassword}\' ${rhelOSLicenseType} ${rhsmPoolEAP} ${eapOnRHELVersion} ${rhsmPoolRHEL}'
    }
  }
}

output vm_Private_IP_Address string = reference(nicName_var).ipConfigurations[0].properties.privateIPAddress
output appURL string = 'http://${reference(nicName_var).ipConfigurations[0].properties.privateIPAddress}:8080/JBoss-EAP_on_Azure/'
output adminConsole string = 'http://${reference(nicName_var).ipConfigurations[0].properties.privateIPAddress}:9990'