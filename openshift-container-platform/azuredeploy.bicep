@description('The base URL where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/openshift-container-platform/'

@description('Token for the base URL where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Region where the resources should be created in')
param location string = resourceGroup().location

@description('Cluster resources prefix')
param clusterName string = 'ocpcluster'

@description('Domain name created with the App Service')
param dnsZone string

@description('Resource Group that contains the domain name')
param dnsZoneRG string

@description('Enable FIPS encryption')
param fipsEnabled bool = true

@allowed([
  'public'
  'private'
])
@description('Public or private facing endpoints')
param privateOrPublicEndpoints string = 'public'

@allowed([
  'new'
  'existing'
])
@description('Deploy in new cluster or in existing cluster. If existing cluster, make sure the new resources are in the same zone')
param newOrExistingNetwork string = 'new'

@description('Resource Group for Existing Vnet.')
param existingVnetResourceGroupName string = resourceGroup().name

@description('Name of new or existing virtual network')
param virtualNetworkName string = 'myVNet'

@description('VNet Address Prefix. Minimum address prefix is /16')
param virtualNetworkCIDR array = [
  '10.0.0.0/16'
]

@description('Name of new or existing master subnet')
param masterSubnetName string = 'masterSubnet'

@description('Master subnet address prefix')
param masterSubnetPrefix string = '10.0.1.0/24'

@description('Name of new or existing worker subnet')
param workerSubnetName string = 'workerSubnet'

@description('Worker subnet address prefix')
param workerSubnetPrefix string = '10.0.2.0/24'

@description('Name of new or existing bastion subnet')
param bastionSubnetName string = 'bastionSubnet'

@description('Worker subnet address prefix')
param bastionSubnetPrefix string = '10.0.3.0/27'

@allowed([
  'az'
  'noha'
])
@description('Deploy to a Single AZ or multiple AZs')
param singleZoneOrMultiZone string = 'az'

@description('Bastion Host VM size. Use VMs with Premium Storage support only.')
param bastionVmSize string = 'Standard_F8s_v2'

@description('OpenShift Master VM size. Use VMs with Premium Storage support only.')
param masterVmSize string = 'Standard_F8s_v2'

@description('OpenShift Node VM(s) size. Use VMs with Premium Storage support only.')
param workerVmSize string = 'Standard_F16s_v2'

@allowed([
  1
  3
  5
])
@description('Number of OpenShift masters.')
param masterInstanceCount int = 3

@allowed([
  3
  4
  5
  6
  7
  8
  9
  10
])
@description('Number of OpenShift nodes')
param workerInstanceCount int = 3

@allowed([
  'portworx'
  'nfs'
])
param storageOption string = 'portworx'

@description('Portworx Spec URL. See README on how to generate the URL')
param pxSpecUrl string = ''

@allowed([
  512
  1024
  2048
])
@description('Size of Datadisk in GB for NFS storage')
param dataDiskSize int = 1024

@allowed([
  true
  false
])
@description('Enable Backup on NFS node')
param enableNfsBackup bool = false

@minLength(4)
@description('Administrator username on all VMs and first user created for OpenShift login')
param adminUsername string

@minLength(4)
@description('User created for OpenShift login')
param openshiftUsername string

@minLength(8)
@description('Password for OpenShift login')
param openshiftPassword string

@description('SSH public key for all VMs')
param sshPublicKey string

@minLength(1)
@description('Pull Secret json or reference to keyvault pull secret is stored')
@secure()
param pullSecret string

@description('Azure AD Client ID')
param aadClientId string

@description('Azure AD Client Secret')
@secure()
param aadClientSecret string

var networkResourceGroup = existingVnetResourceGroupName
var redHatTags = {
  app: 'OpenshiftContainerPlatform'
  version: '4.3.x'
  platform: 'AzurePublic'
}
var imageReference = {
  publisher: 'RedHat'
  offer: 'RHEL'
  sku: '7-RAW'
  version: 'latest'
}
var bastionHostname = 'bastionNode'
var nfsHostname = 'nfsNode'
var nfsVmSize = 'Standard_F8s_v2'
var workerSecurityGroupName_var = 'worker-nsg'
var masterSecurityGroupName_var = 'master-nsg'
var bastionSecurityGroupName_var = 'bastion-nsg'
var diagStorageAccountName_var = 'diag${uniqueString(resourceGroup().id)}'
var bastionPublicIpDnsLabel_var = 'bastiondns${uniqueString(resourceGroup().id)}'
var sshKeyPath = '/home/${adminUsername}/.ssh/authorized_keys'
var clusterNodeDeploymentTemplateUrl = uri(artifactsLocation, 'nested/clusternode.json${artifactsLocationSasToken}')
var openshiftDeploymentTemplateUrl = uri(artifactsLocation, 'nested/openshiftdeploy.json${artifactsLocationSasToken}')
var openshiftDeploymentScriptUrl = uri(artifactsLocation, 'scripts/deployOpenshift.sh${artifactsLocationSasToken}')
var nfsInstallScriptUrl = uri(artifactsLocation, 'scripts/setup-nfs.sh${artifactsLocationSasToken}')
var openshiftDeploymentScriptFileName = 'deployOpenshift.sh'
var nfsInstallScriptFileName = 'setup-nfs.sh'
var vaultName_var = '${nfsHostname}-vault'
var backupFabric = 'Azure'
var backupPolicyName = 'DefaultPolicy'
var protectionContainer = 'iaasvmcontainer;iaasvmcontainerv2;${resourceGroup().name};${nfsHostname}'
var protectedItem = 'vm;iaasvmcontainerv2;${resourceGroup().name};${nfsHostname}'

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-09-01' = if (newOrExistingNetwork == 'new') {
  name: virtualNetworkName
  location: location
  tags: {
    displayName: 'VirtualNetwork'
    app: redHatTags.app
    version: redHatTags.version
    platform: redHatTags.platform
  }
  properties: {
    addressSpace: {
      addressPrefixes: virtualNetworkCIDR
    }
    subnets: [
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetPrefix
          networkSecurityGroup: {
            id: bastionSecurityGroupName.id
          }
        }
      }
      {
        name: masterSubnetName
        properties: {
          addressPrefix: masterSubnetPrefix
          networkSecurityGroup: {
            id: masterSecurityGroupName.id
          }
        }
      }
      {
        name: workerSubnetName
        properties: {
          addressPrefix: workerSubnetPrefix
          networkSecurityGroup: {
            id: workerSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource bastionPublicIpDnsLabel 'Microsoft.Network/publicIPAddresses@2019-09-01' = {
  name: bastionPublicIpDnsLabel_var
  location: location
  sku: {
    name: 'Standard'
  }
  tags: {
    displayName: 'BastionPublicIP'
    app: redHatTags.app
    version: redHatTags.version
    platform: redHatTags.platform
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: bastionPublicIpDnsLabel_var
    }
  }
}

resource bastionHostname_nic 'Microsoft.Network/networkInterfaces@2019-09-01' = {
  name: '${bastionHostname}-nic'
  location: location
  tags: {
    displayName: 'BastionNetworkInterface'
    app: redHatTags.app
    version: redHatTags.version
    platform: redHatTags.platform
  }
  properties: {
    ipConfigurations: [
      {
        name: '${bastionHostname}ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId(networkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, bastionSubnetName)
          }
          publicIPAddress: {
            id: bastionPublicIpDnsLabel.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: bastionSecurityGroupName.id
    }
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource nfsHostname_nic 'Microsoft.Network/networkInterfaces@2019-09-01' = if (storageOption == 'nfs') {
  name: '${nfsHostname}-nic'
  location: location
  tags: {
    displayName: 'NFSNetworkInterface'
    app: redHatTags.app
    version: redHatTags.version
    platform: redHatTags.platform
  }
  properties: {
    ipConfigurations: [
      {
        name: '${nfsHostname}ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId(networkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, workerSubnetName)
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: workerSecurityGroupName.id
    }
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource bastionSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: bastionSecurityGroupName_var
  location: location
  tags: {
    displayName: 'BastionNSG'
    app: redHatTags.app
    version: redHatTags.version
    platform: redHatTags.platform
  }
  properties: {
    securityRules: [
      {
        name: 'allowSSHin_all'
        properties: {
          description: 'Allow SSH in from all locations'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource diagStorageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: diagStorageAccountName_var
  location: location
  kind: 'Storage'
  tags: {
    displayName: diagStorageAccountName_var
    app: redHatTags.app
    version: redHatTags.version
    platform: redHatTags.platform
  }
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
}

module BastionVmDeployment '?' /*TODO: replace with correct path to [variables('clusterNodeDeploymentTemplateUrl')]*/ = {
  name: 'BastionVmDeployment'
  params: {
    location: location
    sshKeyPath: sshKeyPath
    sshPublicKey: sshPublicKey
    dataDiskSize: dataDiskSize
    adminUsername: adminUsername
    vmSize: bastionVmSize
    hostname: bastionHostname
    role: 'bootnode'
    vmStorageType: 'Premium_LRS'
    diagStorageAccount: diagStorageAccountName_var
    imageReference: imageReference
    redHatTags: redHatTags
  }
  dependsOn: [
    diagStorageAccountName
    bastionHostname_nic
  ]
}

resource masterSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: masterSecurityGroupName_var
  location: location
  tags: {
    displayName: 'MasterNSG'
    app: redHatTags.app
    version: redHatTags.version
    platform: redHatTags.platform
  }
  properties: {
    securityRules: [
      {
        name: 'allowHTTPS_all'
        properties: {
          description: 'Allow HTTPS connections from all locations'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '6443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource workerSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: workerSecurityGroupName_var
  location: location
  tags: {
    displayName: 'WorkerNSG'
    app: redHatTags.app
    version: redHatTags.version
    platform: redHatTags.platform
  }
  properties: {
    securityRules: [
      {
        name: 'allowHTTPS_all'
        properties: {
          description: 'Allow HTTPS connections from all locations'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'allowHTTPIn_all'
        properties: {
          description: 'Allow HTTP connections from all locations'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
        }
      }
    ]
  }
}

module OpenShiftDeployment '?' /*TODO: replace with correct path to [variables('openshiftDeploymentTemplateUrl')]*/ = {
  name: 'OpenShiftDeployment'
  params: {
    '_artifactsLocation': uri(artifactsLocation, '.')
    '_artifactsLocationSasToken': artifactsLocationSasToken
    location: location
    openshiftDeploymentScriptUrl: openshiftDeploymentScriptUrl
    openshiftDeploymentScriptFileName: openshiftDeploymentScriptFileName
    masterInstanceCount: masterInstanceCount
    workerInstanceCount: workerInstanceCount
    adminUsername: adminUsername
    openshiftUsername: openshiftUsername
    openshiftPassword: openshiftPassword
    aadClientId: aadClientId
    aadClientSecret: aadClientSecret
    redHatTags: redHatTags
    sshPublicKey: sshPublicKey
    pullSecret: pullSecret
    virtualNetworkName: virtualNetworkName
    virtualNetworkCIDR: virtualNetworkCIDR[0]
    pxSpecUrl: pxSpecUrl
    storageOption: storageOption
    bastionHostname: bastionHostname
    nfsHostname: nfsHostname
    singleZoneOrMultiZone: singleZoneOrMultiZone
    dnsZone: dnsZone
    dnsZoneRG: dnsZoneRG
    masterInstanceType: masterVmSize
    workerInstanceType: workerVmSize
    clusterName: clusterName
    networkResourceGroup: networkResourceGroup
    masterSubnetName: masterSubnetName
    workerSubnetName: workerSubnetName
    enableFips: fipsEnabled
    privateOrPublic: ((privateOrPublicEndpoints == 'private') ? 'Internal' : 'External')
  }
  dependsOn: [
    BastionVmDeployment
  ]
}

module nfsVmDeployment '?' /*TODO: replace with correct path to [variables('clusterNodeDeploymentTemplateUrl')]*/ = if (storageOption == 'nfs') {
  name: 'nfsVmDeployment'
  params: {
    location: location
    sshKeyPath: sshKeyPath
    sshPublicKey: sshPublicKey
    dataDiskSize: dataDiskSize
    adminUsername: adminUsername
    vmSize: nfsVmSize
    hostname: nfsHostname
    role: 'datanode'
    vmStorageType: 'Premium_LRS'
    diagStorageAccount: diagStorageAccountName_var
    imageReference: imageReference
    redHatTags: redHatTags
  }
  dependsOn: [
    diagStorageAccountName
  ]
}

resource nfsHostname_installNfsServer 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = if (storageOption == 'nfs') {
  name: '${nfsHostname}/installNfsServer'
  location: location
  tags: {
    displayName: 'InstallNfsServer'
    app: redHatTags.app
    version: redHatTags.version
    platform: redHatTags.platform
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        nfsInstallScriptUrl
      ]
    }
    protectedSettings: {
      commandToExecute: 'bash ${nfsInstallScriptFileName}'
    }
  }
  dependsOn: [
    nfsVmDeployment
  ]
}

resource vaultName 'Microsoft.RecoveryServices/vaults@2019-05-13' = if (enableNfsBackup == 'true') {
  location: location
  name: vaultName_var
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {}
}

resource vaultName_backupFabric_protectionContainer_protectedItem 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2016-12-01' = if (enableNfsBackup == 'true') {
  name: '${vaultName_var}/${backupFabric}/${protectionContainer}/${protectedItem}'
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: resourceId('Microsoft.RecoveryServices/vaults/backupPolicies', vaultName_var, backupPolicyName)
    sourceResourceId: resourceId('Microsoft.Compute/virtualMachines', nfsHostname)
  }
  dependsOn: [
    nfsVmDeployment
    vaultName
  ]
}

output Openshift_Console_URL string = 'https://console-openshift-console.apps.${clusterName}.${dnsZone}'
output BastionVM_SSH string = 'ssh ${adminUsername}@${reference(bastionPublicIpDnsLabel_var).dnsSettings.fqdn}'