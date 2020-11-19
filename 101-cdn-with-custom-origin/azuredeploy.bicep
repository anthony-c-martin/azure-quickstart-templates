param profileName string {
  metadata: {
    description: 'Name of the CDN Profile'
  }
  default: 'myCDNProfile'
}
param endpointName string {
  metadata: {
    description: 'Name of the CDN Endpoint, must be unique'
  }
}
param originUrl string {
  metadata: {
    description: 'Url of the origin'
  }
}
param CDNSku string {
  allowed: [
    'Standard_Akamai'
    'Standard_Microsoft'
    'Standard_Verizon'
    'Premium_Verizon'
  ]
  metadata: {
    description: 'CDN SKU names'
  }
  default: 'Standard_Microsoft'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource profileName_resource 'Microsoft.Cdn/profiles@2020-04-15' = {
  name: profileName
  location: location
  sku: {
    name: CDNSku
  }
}

resource profileName_endpointName 'Microsoft.Cdn/profiles/endpoints@2020-04-15' = {
  name: '${profileName}/${endpointName}'
  location: location
  properties: {
    originHostHeader: originUrl
    isHttpAllowed: true
    isHttpsAllowed: true
    queryStringCachingBehavior: 'IgnoreQueryString'
    contentTypesToCompress: [
      'application/eot'
      'application/font'
      'application/font-sfnt'
      'application/javascript'
      'application/json'
      'application/opentype'
      'application/otf'
      'application/pkcs7-mime'
      'application/truetype'
      'application/ttf'
      'application/vnd.ms-fontobject'
      'application/xhtml+xml'
      'application/xml'
      'application/xml+rss'
      'application/x-font-opentype'
      'application/x-font-truetype'
      'application/x-font-ttf'
      'application/x-httpd-cgi'
      'application/x-javascript'
      'application/x-mpegurl'
      'application/x-opentype'
      'application/x-otf'
      'application/x-perl'
      'application/x-ttf'
      'font/eot'
      'font/ttf'
      'font/otf'
      'font/opentype'
      'image/svg+xml'
      'text/css'
      'text/csv'
      'text/html'
      'text/javascript'
      'text/js'
      'text/plain'
      'text/richtext'
      'text/tab-separated-values'
      'text/xml'
      'text/x-script'
      'text/x-component'
      'text/x-java-source'
    ]
    isCompressionEnabled: true
    origins: [
      {
        name: 'origin1'
        properties: {
          hostName: originUrl
        }
      }
    ]
  }
  dependsOn: [
    profileName_resource
  ]
}