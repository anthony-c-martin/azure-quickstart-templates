@description('Size of Drupal VMs in the VM Scale Set.')
param drupalVmSku string = 'Standard_D2s_v3'

@allowed([
  'Standard_LRS'
  'Premium_LRS'
  'StandardSSD_LRS'
])
@description('Storage account type for the cluster')
param drupalVMDiskSku string = 'StandardSSD_LRS'

@allowed([
  '14.04.4-LTS'
  '16.04-LTS'
  '18.04-LTS'
])
@description('The Ubuntu version for the Drupal VM. This will pick a fully patched image of this given Ubuntu version.')
param drupalUbuntuOSVersion string = '18.04-LTS'

@description('Admin User for the Drupal installation.')
param drupalAdminUser string

@description('Admin password for the Drupal installation.')
@secure()
param drupalAdminPassword string

@allowed([
  '8.1.1'
])
@description('The Drupal Version to be installed')
param drupalVersion string = '8.1.1'

@minLength(3)
@maxLength(61)
@description('String used as a base for naming resources. Must be 3-61 characters in length and globally unique across Azure. A hash is prepended to this string for some resources, and resource-specific information is appended.')
param vmssName string = 'vmss-${uniqueString(resourceGroup().id)}'

@minValue(2)
@maxValue(10)
@description('Number of Drupal VM instances (minimum and default instance count). Atleast 2 are recommended for high availability')
param instanceCount int = 2

@minValue(2)
@maxValue(100)
@description('maximum number of drupal instances in the vm scale set')
param maximumInstanceCount int = 10

@description('Admin username on all Drupal VMs, gluster VMs.')
param adminUsername string

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('The MySQL Database to which drupal will be installed')
param drupalInstallationDatabaseName string = 'drupaldb'

@allowed([
  'no'
  'yes'
])
@description('If Yes new MySQL server will be provisioned using the mysql replication template')
param createNewMySQLServer string = 'yes'

@description('Fully qualified domain name of the existing mysql server.  Required if a new mySql server is not created.')
param existingMySqlFQDN string = 'none'

@description('mysql username. When creating New MySQL server using mysql replication template this will be admin.')
param mySqlUser string

@description('mysql user password. For existing enter the existing password. In case of new MySQL server this will be the password for MySqL admin user')
@secure()
param mySqlUserPassword string

@description('Required when creating new MySQL server, FQDN of server will be using dnsLabelPrefix.location.cloudapp.azure.com')
param newMySqlDnsLabelPrefix string = 'mysql-${uniqueString(resourceGroup().id)}'

@description('Required when creating new MySQL server. User name to ssh in to the MySQL VMs')
param mySqlVmAdminUsername string

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param mySqlVmAuthenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param mySqlVmadminPasswordOrKey string

@description('Required when creating new MySQL server. size for the mySql VMs')
param mySqlVmSize string = 'Standard_D2s_v3'

@allowed([
  'CentOS 6.10'
  'CentOS 7.8'
  'CentOS 8.2'
  'Ubuntu 14.04.5-LTS'
  'Ubuntu 16.04-LTS'
  'Ubuntu 18.04-LTS'
])
@description('Required when creating new MySQL server. VM OS version')
param mySqlOSVersion string = 'CentOS 8.2'

@description('Virtual network name for the cluster')
param virtualNetworkName string = 'drupal-vnet'

@allowed([
  'new'
  'existing'
])
@description('Identifies whether to use new or existing Virtual Network')
param virtualNetworkNewOrExisting string = 'new'

@description('If using existing VNet, specifies the resource group for the existing VNet')
param virtualNetworkResourceGroupName string = resourceGroup().name

@description('subnet name for the MySQL nodes')
param subnetName string = 'drupal-subnet'

@description('IP address in CIDR for virtual network')
param virtualNetworkAddressPrefix string = '10.0.0.0/16'

@description('IP address in CIDR for db subnetq')
param subnetAddressPrefix string = '10.0.1.0/24'

@description('Start IP address in the subnet for the VMs')
param subnetStartAddress string = '10.0.1.4'

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Specifies the name of the Azure Storage account used for the file share.')
param storageAccountName string = 'drupal${uniqueString(resourceGroup().id)}'

@minLength(3)
@maxLength(63)
@description('Specifies the name of the File Share. File share names must be between 3 and 63 characters in length and use numbers, lower-case letters and dash (-) only.')
param fileShareName string = 'drupal'

@description('Location for all resources.')
param location string = resourceGroup().location

