@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/tableau-server-single-node/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

@description('The location where these resources will be deployed.  By default this will be the location of the resource group.')
param location string = resourceGroup().location

@allowed([
  'Ubuntu 16.04 LTS'
  'CentOS 7.5'
  'RHEL 7.7'
  'Windows 2019-Datacenter'
  'Windows 2016-Datacenter'
  'Windows 2012-R2-Datacenter'
  'Windows 2012-Datacenter'
])
@description('The operating system of the VM.')
param OS string

@allowed([
  '2020.1.3'
  '2019.4.6'
  '2019.3.7'
  '2019.2.11'
  '2019.1.15'
])
@description('The version of Tableau Server to install.')
param tableau_version string = '2020.1.3'

@allowed([
  'Standard_D16s_v3'
  'Standard_D32s_v3'
  'Standard_D48s_v3'
  'Standard_D4s_v3'
])
@description('Please select the size of the VM you wish to deploy.  Tableau Server should be deployed on a machine with at least 16 vCPUs.  Standard_D4s_v3 is provided for testing only.  Read more about sizing options here: https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-general')
param VMSize string = 'Standard_D16s_v3'

@description('Admin username for Virtual Machine')
param adminUsername string

@description('Password for the Virtual Machine.')
@secure()
param adminPassword string

@description('CIDR block for SSH source - limit to your IP for secure access.')
param source_CIDR string

@description('Tableau Server administrator username.')
param tableau_admin_username string

@description('Tableau Server administrator password.')
@secure()
param tableau_admin_password string

@description('First name to use for registering Tableau Server')
param registration_first_name string

@description('Last name to use for registering Tableau Server')
param registration_last_name string

@description('Email address to use for registering Tableau Server')
param registration_email string

@description('Company name to use for registering Tableau Server')
param registration_company string

@description('Job title to use for registering Tableau Server')
param registration_title string

@description('Department name to use for registering Tableau Server')
param registration_department string

@description('Industry name to use for registering Tableau Server')
param registration_industry string

@description('Phone number to use for registering Tableau Server')
param registration_phone string

@description('Your current City - to use for registering Tableau Server')
param registration_city string

@description('Your current State - to use for registering Tableau Server')
param registration_state string

@description('Your current zip - to use for registering Tableau Server')
param registration_zip string

@description('Your current Country - to use for registering Tableau Server')
param registration_country string

@description('Enter Tableau Server License key.  ** If you would like to run a 2-week free trial please leave as \'trial\'')
param license_key string = 'trial'

@allowed([
  'Yes'
  'No'
])
@description('Please type \'Yes\' to accept the Tableau EULA which can be found here: https://mkt.tableau.com/files/tableau_eula.pdf. If you type No then the Azure resources will still be deployed but Tableau Server will not be installed.')
param accept_eula string

