@description('Location for all resources')
param location string = resourceGroup().location

@description('Unique DNS Name for the Public IP used to access the Docker Virtual Machine (master node).')
param dnsNameForJumpBox string = 'jumpbox-${uniqueString(resourceGroup().id)}'

@metadata({
  description: 'The image to use for VMs created. This can be marketplace or custom image'
  link: 'https://docs.microsoft.com/en-us/nodejs/api/azure-arm-compute/imagereference?view=azure-node-2.2.0'
})
param vmImageReference object = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: '18.04-LTS'
  version: 'latest'
}

@description('Size of VMs in the VM Scale Set.')
param vmNodeSku string = 'Standard_F8s_v2'

@description('Size of the master node.')
param vmMasterSku string = 'Standard_F16s_v2'

@allowed([
  'Premium_LRS'
  'Standard_LRS'
])
@description('Choose between a standard disk for and SSD disk for the master node\'s NFS fileshare')
param vmMasterDiskType string = 'Premium_LRS'

@allowed([
  32
  64
  128
  256
  512
  1000
  2000
  4000
  10000
])
@description('The SSD Size to be used for the NFS file share. For pricing details see https://azure.microsoft.com/en-us/pricing/details/managed-disks/')
param vmMasterDiskSize int = 256

@description('An additional installs script (bash run as root) to be run after nodes/master are configured. Can be used to mount additional storage or do additional setup')
param vmAdditionalInstallScriptUrl string = ''

@description('An argument to be passed to the additional install script')
param vmAdditionalInstallScriptArgument string = ''

@description('The install URL for nextflow, this can be used to pin nextflow versions')
param nextflowInstallUrl string = 'https://get.nextflow.io'

@minValue(1)
@maxValue(100)
@description('Number of cluster VM instances (100 or less).')
param instanceCount int = 2

@description('Admin username on all VMs.')
param adminUsername string

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('Name of the virtual network to deploy the scale set into.')
param vnetName string = 'nfvnet'

@description('Name of the subnet to deploy the scale set into.')
param subnetName string = 'nfsubnet'

@description('Azure file share name.')
param shareName string = 'sharedstorage'

@description('Path on VM to mount file shares. \'/datadisks/disk1/\' is a Premium Managed disk with high iops, this will suit most uses.')
param mountpointPath string = '/datadisks/disk1'

@description('Sets the cluster.maxCpus setting on all cluster nodes')
param nodeMaxCpus int = 2

@description('Determines whether to run the custom script extension on a subsequent deployment. Use the defaultValue.')
param forceUpdateTag string = newGuid()

@description('*Advanced* This is best left as default unless you are an advanced user. The base URI where artifacts required by this template are located.')
param artifactsLocation string = deployment().properties.templateLink.uri

@description('*Advanced* This should be left as default unless you are an advanced user. The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('*Advanced* This should be left as default unless you are an advanced user. The folder in the artifacts location were shared scripts are stored.')
param diskInitScriptUri string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/shared_scripts/ubuntu/vm-disk-utils-0.1.sh'

@description('*Advanced* This should be left as default unless you are an advanced user. The folder in the artifacts location were nextflow scripts are stored.')
param artifactsNextflowFolder string = 'scripts'

var nextflowInitScript = uri(artifactsLocation, '${artifactsNextflowFolder}/init.sh${artifactsLocationSasToken}')
var jumpboxNICName_var = 'jumpboxNIC'
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var vmssName_var = 'cluster${uniqueString(dnsNameForJumpBox)}'
var storageAccountType = 'Standard_LRS'
var storageAccountName_var = 'nfstorage${uniqueString(resourceGroup().id)}'
var storageSuffix = environment().suffixes.storage
var publicIPAddressName_var = 'jumpboxPublicIP'
var publicIPAddressType = 'Dynamic'
var jumpboxVMName_var = 'jumpboxVM'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}
var networkSecurityGroupName_var = 'default-NSG'

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName_var
  location: location
  kind: 'Storage'
  sku: {
    name: storageAccountType
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForJumpBox
    }
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-22'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnetName
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
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource jumpboxNICName 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: jumpboxNICName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetName_resource
  ]
}

resource jumpboxVMName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: jumpboxVMName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmMasterSku
    }
    osProfile: {
      computerName: jumpboxVMName_var
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: vmImageReference
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          lun: 0
          name: 'jumpboxdatadisk'
          diskSizeGB: vmMasterDiskSize
          caching: 'None'
          createOption: 'Empty'
          managedDisk: {
            storageAccountType: vmMasterDiskType
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jumpboxNICName.id
        }
      ]
    }
  }
  dependsOn: [
    storageAccountName
  ]
}

resource jumpboxVMName_nfinit 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  parent: jumpboxVMName
  name: 'nfinit'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    forceUpdateTag: forceUpdateTag
    settings: {
      fileUris: [
        nextflowInitScript
        diskInitScriptUri
      ]
    }
    protectedSettings: {
      commandToExecute: 'bash init.sh ${storageAccountName_var} "${listKeys(storageAccountName.id, '2019-06-01').keys[0].value}" ${shareName} ${storageSuffix} ${mountpointPath} false ${adminUsername} 0 ${nextflowInstallUrl} ${vmAdditionalInstallScriptUrl} ${vmAdditionalInstallScriptArgument}'
    }
  }
}

resource vmssName 'Microsoft.Compute/virtualMachineScaleSets@2019-12-01' = {
  name: vmssName_var
  location: location
  sku: {
    name: vmNodeSku
    capacity: instanceCount
  }
  properties: {
    overprovision: true
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
        }
        imageReference: vmImageReference
      }
      osProfile: {
        computerNamePrefix: vmssName_var
        adminUsername: adminUsername
        adminPassword: adminPasswordOrKey
        linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig'
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
                    }
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
            name: 'filesextension'
            properties: {
              publisher: 'Microsoft.Azure.Extensions'
              type: 'CustomScript'
              typeHandlerVersion: '2.0'
              autoUpgradeMinorVersion: true
              forceUpdateTag: forceUpdateTag
              settings: {
                fileUris: [
                  nextflowInitScript
                  diskInitScriptUri
                ]
              }
              protectedSettings: {
                commandToExecute: 'bash init.sh ${storageAccountName_var} "${listKeys(storageAccountName.id, '2019-06-01').keys[0].value}" ${shareName} ${storageSuffix} ${mountpointPath} true ${adminUsername} ${nodeMaxCpus} ${nextflowInstallUrl} ${vmAdditionalInstallScriptUrl} ${vmAdditionalInstallScriptArgument}'
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    vnetName_resource
  ]
}

output JumpboxConnectionString string = 'ssh ${adminUsername}@${reference(publicIPAddressName_var).dnsSettings.fqdn}'
output ExampleNextflowCommand string = 'nextflow run hello -process.executor ignite -cluster.join path:${mountpointPath}/cifs/cluster -with-timeline runtimeline.html -with-trace -cluster.maxCpus 0'
output ExampleNextflowCommandWithDocker string = 'nextflow run nextflow-io/rnatoy -with-docker -process.executor ignite -cluster.join path:${mountpointPath}/cifs/cluster -with-timeline runtimeline.html -with-trace -cluster.maxCpus 0'