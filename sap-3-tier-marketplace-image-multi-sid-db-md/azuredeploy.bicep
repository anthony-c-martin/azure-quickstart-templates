@minLength(3)
@maxLength(3)
@description('SAP System ID.')
param sapSystemId string = 'DEV'

@allowed([
  'Windows Server 2012 Datacenter'
  'Windows Server 2012 R2 Datacenter'
  'Windows Server 2016 Datacenter'
  'SLES 12'
  'SLES 12 BYOS'
  'RHEL 7'
  'Oracle Linux 7'
])
@description('The type of the operating system you want to deploy.')
param osType string = 'Windows Server 2012 R2 Datacenter'

@allowed([
  'SQL'
  'HANA'
])
@description('The type of the database')
param dbtype string = 'SQL'

@allowed([
  'Demo'
  'Small'
  'Medium'
  'Large'
  'X-Large'
])
@description('The size of the SAP System you want to deploy.')
param sapSystemSize string = 'Small'

@allowed([
  'HA'
  'Not HA'
])
@description('Determines whether this is a high available deployment or not. A HA deployment contains multiple instances of single point of failures.')
param systemAvailability string = 'Not HA'

@description('Username for the Virtual Machine.')
param adminUsername string

@allowed([
  'password'
  'sshPublicKey'
])
@description('Type of authentication to use on the Virtual Machine.')
param authenticationType string = 'password'

@description('Password or ssh key for the Virtual Machine.')
@secure()
param adminPasswordOrKey string

