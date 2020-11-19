param vaultName string {
  metadata: {
    description: 'Specifies the name of the KeyVault, this vault must already exist.'
  }
}
param keyName string {
  metadata: {
    description: 'Specifies the name of the key to be created.'
  }
}
param attributes object {
  metadata: {
    description: 'The attributes of a key managed by the key vault service.'
  }
  default: {}
}
param crv string {
  allowed: [
    ''
    'P-256'
    'P-256K'
    'P-384'
    'P-521'
  ]
  metadata: {
    description: 'Elliptic curve name.'
  }
  default: ''
}
param key_ops array {
  metadata: {
    description: 'JSON web key operations. Operations include: \'encrypt\', \'decrypt\', \'sign\', \'verify\', \'wrapKey\', \'unwrapKey\''
  }
  default: []
}
param key_size int {
  metadata: {
    description: 'The key size in bits. For example: 2048, 3072, or 4096 for RSA.'
  }
  default: 4096
}
param kty string {
  allowed: [
    'EC'
    'EC-HSM'
    'RSA'
    'RSA-HSM'
  ]
  metadata: {
    description: 'The type of key to create'
  }
  default: 'RSA'
}
param tags object {
  metadata: {
    description: 'Tags to be assigned to the Key.'
  }
  default: {}
}

resource vaultName_keyName 'Microsoft.KeyVault/vaults/keys@2019-09-01' = {
  name: '${vaultName}/${keyName}'
  tags: tags
  properties: {
    attributes: attributes
    crv: crv
    kty: kty
    key_ops: key_ops
    key_size: key_size
  }
}

output key object = reference(vaultName_keyName.id, '2019-09-01', 'Full')