var accountid = diagnosticsStorageAccountName.id
var bePoolName = 'bepool'
var diagnosticsStorageAccountName_var = 'bootdiags${uniqueString(resourceGroup().id)}'
var ipConfigName = 'ipconfig'
var lbPoolID = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName_var, bePoolName)
var lbProbeID = resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName_var, 'tcpProbe')
var frontEndIPConfigID = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName_var, 'loadBalancerFrontEnd')
var loadBalancerName_var = 'lb-${vmssName}'
var longNamingInfix = toLower(vmssName)
var natBackendPort = 22
var natEndPort = 50119
var natPoolName = 'natpool'
var natStartPort = 50000
var nicName = '${vmssName}nic'
var imageReference = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: drupalUbuntuOSVersion
  version: 'latest'
}
var publicIPAddressID = publicIPAddressName.id
var publicIPAddressName_var = '${vmssName}pip'
var storageAccountType = 'Standard_LRS'
var wadcfgxend = '"><MetricAggregation scheduledTransferPeriod="PT1H"/><MetricAggregation scheduledTransferPeriod="PT1M"/></Metrics></DiagnosticMonitorConfiguration></WadCfg>'
var wadcfgxstart = '${wadlogs}${wadperfcounters1}${wadperfcounters2}<Metrics resourceId="'
var wadlogs = '<WadCfg><DiagnosticMonitorConfiguration>'
var wadmetricsresourceid = vmssName_resource.id
var wadperfcounters1 = '<PerformanceCounters scheduledTransferPeriod="PT1M"><PerformanceCounterConfiguration counterSpecifier="\\Memory\\AvailableMemory" sampleRate="PT15S" unit="Bytes"><annotation displayName="Memory available" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Memory\\PercentAvailableMemory" sampleRate="PT15S" unit="Percent"><annotation displayName="Mem. percent available" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Memory\\UsedMemory" sampleRate="PT15S" unit="Bytes"><annotation displayName="Memory used" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Memory\\PercentUsedMemory" sampleRate="PT15S" unit="Percent"><annotation displayName="Memory percentage" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Memory\\PercentUsedByCache" sampleRate="PT15S" unit="Percent"><annotation displayName="Mem. used by cache" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Processor\\PercentIdleTime" sampleRate="PT15S" unit="Percent"><annotation displayName="CPU idle time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Processor\\PercentUserTime" sampleRate="PT15S" unit="Percent"><annotation displayName="CPU user time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Processor\\PercentProcessorTime" sampleRate="PT15S" unit="Percent"><annotation displayName="CPU percentage guest OS" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Processor\\PercentIOWaitTime" sampleRate="PT15S" unit="Percent"><annotation displayName="CPU IO wait time" locale="en-us"/></PerformanceCounterConfiguration>'
var wadperfcounters2 = '<PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk\\BytesPerSecond" sampleRate="PT15S" unit="BytesPerSecond"><annotation displayName="Disk total bytes" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk\\ReadBytesPerSecond" sampleRate="PT15S" unit="BytesPerSecond"><annotation displayName="Disk read guest OS" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk\\WriteBytesPerSecond" sampleRate="PT15S" unit="BytesPerSecond"><annotation displayName="Disk write guest OS" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk\\TransfersPerSecond" sampleRate="PT15S" unit="CountPerSecond"><annotation displayName="Disk transfers" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk\\ReadsPerSecond" sampleRate="PT15S" unit="CountPerSecond"><annotation displayName="Disk reads" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk\\WritesPerSecond" sampleRate="PT15S" unit="CountPerSecond"><annotation displayName="Disk writes" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk\\AverageReadTime" sampleRate="PT15S" unit="Seconds"><annotation displayName="Disk read time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk\\AverageWriteTime" sampleRate="PT15S" unit="Seconds"><annotation displayName="Disk write time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk\\AverageTransferTime" sampleRate="PT15S" unit="Seconds"><annotation displayName="Disk transfer time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk\\AverageDiskQueueLength" sampleRate="PT15S" unit="Count"><annotation displayName="Disk queue length" locale="en-us"/></PerformanceCounterConfiguration></PerformanceCounters>'
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

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource storageAccountName_default_fileShareName 'Microsoft.Storage/storageAccounts/fileServices/shares@2019-06-01' = {
  name: '${storageAccountName}/default/${fileShareName}'
  dependsOn: [
    storageAccountName_resource
  ]
}

resource diagnosticsStorageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: diagnosticsStorageAccountName_var
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: longNamingInfix
    }
  }
}

