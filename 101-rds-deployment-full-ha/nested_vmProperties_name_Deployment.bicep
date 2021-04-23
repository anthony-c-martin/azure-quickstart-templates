param projectName string
param location string
param timeZoneID string
param loopCount int
param storageDiagUrl string
param vmName string
param subNetRef string
param vmSize string
param vmSpot bool
param vmStorageSkuType string
param adminUser string

@secure()
param adminPasswd string
param intLbName string
param intLbBackEndPool string
param intLbBrokerIP string
param intLbWebGWIP string
param pubLbName string
param pubLbBackEndPool string
param adDomainName string
param firstDcIP string
param dcName string
param MainConnectionBroker string
param WebAccessServerName string
param WebAccessServerCount int
param SessionHostName string
param SessionHostCount int
param LicenseServerName string
param LicenseServerCount int
param externalFqdn string
param brokerFqdn string
param externalDnsZone string
param dscFunction string
param dscLocation string
param dscScriptName string
param scriptName string
param deployHA bool
param rdsDBName string
param azureSQLFqdn string
param webGwName string

@secure()
param artifactsLocationSasToken string

var scriptPath = uri(dscLocation, 'scripts/${scriptName}${artifactsLocationSasToken}')
var intlbPool = [
  {
    id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', intLbName, intLbBackEndPool)
  }
]
var pubIntlbPool = [
  {
    id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', intLbName, intLbBackEndPool)
  }
  {
    id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', pubLbName, pubLbBackEndPool)
  }
]
var intlbRef = resourceId(location, 'Microsoft.Network/loadBalancers', intLbName)

resource vmName_1_pip 'Microsoft.Network/publicIPAddresses@2019-12-01' = [for i in range(0, loopCount): {
  name: '${vmName}${(i + 1)}pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: '${vmName}pip${(i + 1)}'
    }
  }
}]

resource vmName_1_nic1 'Microsoft.Network/networkInterfaces@2019-12-01' = [for i in range(0, loopCount): {
  location: location
  name: '${vmName}${(i + 1)}nic1'
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: subNetRef
          }
          privateIPAllocationMethod: ((vmName == dcName) ? (((i + 1) == 1) ? 'static' : 'dynamic') : 'dynamic')
          privateIPAddress: ((vmName == dcName) ? (((i + 1) == 1) ? firstDcIP : json('null')) : json('null'))
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', '${vmName}${(i + 1)}pip')
          }
          loadBalancerBackendAddressPools: ((!empty(intLbBackEndPool)) ? ((!empty(pubLbBackEndPool)) ? pubIntlbPool : intlbPool) : json('null'))
        }
      }
    ]
  }
  dependsOn: [
    resourceId('Microsoft.Network/publicIPAddresses', '${vmName}${(i + 1)}pip')
  ]
}]

resource vmName_1 'Microsoft.Compute/virtualMachines@2019-07-01' = [for i in range(0, loopCount): {
  name: concat(vmName, (i + 1))
  location: location
  properties: {
    licenseType: 'Windows_Server'
    billingProfile: {
      maxPrice: ((vmSpot == bool('true')) ? '-1' : json('null'))
    }
    priority: ((vmSpot == bool('true')) ? 'Spot' : json('null'))
    evictionPolicy: ((vmSpot == bool('true')) ? 'Deallocate' : json('null'))
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageDiagUrl
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${vmName}${(i + 1)}nic1')
        }
      ]
    }
    osProfile: {
      adminUsername: adminUser
      adminPassword: adminPasswd
      computerName: concat(vmName, (i + 1))
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: vmStorageSkuType
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
    }
  }
  dependsOn: [
    resourceId('Microsoft.Network/networkInterfaces', '${vmName}${(i + 1)}nic1')
  ]
}]

resource vmName_1_dscext 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = [for i in range(0, loopCount): if (!empty(dscFunction)) {
  name: '${vmName}${(i + 1)}/dscext'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.11'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: uri(dscLocation, 'dsc/${dscScriptName}${artifactsLocationSasToken}')
      ConfigurationFunction: dscFunction
      Properties: {
        AdminCreds: {
          UserName: adminUser
          Password: 'PrivateSettingsRef:AdminPassword'
        }
        RDSParameters: [
          {
            timeZoneID: timeZoneID
            DomainName: adDomainName
            DNSServer: firstDcIP
            MainConnectionBroker: MainConnectionBroker
            WebAccessServer: '${WebAccessServerName}1'
            SessionHost: '${SessionHostName}1'
            LicenseServer: '${LicenseServerName}1'
            externalFqdn: externalFqdn
            externalDnsDomain: externalDnsZone
            IntBrokerLBIP: intLbBrokerIP
            IntWebGWLBIP: intLbWebGWIP
            WebGWDNS: webGwName
          }
        ]
      }
    }
    protectedSettings: {
      Items: {
        AdminPassword: adminPasswd
      }
    }
  }
  dependsOn: [
    resourceId('Microsoft.Compute/virtualMachines', concat(vmName, (i + 1)))
  ]
}]

resource vmName_1_pwshext 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = [for i in range(0, loopCount): if (contains(vmName, 'cb') && deployHA) {
  name: '${vmName}${(i + 1)}/pwshext'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        scriptPath
      ]
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Bypass -File ./${scriptName} -AdminUser ${adminUser} -Passwd ${adminPasswd} -MainConnectionBroker ${MainConnectionBroker} -BrokerFqdn ${brokerFqdn} -WebGatewayFqdn ${externalFqdn} -AzureSQLFQDN ${azureSQLFqdn} -AzureSQLDBName ${rdsDBName} -WebAccessServerName ${WebAccessServerName} -WebAccessServerCount ${WebAccessServerCount} -SessionHostName ${SessionHostName} -SessionHostCount ${SessionHostCount} -LicenseServerName ${LicenseServerName} -LicenseServerCount ${LicenseServerCount}'
    }
  }
  dependsOn: [
    resourceId('Microsoft.Compute/virtualMachines', concat(vmName, (i + 1)))
    resourceId('Microsoft.Compute/virtualMachines/extensions', concat(vmName, (i + 1)), 'dscext')
  ]
}]