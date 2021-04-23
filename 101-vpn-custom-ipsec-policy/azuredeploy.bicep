@description('Resource Location')
param location string = resourceGroup().location

@description('Name of existing Virtual Network Gateway to deploy the connection to')
param vpnGateway_Name string

@description('Name of existing Local Network Gateway to deploy the connection to')
param localGateway_Name string

@description('Name of the VPN connection between Azure and On-Premises (ex: AzureUKS-to-LDN)')
param vpnName string = 'Azure-to-OnPremises'

@allowed([
  'IKEv1'
  'IKEv2'
])
@description('Protocol utilised by the VPN Connection (IKEv1, IKEv2)')
param vpnProtocol string = 'IKEv2'

@description('Security Association Lifetime (Seconds)')
param saLifeTimeSeconds int = 3600

@description('Security Association Data Size (KB)')
param saDataSizeKilobytes int = 1024000000

@allowed([
  'None'
  'DES'
  'DES3'
  'AES128'
  'AES192'
  'AES256'
  'GCMAES128'
  'GCMAES192'
  'GCMAES256'
])
@description('IPSec Encryption')
param ipsecEncryption string = 'AES256'

@allowed([
  'MD5'
  'SHA1'
  'SHA256'
  'GCMAES128'
  'GCMAES192'
  'GCMAES256'
])
@description('IPSec Integrity')
param ipsecIntegrity string = 'SHA256'

@allowed([
  'DES'
  'DES3'
  'AES128'
  'AES192'
  'AES256'
  'GCMAES256'
  'GCMAES128'
])
@description('IKE Encryption')
param ikeEncryption string = 'AES256'

@allowed([
  'MD5'
  'SHA1'
  'SHA256'
  'SHA384'
  'GCMAES256'
  'GCMAES128'
])
@description('IKE Integrity')
param ikeIntegrity string = 'SHA256'

@allowed([
  'None'
  'DHGroup1'
  'DHGroup2'
  'DHGroup14'
  'DHGroup2048'
  'ECP256'
  'ECP384'
  'DHGroup24'
])
@description('Diffie-Hellman Group')
param dhGroup string = 'DHGroup14'

@allowed([
  'None'
  'PFS1'
  'PFS2'
  'PFS2048'
  'ECP256'
  'ECP384'
  'PFS24'
  'PFS14'
  'PFSMM'
])
@description('Perfect Forward Secrecy Group')
param pfsGroup string = 'PFS14'

@description('Pre-Shared Key')
@secure()
param sharedKey string

@allowed([
  true
  false
])
@description('Enable this if the OnPremises VPN endpoint needs to be configured as a Policy-Based VPN')
param policyBasedTrafficSelectors bool = false

resource vpnName_resource 'Microsoft.Network/connections@2020-04-01' = {
  name: vpnName
  location: location
  properties: {
    virtualNetworkGateway1: {
      id: resourceId('Microsoft.Network/virtualNetworkGateways', vpnGateway_Name)
    }
    localNetworkGateway2: {
      id: resourceId('Microsoft.Network/localNetworkGateways', localGateway_Name)
    }
    connectionType: 'IPsec'
    connectionProtocol: vpnProtocol
    sharedKey: sharedKey
    usePolicyBasedTrafficSelectors: policyBasedTrafficSelectors
    ipsecPolicies: [
      {
        saLifeTimeSeconds: saLifeTimeSeconds
        saDataSizeKilobytes: saDataSizeKilobytes
        ipsecEncryption: ipsecEncryption
        ipsecIntegrity: ipsecIntegrity
        ikeEncryption: ikeEncryption
        ikeIntegrity: ikeIntegrity
        dhGroup: dhGroup
        pfsGroup: pfsGroup
      }
    ]
  }
}