resource loadBalancerName 'Microsoft.Network/loadBalancers@2020-06-01' = {
  name: loadBalancerName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
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
    loadBalancingRules: [
      {
        name: 'LBRule'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          backendAddressPool: {
            id: lbPoolID
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: lbProbeID
          }
        }
      }
    ]
    probes: [
      {
        name: 'tcpProbe'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
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
  }
}

module mysql '?' /*TODO: replace with correct path to https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/mysql-replication/azuredeploy.json*/ = if (createNewMySQLServer == 'yes') {
  name: 'mysql'
  params: {
    dnsName: newMySqlDnsLabelPrefix
    location: location
    vmUserName: mySqlVmAdminUsername
    adminPasswordOrKey: mySqlVmadminPasswordOrKey
    authenticationType: mySqlVmAuthenticationType
    mysqlRootPassword: mySqlUserPassword
    mysqlReplicationPassword: mySqlUserPassword
    mysqlProbePassword: mySqlUserPassword
    vmSize: mySqlVmSize
    vmImage: mySqlOSVersion
    virtualNetworkName: virtualNetworkName
    virtualNetworkNewOrExisting: virtualNetworkNewOrExisting
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
    subnetName: subnetName
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    subnetAddressPrefix: subnetAddressPrefix
    subnetStartAddress: subnetStartAddress
  }
}

resource vmssName_resource 'Microsoft.Compute/virtualMachineScaleSets@2020-06-01' = {
  name: vmssName
  location: location
  sku: {
    name: drupalVmSku
    tier: 'Standard'
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
          caching: 'ReadOnly'
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: drupalVMDiskSku
          }
        }
        imageReference: imageReference
      }
      osProfile: {
        computerNamePrefix: vmssName
        adminUsername: adminUsername
        adminPassword: adminPasswordOrKey
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
                  name: ipConfigName
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
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
            name: 'drupalextension'
            properties: {
              publisher: 'Microsoft.Azure.Extensions'
              type: 'CustomScript'
              typeHandlerVersion: '2.0'
              autoUpgradeMinorVersion: true
              settings: {
                fileUris: [
                  uri(artifactsLocation, 'scripts/mount-azure-fileshare.sh${artifactsLocationSasToken}')
                  uri(artifactsLocation, 'scripts/install_drupal.sh${artifactsLocationSasToken}')
                ]
              }
              protectedSettings: {
                commandToExecute: 'bash mount-azure-fileshare.sh ${storageAccountName} \'${listKeys(storageAccountName, '2019-06-01').keys[0].value}\' \'${fileShareName}\' \'/mnt/azurefiles-drupal\' ${adminUsername} ${environment().suffixes.storage};sudo bash install_drupal.sh -d \'${drupalVersion}\' -u ${drupalAdminUser} -p \'${drupalAdminPassword}\' -s \'${existingMySqlFQDN}\' -n ${mySqlUser} -P \'${mySqlUserPassword}\' -k ${drupalInstallationDatabaseName} -z ${createNewMySQLServer} -S ${reference('mysql').outputs.fqdn.value}'
              }
            }
          }
          {
            name: 'LinuxDiagnostic'
            properties: {
              publisher: 'Microsoft.OSTCExtensions'
              type: 'LinuxDiagnostic'
              typeHandlerVersion: '2.3'
              autoUpgradeMinorVersion: true
              settings: {
                xmlCfg: base64(concat(wadcfgxstart, wadmetricsresourceid, wadcfgxend))
                storageAccount: diagnosticsStorageAccountName_var
              }
              protectedSettings: {
                storageAccountName: diagnosticsStorageAccountName_var
                storageAccountKey: listkeys(accountid, '2019-06-01').keys[0].value
                storageAccountEndPoint: 'http://${environment().suffixes.storage}'
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    loadBalancerName
    mysql
  ]
}

resource autoscalesetting 'Microsoft.Insights/autoscaleSettings@2015-04-01' = {
  name: 'autoscalesetting'
  location: location
  properties: {
    name: 'autoscalesetting'
    targetResourceUri: vmssName_resource.id
    enabled: true
    profiles: [
      {
        name: 'Profile1'
        capacity: {
          minimum: instanceCount
          maximum: maximumInstanceCount
          default: instanceCount
        }
        rules: [
          {
            metricTrigger: {
              metricName: '\\Processor\\PercentProcessorTime'
              metricResourceUri: vmssName_resource.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 60
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT1M'
            }
          }
          {
            metricTrigger: {
              metricName: '\\Processor\\PercentProcessorTime'
              metricResourceUri: vmssName_resource.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 50
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
}