@description('The id of the subnet you want to use.')
param subnetId string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/sap-3-tier-marketplace-image-multi-sid-db-md/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var images = {
  'Windows Server 2012 Datacenter': {
    sku: '2012-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    version: 'latest'
    OSType: 'Windows'
    Plan: {}
    UsePlan: false
    osDiskSize: 128
  }
  'Windows Server 2012 R2 Datacenter': {
    sku: '2012-R2-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    version: 'latest'
    OSType: 'Windows'
    Plan: {}
    UsePlan: false
    osDiskSize: 128
  }
  'Windows Server 2016 Datacenter': {
    sku: '2016-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    version: 'latest'
    OSType: 'Windows'
    Plan: {}
    UsePlan: false
    osDiskSize: 128
  }
  'SLES 12': {
    sku: '12-SP3'
    offer: 'SLES-SAP'
    publisher: 'SUSE'
    version: 'latest'
    OSType: 'Linux'
    Plan: {}
    UsePlan: false
    osDiskSize: 64
  }
  'SLES 12 BYOS': {
    sku: '12-SP3'
    offer: 'SLES-SAP-BYOS'
    publisher: 'SUSE'
    version: 'latest'
    OSType: 'Linux'
    Plan: {}
    UsePlan: false
    osDiskSize: 64
  }
  'RHEL 7': {
    sku: '7.4'
    offer: 'RHEL'
    publisher: 'RedHat'
    version: 'latest'
    OSType: 'Linux'
    Plan: {}
    UsePlan: false
    osDiskSize: 64
  }
  'Oracle Linux 7': {
    sku: '7.3'
    offer: 'Oracle-Linux'
    publisher: 'Oracle'
    version: 'latest'
    OSType: 'Linux'
    Plan: {}
    UsePlan: false
    osDiskSize: 64
  }
}
var internalOSType = images[osType].OSType
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
var csExtension = {
  Windows: {
    Publisher: 'Microsoft.Compute'
    Name: 'CustomScriptExtension'
    Version: '1.7'
    script: uri(artifactsLocation, 'scripts/diskConfig.ps1${artifactsLocationSasToken}')
    scriptCall: 'powershell.exe -ExecutionPolicy bypass -File diskConfig.ps1'
  }
  Linux: {
    Publisher: 'Microsoft.Azure.Extensions'
    Name: 'CustomScript'
    Version: '2.0'
    script: uri(artifactsLocation, 'scripts/diskConfig.sh${artifactsLocationSasToken}')
    scriptCall: 'sh diskConfig.sh'
  }
}
var cseExtPublisher = csExtension[internalOSType].Publisher
var cseExtName = csExtension[internalOSType].Name
var cseExtVersion = csExtension[internalOSType].Version
var csExtensionScript = csExtension[internalOSType].script
var csExtensionscriptCall = csExtension[internalOSType].scriptCall
var sizes = {
  Demo: {
    HANA: {
      vmSize: 'Standard_E8s_v3'
      disks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 2
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 3
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 4
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 5
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 6
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
        {
          lun: 7
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0,1#2,3#4#5#6,7\' -names \'data#log#shared#usrsap#backup\' -paths \'/hana/data#/hana/log#/hana/shared#/usr/sap#/hana/backup\'  -sizes \'100#100#100#100#100\''
      }
      useFastNetwork: false
    }
    SQL: {
      vmSize: 'Standard_DS12_v2'
      disks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 128
        }
      ]
      scriptArguments: {
        Windows: '-luns "0" -names "data" -paths "C:\\sql\\data,C:\\sql\\log"  -sizes "70,100"'
      }
      useFastNetwork: false
    }
  }
  Small: {
    HANA: {
      vmSize: 'Standard_E32s_v3'
      disks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 2
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 3
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 4
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 64
        }
        {
          lun: 5
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0,1,2#3#4#5\' -names \'datalog#shared#usrsap#backup\' -paths \'/hana/data,/hana/log#/hana/shared#/usr/sap#/hana/backup\' -sizes \'70,100#100#100#100\''
      }
      useFastNetwork: true
    }
    SQL: {
      vmSize: 'Standard_DS13_v2'
      disks: [
        {
          lun: 0
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 1
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 2
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 3
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 4
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
      ]
      scriptArguments: {
        Windows: '-luns \'0,1,2,3#4\' -names \'data#log\' -paths \'C:\\sql\\data#C:\\sql\\log\'  -sizes \'100#100\''
      }
      useFastNetwork: true
    }
  }
  Medium: {
    HANA: {
      vmSize: 'Standard_E64s_v3'
      disks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 2
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 3
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 4
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 64
        }
        {
          lun: 5
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0,1,2#3#4#5\' -names \'datalog#shared#usrsap#backup\' -paths \'/hana/data,/hana/log#/hana/shared#/usr/sap#/hana/backup\' -sizes \'70,100#100#100#100\''
      }
      useFastNetwork: true
    }
    SQL: {
      vmSize: 'Standard_DS14_v2'
      disks: [
        {
          lun: 0
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 1
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 2
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 3
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 4
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 5
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 6
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 7
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
      ]
      scriptArguments: {
        Windows: '-luns \'0,1,2,3,4,5,6#7\' -names \'data#log\' -paths \'C:\\sql\\data#C:\\sql\\log\'  -sizes \'100#100\''
      }
      useFastNetwork: true
    }
  }
  Large: {
    HANA: {
      vmSize: 'Standard_M64s'
      disks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 2
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 3
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 4
          caching: 'None'
          writeAcceleratorEnabled: 'true'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 5
          caching: 'None'
          writeAcceleratorEnabled: 'true'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 6
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 7
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 64
        }
        {
          lun: 8
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 9
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0,1,2,3#4,5#6#7#8,9\' -names \'data#log#shared#usrsap#backup\' -paths \'/hana/data#/hana/log#/hana/shared#/usr/sap#/hana/backup\' -sizes \'100#100#100#100#100\''
      }
      useFastNetwork: true
    }
    SQL: {
      vmSize: 'Standard_GS4'
      disks: [
        {
          lun: 0
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 1
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 2
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 3
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 4
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 5
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 512
        }
      ]
      scriptArguments: {
        Windows: '-luns \'0,1,2,3,4#5\' -names \'data#log\' -paths \'C:\\sql\\data#C:\\sql\\log\'  -sizes \'100#100\''
      }
      useFastNetwork: false
    }
  }
  'X-Large': {
    HANA: {
      vmSize: 'Standard_M128s'
      disks: [
        {
          lun: 0
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 1
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 2
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 3
          caching: 'None'
          writeAcceleratorEnabled: 'true'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 4
          caching: 'None'
          writeAcceleratorEnabled: 'true'
          createOption: 'Empty'
          diskSizeGB: 512
        }
        {
          lun: 5
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 6
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 64
        }
        {
          lun: 7
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 2048
        }
        {
          lun: 8
          caching: 'ReadOnly'
          createOption: 'Empty'
          diskSizeGB: 2048
        }
      ]
      scriptArguments: {
        Linux: '-luns \'0,1,2#3,4#5#6#7,8\' -names \'data#log#shared#usrsap#backup\' -paths \'/hana/data#/hana/log#/hana/shared#/usr/sap#/hana/backup\' -sizes \'100#100#100#100#100\''
      }
      useFastNetwork: true
    }
    SQL: {
      vmSize: 'Standard_GS5'
      disks: [
        {
          lun: 0
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 1
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 2
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 3
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 4
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 5
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 6
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
        {
          lun: 7
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: 1024
        }
      ]
      scriptArguments: {
        Windows: '-luns \'0,1,2,3,4,5,6#7\' -names \'data#log\' -paths \'C:\\sql\\data#C:\\sql\\log\'  -sizes \'100#100\''
      }
      useFastNetwork: false
    }
  }
}
var dbvmCount = ((systemAvailability == 'HA') ? 2 : 1)
var sidlower = toLower(sapSystemId)
var publicIpNameDB_var = '${sidlower}-pip-db'
var vnetName_var = '${sidlower}-vnet'
var subnetName = 'Subnet'
var subnets = {
  true: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetName)
  false: subnetId
}
var selectedSubnetId = subnets[string((length(subnetId) == 0))]
var nsgName_var = '${sidlower}-nsg'
var avSetNameDB_var = '${sidlower}-avset-db'
var loadBalancerNameDB_var = '${sidlower}-lb-db'
var nicNameDB_var = '${sidlower}-nic-db'
var vmNameDB_var = '${sidlower}-db'
var osSecurityRules = {
  Windows: [
    {
      name: 'RDP'
      properties: {
        description: 'Allow RDP Subnet'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '3389'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
        access: 'Allow'
        priority: 100
        direction: 'Inbound'
      }
    }
  ]
  Linux: [
    {
      name: 'SSH'
      properties: {
        description: 'Allow SSH Subnet'
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
var selectedSecurityRules = osSecurityRules[internalOSType]
var loadBalancerFrontendHANADB = 'frontend'
var backendPoolHANADB = 'backend'
var probePortHANADB = 'probe'
var dbInstanceNumberHANA = 3
var lbPrefixHANADB = 'lb${padLeft(dbInstanceNumberHANA, 2, '0')}'
var probePortInternalHANADB = (62500 + dbInstanceNumberHANA)
var lbRulePrefixHANADB = '${lbPrefixHANADB}Rule'
var loadBalancerFrontendSQLDB = 'frontend'
var loadBalancerFrontendSQLCL = 'frontendcl'
var backendPoolSQLDB = 'backend'
var backendPoolSQLCL = 'backendcl'
var probePortSQLDB = 'probe'
var probePortSQLCL = 'probecl'
var lbPrefixSQLDB = 'lbsql'
var lbPrefixSQLcl = 'lbsqlcl'
var probePortInternalSQLDB = 62500
var probePortInternalSQLCL = 63500
var lbRulePrefixSQLDB = '${lbPrefixSQLDB}Rule'
var idleTimeoutInMinutes = 30
var lbFrontendConfigs = {
  HANA: {
    Linux: [
      {
        properties: {
          subnet: {
            id: selectedSubnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
        name: loadBalancerFrontendHANADB
      }
    ]
  }
  SQL: {
    Windows: [
      {
        properties: {
          subnet: {
            id: selectedSubnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
        name: loadBalancerFrontendSQLDB
      }
      {
        properties: {
          subnet: {
            id: selectedSubnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
        name: loadBalancerFrontendSQLCL
      }
    ]
  }
}
var lbBackendPools = {
  HANA: {
    Linux: [
      {
        name: backendPoolHANADB
      }
    ]
  }
  SQL: {
    Windows: [
      {
        name: backendPoolSQLDB
      }
      {
        name: backendPoolSQLCL
      }
    ]
  }
}
var lbRules = {
  HANA: {
    Linux: [
      {
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerNameDB_var, loadBalancerFrontendHANADB)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameDB_var, backendPoolHANADB)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerNameDB_var, probePortHANADB)
          }
          protocol: 'Tcp'
          frontendPort: (30013 + (dbInstanceNumberHANA * 100))
          backendPort: (30013 + (dbInstanceNumberHANA * 100))
          enableFloatingIP: true
          idleTimeoutInMinutes: idleTimeoutInMinutes
        }
        name: '${lbRulePrefixHANADB}3${padLeft(dbInstanceNumberHANA, 2, '0')}13'
      }
      {
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerNameDB_var, loadBalancerFrontendHANADB)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameDB_var, backendPoolHANADB)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerNameDB_var, probePortHANADB)
          }
          protocol: 'Tcp'
          frontendPort: (30015 + (dbInstanceNumberHANA * 100))
          backendPort: (30015 + (dbInstanceNumberHANA * 100))
          enableFloatingIP: true
          idleTimeoutInMinutes: idleTimeoutInMinutes
        }
        name: '${lbRulePrefixHANADB}3${padLeft(dbInstanceNumberHANA, 2, '0')}15'
      }
      {
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerNameDB_var, loadBalancerFrontendHANADB)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameDB_var, backendPoolHANADB)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerNameDB_var, probePortHANADB)
          }
          protocol: 'Tcp'
          frontendPort: (30040 + (dbInstanceNumberHANA * 100))
          backendPort: (30040 + (dbInstanceNumberHANA * 100))
          enableFloatingIP: true
          idleTimeoutInMinutes: idleTimeoutInMinutes
        }
        name: '${lbRulePrefixHANADB}3${padLeft(dbInstanceNumberHANA, 2, '0')}40'
      }
      {
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerNameDB_var, loadBalancerFrontendHANADB)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameDB_var, backendPoolHANADB)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerNameDB_var, probePortHANADB)
          }
          protocol: 'Tcp'
          frontendPort: (30041 + (dbInstanceNumberHANA * 100))
          backendPort: (30041 + (dbInstanceNumberHANA * 100))
          enableFloatingIP: true
          idleTimeoutInMinutes: idleTimeoutInMinutes
        }
        name: '${lbRulePrefixHANADB}3${padLeft(dbInstanceNumberHANA, 2, '0')}41'
      }
      {
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerNameDB_var, loadBalancerFrontendHANADB)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameDB_var, backendPoolHANADB)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerNameDB_var, probePortHANADB)
          }
          protocol: 'Tcp'
          frontendPort: (30042 + (dbInstanceNumberHANA * 100))
          backendPort: (30042 + (dbInstanceNumberHANA * 100))
          enableFloatingIP: true
          idleTimeoutInMinutes: idleTimeoutInMinutes
        }
        name: '${lbRulePrefixHANADB}3${padLeft(dbInstanceNumberHANA, 2, '0')}42'
      }
    ]
  }
  SQL: {
    Windows: [
      {
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerNameDB_var, loadBalancerFrontendSQLDB)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerNameDB_var, backendPoolSQLDB)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerNameDB_var, probePortSQLDB)
          }
          protocol: 'Tcp'
          frontendPort: 1433
          backendPort: 1433
          enableFloatingIP: true
          idleTimeoutInMinutes: idleTimeoutInMinutes
        }
        name: '${lbRulePrefixSQLDB}1433'
      }
    ]
  }
}
var lbProbes = {
  HANA: {
    Linux: [
      {
        properties: {
          protocol: 'Tcp'
          port: probePortInternalHANADB
          intervalInSeconds: 5
          numberOfProbes: 2
        }
        name: probePortHANADB
      }
    ]
  }
  SQL: {
    Windows: [
      {
        properties: {
          protocol: 'Tcp'
          port: probePortInternalSQLDB
          intervalInSeconds: 5
          numberOfProbes: 2
        }
        name: probePortSQLDB
      }
      {
        properties: {
          protocol: 'Tcp'
          port: probePortInternalSQLCL
          intervalInSeconds: 5
          numberOfProbes: 2
        }
        name: probePortSQLCL
      }
    ]
  }
}
var nicBackAddressPools = {
  HANA: {
    Linux: [
      {
        id: '${loadBalancerNameDB.id}/backendAddressPools/${backendPoolHANADB}'
      }
    ]
  }
  SQL: {
    Windows: [
      {
        id: '${loadBalancerNameDB.id}/backendAddressPools/${backendPoolSQLDB}'
      }
      {
        id: '${loadBalancerNameDB.id}/backendAddressPools/${backendPoolSQLCL}'
      }
    ]
  }
}

