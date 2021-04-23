@description('batch acount name')
param batchservice string

@description('certificate securestring reference to keyvault')
@secure()
param certdata string

@description('keyvault certificate thumbprint')
@secure()
param certthumbprint string

@description('keyvault certificate pfx password')
param certpassword string

var certname_var = '${batchservice}/SHA1-${certthumbprint}'

resource certname 'Microsoft.Batch/batchAccounts/certificates@2019-04-01' = {
  name: certname_var
  properties: {
    format: 'Pfx'
    thumbprint: certthumbprint
    thumbprintAlgorithm: 'SHA1'
    data: certdata
    password: certpassword
  }
}