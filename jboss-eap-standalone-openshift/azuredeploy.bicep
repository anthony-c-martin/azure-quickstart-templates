@minLength(1)
@description('User name for the Virtual Machine and OpenShift Webconsole.')
param adminUsername string

@description('User password for the OpenShift Webconsole')
@secure()
param openshiftPassword string

@description('DNS Label for the Public IP. Must be lowercase. It should match with the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$ or it will raise an error.')
param dnsLabelPrefix string

@description('Red Hat Subscription Manager User')
param rhsmUser string

@description('Red Hat Subscription Manager Password')
@secure()
param rhsmPassword string

@description('Red Hat Subscription Manager Pool (must contain OpenShift entitlement).')
param rhsmPool string

@description('SSH RSA public key file as a string.')
@secure()
param sshKeyData string

@allowed([
  'Standard_D4_v3'
  'Standard_D8_v3'
  'Standard_DS4_v2'
  'Standard_DS4_v3'
  'Standard_DS8_v3'
  'Standard_DS16_v3'
])
@description('The size of the Virtual Machine.')
param vmSize string = 'Standard_D4_v3'

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/jboss-eap-standalone-openshift/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

var ScriptFolder = 'scripts'
var ScriptFileName = 'allinone.sh'
var virtualNetworkName_var = 'openshiftVnet'
var addressPrefix = '10.0.0.0/16'
var nicName_var = 'OneVmNic'
var publicIPAddressName_var = 'onevmPublicIP'
var subnetName = 'openshiftVsnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var sshKeyPath = '/home/${adminUsername}/.ssh/authorized_keys'
var singlequote = '\''
var escapedQuote = '"'

resource name 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: resourceGroup().name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: resourceGroup().name
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: 'true'
        ssh: {
          publicKeys: [
            {
              path: sshKeyPath
              keyData: sshKeyData
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'RedHat'
        offer: 'RHEL'
        sku: '7-RAW'
        version: 'latest'
      }
      osDisk: {
        caching: 'ReadWrite'
        name: 'osdisk'
        createOption: 'FromImage'
        diskSizeGB: '128'
      }
      dataDisks: [
        {
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: '128'
          lun: 0
          name: 'datadisk0'
        }
        {
          caching: 'None'
          createOption: 'Empty'
          diskSizeGB: '128'
          lun: 1
          name: 'datadisk1'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName.id
        }
      ]
    }
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2018-04-01' = {
  name: nicName_var
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
    virtualNetworkName
  ]
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2018-04-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2018-04-01' = {
  name: virtualNetworkName_var
  location: location
  tags: {
    displayName: 'VirtualNetwork'
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
          addressPrefix: addressPrefix
        }
      }
    ]
  }
}

resource name_installcustomscript 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = {
  name: '${resourceGroup().name}/installcustomscript'
  location: location
  tags: {
    displayName: 'VirtualMachineCustomScriptExtension'
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, '${ScriptFolder}/${ScriptFileName}${artifactsLocationSasToken}')
      ]
    }
    protectedSettings: {
      commandToExecute: 'bash allinone.sh  ${resourceGroup().name} ${dnsLabelPrefix} ${adminUsername} ${singlequote}${openshiftPassword}${singlequote} ${reference(publicIPAddressName_var).dnsSettings.fqdn} ${rhsmUser} ${singlequote}${rhsmPassword}${singlequote} ${rhsmPool} ${reference('onevmPublicIP').ipAddress}${escapedQuote}${sshKeyData}${escapedQuote}'
    }
  }
  dependsOn: [
    name
  ]
}

resource name_nsg 'Microsoft.Network/networkSecurityGroups@2018-04-01' = {
  name: '${resourceGroup().name}nsg'
  tags: {
    displayName: 'NetworkSecurityGroup'
  }
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-openshift-router-https'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 2000
          direction: 'Inbound'
        }
      }
      {
        name: 'default-allow-openshift-router-http'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 2001
          direction: 'Inbound'
        }
      }
      {
        name: 'default-allow-openshift-master'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 2002
          direction: 'Inbound'
        }
      }
      {
        name: 'default-allow-ssh'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 2003
          direction: 'Inbound'
        }
      }
    ]
  }
}

output sshCommand string = 'ssh ${adminUsername}@${reference(publicIPAddressName_var).dnsSettings.fqdn}'
output OpenshiftConsole string = 'https://${reference(publicIPAddressName_var).dnsSettings.fqdn}:8443'
output publicIP string = reference('onevmPublicIP').ipAddress