resource nsgName 'Microsoft.Network/networkSecurityGroups@2018-04-01' = if (length(subnetId) == 0) {
  name: concat(nsgName_var)
  location: location
  properties: {
    securityRules: selectedSecurityRules
  }
}

resource vnetName 'Microsoft.Network/virtualNetworks@2018-04-01' = if (length(subnetId) == 0) {
  name: vnetName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsgName.id
          }
        }
      }
    ]
  }
}

resource avSetNameDB 'Microsoft.Compute/availabilitySets@2017-03-30' = {
  name: avSetNameDB_var
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 20
  }
}

resource publicIpNameDB 'Microsoft.Network/publicIPAddresses@2018-04-01' = [for i in range(0, dbvmCount): if (length(subnetId) == 0) {
  name: '${publicIpNameDB_var}-${i}'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  dependsOn: [
    vnetName
  ]
}]

resource loadBalancerNameDB 'Microsoft.Network/loadBalancers@2018-04-01' = if (dbvmCount > 1) {
  name: loadBalancerNameDB_var
  location: location
  properties: {
    frontendIPConfigurations: lbFrontendConfigs[dbtype][internalOSType]
    backendAddressPools: lbBackendPools[dbtype][internalOSType]
    loadBalancingRules: lbRules[dbtype][internalOSType]
    probes: lbProbes[dbtype][internalOSType]
  }
  dependsOn: [
    vnetName
  ]
}

