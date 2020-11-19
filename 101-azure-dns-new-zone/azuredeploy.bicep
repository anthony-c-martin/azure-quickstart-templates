param newZoneName string {
  metadata: {
    description: 'The name of the DNS zone to be created.  Must have at least 2 segements, e.g. hostname.org'
  }
  default: '${uniqueString(resourceGroup().id)}.azurequickstart.org'
}
param newRecordName string {
  metadata: {
    description: 'The name of the DNS record to be created.  The name is relative to the zone, not the FQDN.'
  }
  default: 'www'
}

resource newZoneName_resource 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: newZoneName
  location: 'global'
}

resource newZoneName_newRecordName 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  name: '${newZoneName}/${newRecordName}'
  location: 'global'
  properties: {
    TTL: 3600
    ARecords: [
      {
        ipv4Address: '1.2.3.4'
      }
      {
        ipv4Address: '1.2.3.5'
      }
    ]
  }
  dependsOn: [
    newZoneName_resource
  ]
}

output nameServers array = reference(newZoneName).nameServers