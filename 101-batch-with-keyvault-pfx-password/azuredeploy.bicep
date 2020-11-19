param batchservice string {
  metadata: {
    description: 'batch acount name'
  }
}
param certdata string {
  metadata: {
    description: 'certificate securestring reference to keyvault'
  }
  secure: true
}
param certthumbprint string {
  metadata: {
    description: 'keyvault certificate thumbprint'
  }
  secure: true
}
param certpassword string {
  metadata: {
    description: 'keyvault certificate pfx password'
  }
}

var certname = '${batchservice}/SHA1-${certthumbprint}'

resource certname_resource 'Microsoft.Batch/batchAccounts/certificates@2019-04-01' = {
  name: certname
  properties: {
    format: 'Pfx'
    thumbprint: certthumbprint
    thumbprintAlgorithm: 'SHA1'
    data: certdata
    password: certpassword
  }
}