var virtualNetworkName_var = 'TABVNET'
var NSGName_var = 'TABNSG'
var publicIPAddressType = 'Dynamic'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var numberOfInstances = 1
var virtualMachineSize = VMSize
var linux_os = [
  'Ubuntu 16.04 LTS'
  'CentOS 7.5'
  'RHEL 7.7'
]
var os_is_linux = contains(linux_os, OS)
var imageReference = {
  'Ubuntu 16.04 LTS': {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '16.04.0-LTS'
    version: 'latest'
  }
  'CentOS 7.5': {
    publisher: 'OpenLogic'
    offer: 'CentOS'
    sku: '7.5'
    version: 'latest'
  }
  'RHEL 7.7': {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '7-RAW'
    version: 'latest'
  }
  'Windows 2016-Datacenter': {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2016-Datacenter'
    version: 'latest'
  }
  'Windows 2019-Datacenter': {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2019-Datacenter'
    version: 'latest'
  }
  'Windows 2012-Datacenter': {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2012-Datacenter'
    version: 'latest'
  }
  'Windows 2012-R2-Datacenter': {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2012-R2-Datacenter'
    version: 'latest'
  }
}
var publicIpName = substring(concat(uniqueString(resourceGroup().id, deployment().name)), 0, 6)
var LinuxExecute = '-u \'${adminUsername}\' -p \'${adminPassword}\' -h \'${tableau_admin_username}\' -e \'${tableau_version}\' -i \'${tableau_admin_password}\' -j \'${registration_zip}\' -k \'${registration_country}\' -l \'${registration_city}\' -m \'${registration_last_name}\' -n \'${registration_industry}\' -o yes -q \'${registration_title}\' -r \'${registration_phone}\' -s \'${registration_company}\' -t \'${registration_state}\' -x \'${registration_email}\' -v \'${registration_department}\' -g \'${installscripturi}\' -y \'${license_key}\' -f \'${OS}\' -w \'${registration_first_name}\''
var LinCmdWrapper = 'bash ./config-linux.sh ${LinuxExecute}'
var linuxscripturi = uri(artifactsLocation, 'scripts/config-linux.sh${artifactsLocationSasToken}')
var installscripturi = uri(artifactsLocation, 'scripts/automated-installer${artifactsLocationSasToken}')
var winscriptfile = 'config-win.ps1'
var winscripturi = '${artifactsLocation}scripts/config-win.ps1${artifactsLocationSasToken}'
var WinExecute = '-local_admin_user ${adminUsername} -local_admin_pass ${adminPassword} -ts_admin_un ${tableau_admin_username} -ts_admin_pass ${tableau_admin_password} -reg_zip ${registration_zip} -reg_country ${registration_country} -reg_city ${registration_city} -reg_last_name ${registration_last_name} -reg_industry ${registration_industry} -eula ${accept_eula} -reg_title ${registration_title} -reg_phone ${registration_phone} -reg_company ${registration_company} -reg_state ${registration_state} -reg_email ${registration_email} -reg_department ${registration_department} -install_script_url ${winscripturi} -license_key ${license_key} -reg_first_name ${registration_first_name} -ts_build ${tableau_version}'
var WinCmdWrapper = 'powershell -ExecutionPolicy Unrestricted -File ${winscriptfile} ${WinExecute}'
var win_CSE_properties = {
  publisher: 'Microsoft.Compute'
  type: 'CustomScriptExtension'
  typeHandlerVersion: '1.7'
  autoUpgradeMinorVersion: true
  settings: {
    fileUris: split(winscripturi, ' ')
  }
  protectedSettings: {
    commandToExecute: WinCmdWrapper
  }
}
var lin_CSE_properties = {
  publisher: 'Microsoft.Azure.Extensions'
  type: 'CustomScript'
  typeHandlerVersion: '2.0'
  autoUpgradeMinorVersion: true
  settings: {
    skipDos2Unix: false
    timestamp: 123456789
  }
  protectedSettings: {
    commandToExecute: LinCmdWrapper
    fileUris: [
      linuxscripturi
    ]
  }
}
var LinuxsecurityRules = [
  {
    name: 'ssh-rule'
    properties: {
      description: 'Allow SSH'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '22'
      sourceAddressPrefix: source_CIDR
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 100
      direction: 'Inbound'
    }
  }
  {
    name: 'mngagent-rule'
    properties: {
      description: 'Allow Management'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '8850'
      sourceAddressPrefix: source_CIDR
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 110
      direction: 'Inbound'
    }
  }
  {
    name: 'web-rule'
    properties: {
      description: 'Allow WEB'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '80'
      sourceAddressPrefix: 'Internet'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 120
      direction: 'Inbound'
    }
  }
]
var WindowssecurityRules = [
  {
    name: 'rdp-rule'
    properties: {
      description: 'Allow RDP'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '3389'
      sourceAddressPrefix: source_CIDR
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 100
      direction: 'Inbound'
    }
  }
  {
    name: 'mngagent-rule'
    properties: {
      description: 'Allow Management'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '8850'
      sourceAddressPrefix: source_CIDR
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 110
      direction: 'Inbound'
    }
  }
  {
    name: 'web-rule'
    properties: {
      description: 'Allow WEB'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '80'
      sourceAddressPrefix: 'Internet'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 120
      direction: 'Inbound'
    }
  }
]

module pid_6c922c23_cc65_4b76_8290_74feb0f3c476 './nested_pid_6c922c23_cc65_4b76_8290_74feb0f3c476.bicep' = {
  name: 'pid-6c922c23-cc65-4b76-8290-74feb0f3c476'
  params: {}
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2019-04-01' = {
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
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
          networkSecurityGroup: {
            id: NSGName.id
          }
        }
      }
    ]
  }
}

resource NSGName 'Microsoft.Network/networkSecurityGroups@2019-04-01' = {
  name: NSGName_var
  location: location
  tags: {
    displayName: NSGName_var
  }
  properties: {
    securityRules: (os_is_linux ? LinuxsecurityRules : WindowssecurityRules)
  }
}

resource tabpip_1 'Microsoft.Network/publicIPAddresses@2019-04-01' = [for i in range(0, numberOfInstances): {
  name: 'tabpip${(i + 1)}'
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: 'a${publicIpName}${(i + 1)}'
    }
  }
  dependsOn: [
    virtualNetworkName
  ]
}]

resource tabnic_1 'Microsoft.Network/networkInterfaces@2019-04-01' = [for i in range(0, numberOfInstances): {
  name: 'tabnic${(i + 1)}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses/', 'tabpip${(i + 1)}')
          }
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnet1Name)
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
    tabpip_1
  ]
}]

resource tableau_1 'Microsoft.Compute/virtualMachines@2019-07-01' = [for i in range(0, numberOfInstances): {
  name: 'tableau${(i + 1)}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    osProfile: {
      computerName: 'tableauvm${(i + 1)}'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: imageReference[OS]
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [for j in range(0, 1): {
        diskSizeGB: 64
        lun: j
        createOption: 'Empty'
      }]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'tabnic${(i + 1)}')
        }
      ]
    }
  }
  dependsOn: [
    tabnic_1
  ]
}]

resource tableau_1_CustomScript 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = [for i in range(0, numberOfInstances): if (accept_eula == 'Yes') {
  name: 'tableau${(i + 1)}/CustomScript'
  location: location
  tags: {
    displayName: 'customscriptextension'
  }
  properties: (os_is_linux ? lin_CSE_properties : win_CSE_properties)
  dependsOn: [
    resourceId('Microsoft.Compute/virtualMachines', 'tableau${(i + 1)}')
  ]
}]