resource nicNameDB 'Microsoft.Network/networkInterfaces@2017-06-01' = [for i in range(0, dbvmCount): {
  name: '${nicNameDB_var}-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: ((length(subnetId) == 0) ? json('{"id": "${resourceId('Microsoft.Network/publicIPAddresses', '${publicIpNameDB_var}-${i}')}"}') : json('null'))
          subnet: {
            id: selectedSubnetId
          }
          loadBalancerBackendAddressPools: ((dbvmCount > 1) ? nicBackAddressPools[dbtype][internalOSType] : json('null'))
        }
      }
    ]
    enableAcceleratedNetworking: sizes[sapSystemSize][dbtype].useFastNetwork
  }
  dependsOn: [
    publicIpNameDB
    vnetName
    loadBalancerNameDB
  ]
}]

resource vmNameDB 'Microsoft.Compute/virtualMachines@2017-12-01' = [for i in range(0, dbvmCount): {
  name: '${vmNameDB_var}-${i}'
  location: location
  properties: {
    availabilitySet: {
      id: avSetNameDB.id
    }
    hardwareProfile: {
      vmSize: sizes[sapSystemSize][dbtype].vmSize
    }
    osProfile: {
      computerName: '${vmNameDB_var}-${i}'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: images[osType].publisher
        offer: images[osType].offer
        sku: images[osType].sku
        version: 'latest'
      }
      osDisk: {
        name: '${vmNameDB_var}-${i}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        diskSizeGB: images[osType].osDiskSize
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: sizes[sapSystemSize][dbtype].disks
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${nicNameDB_var}-${i}')
        }
      ]
    }
  }
  dependsOn: [
    nicNameDB
    avSetNameDB
  ]
}]

resource vmNameDB_cseExtName 'Microsoft.Compute/virtualMachines/extensions@2017-12-01' = [for i in range(0, dbvmCount): {
  name: '${vmNameDB_var}-${i}/${cseExtName}'
  location: location
  properties: {
    publisher: cseExtPublisher
    type: cseExtName
    typeHandlerVersion: cseExtVersion
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        csExtensionScript
      ]
      commandToExecute: '${csExtensionscriptCall} ${sizes[sapSystemSize][dbtype].scriptArguments[internalOSType]}'
    }
  }
  dependsOn: [
    vmNameDB
  ]
}]