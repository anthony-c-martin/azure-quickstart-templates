param contosoIntegrationAccountName string {
  minLength: 1
  maxLength: 80
  metadata: {
    description: 'Name of the Integration Account.'
  }
  default: 'ContosoIntegrationAccount'
}
param fabrikamIntegrationAccountName string {
  minLength: 1
  maxLength: 80
  metadata: {
    description: 'Name of the Integration Account.'
  }
  default: 'FabrikamIntegrationAccount'
}
param contosoAS2ReceiveLogicAppName string {
  minLength: 1
  maxLength: 80
  metadata: {
    description: 'Name of the Logic App.'
  }
  default: 'Contoso-AS2Receive'
}
param fabrikamSalesAS2SendLogicAppName string {
  minLength: 1
  maxLength: 80
  metadata: {
    description: 'Name of the Logic App.'
  }
  default: 'FabrikamSales-AS2Send'
}
param fabrikamFinanceAS2SendLogicAppName string {
  minLength: 1
  maxLength: 80
  metadata: {
    description: 'Name of the Logic App.'
  }
  default: 'FabrikamFinance-AS2Send'
}
param fabrikamFinanceAS2ReceiveMDNLogicAppName string {
  minLength: 1
  maxLength: 80
  metadata: {
    description: 'Name of the Logic App.'
  }
  default: 'FabrikamFinance-AS2ReceiveMDN'
}
param location string {
  metadata: {
    description: 'Location of the Logic App.'
  }
  default: resourceGroup().location
}
param contoso_AS2_Connection_Name string {
  metadata: {
    description: 'Name of the AS2 connection.'
  }
  default: 'Contoso-AS2'
}
param fabrikam_AS2_Connection_Name string {
  metadata: {
    description: 'Name of the AS2 connection.'
  }
  default: 'Fabrikam-AS2'
}

resource contosoIntegrationAccountName_resource 'Microsoft.Logic/integrationAccounts@2019-05-01' = {
  properties: {}
  sku: {
    name: 'Standard'
  }
  tags: {
    displayName: 'Contoso Integration Account'
  }
  name: contosoIntegrationAccountName
  location: location
}

resource fabrikamIntegrationAccountName_resource 'Microsoft.Logic/integrationAccounts@2019-05-01' = {
  properties: {}
  sku: {
    name: 'Standard'
  }
  tags: {
    displayName: 'Fabrikam Integration Account'
  }
  name: fabrikamIntegrationAccountName
  location: location
}

resource contosoIntegrationAccountName_Contoso 'Microsoft.Logic/integrationAccounts/partners@2016-06-01' = {
  properties: {
    partnerType: 'B2B'
    content: {
      b2b: {
        businessIdentities: [
          {
            qualifier: 'ZZ'
            value: '99'
          }
          {
            qualifier: 'AS2Identity'
            value: 'Contoso'
          }
        ]
      }
    }
  }
  name: '${contosoIntegrationAccountName}/Contoso'
  dependsOn: [
    contosoIntegrationAccountName_resource
  ]
}

resource fabrikamIntegrationAccountName_Contoso 'Microsoft.Logic/integrationAccounts/partners@2016-06-01' = {
  properties: {
    partnerType: 'B2B'
    content: {
      b2b: {
        businessIdentities: [
          {
            qualifier: 'ZZ'
            value: '99'
          }
          {
            qualifier: 'AS2Identity'
            value: 'Contoso'
          }
        ]
      }
    }
  }
  name: '${fabrikamIntegrationAccountName}/Contoso'
  dependsOn: [
    fabrikamIntegrationAccountName_resource
  ]
}

resource contosoIntegrationAccountName_FabrikamSales 'Microsoft.Logic/integrationAccounts/partners@2016-06-01' = {
  properties: {
    partnerType: 'B2B'
    content: {
      b2b: {
        businessIdentities: [
          {
            qualifier: 'ZZ'
            value: '98'
          }
          {
            qualifier: 'AS2Identity'
            value: 'FabrikamSales'
          }
        ]
      }
    }
  }
  name: '${contosoIntegrationAccountName}/FabrikamSales'
  dependsOn: [
    contosoIntegrationAccountName_resource
  ]
}

resource fabrikamIntegrationAccountName_FabrikamSales 'Microsoft.Logic/integrationAccounts/partners@2016-06-01' = {
  properties: {
    partnerType: 'B2B'
    content: {
      b2b: {
        businessIdentities: [
          {
            qualifier: 'ZZ'
            value: '98'
          }
          {
            qualifier: 'AS2Identity'
            value: 'FabrikamSales'
          }
        ]
      }
    }
  }
  name: '${fabrikamIntegrationAccountName}/FabrikamSales'
  dependsOn: [
    fabrikamIntegrationAccountName_resource
  ]
}

resource contosoIntegrationAccountName_FabrikamFinance 'Microsoft.Logic/integrationAccounts/partners@2016-06-01' = {
  properties: {
    partnerType: 'B2B'
    content: {
      b2b: {
        businessIdentities: [
          {
            qualifier: 'ZZ'
            value: '97'
          }
          {
            qualifier: 'AS2Identity'
            value: 'FabrikamFinance'
          }
        ]
      }
    }
  }
  name: '${contosoIntegrationAccountName}/FabrikamFinance'
  dependsOn: [
    contosoIntegrationAccountName_resource
  ]
}

resource fabrikamIntegrationAccountName_FabrikamFinance 'Microsoft.Logic/integrationAccounts/partners@2016-06-01' = {
  properties: {
    partnerType: 'B2B'
    content: {
      b2b: {
        businessIdentities: [
          {
            qualifier: 'ZZ'
            value: '97'
          }
          {
            qualifier: 'AS2Identity'
            value: 'FabrikamFinance'
          }
        ]
      }
    }
  }
  name: '${fabrikamIntegrationAccountName}/FabrikamFinance'
  dependsOn: [
    fabrikamIntegrationAccountName_resource
  ]
}

resource contosoIntegrationAccountName_Contoso_FabrikamSales 'Microsoft.Logic/integrationAccounts/agreements@2016-06-01' = {
  properties: {
    hostPartner: 'Contoso'
    guestPartner: 'FabrikamSales'
    hostIdentity: {
      qualifier: 'AS2Identity'
      value: 'Contoso'
    }
    guestIdentity: {
      qualifier: 'AS2Identity'
      value: 'FabrikamSales'
    }
    agreementType: 'AS2'
    content: {
      aS2: {
        receiveAgreement: {
          protocolSettings: {
            messageConnectionSettings: {
              ignoreCertificateNameMismatch: false
              supportHttpStatusCodeContinue: true
              keepHttpConnectionAlive: true
              unfoldHttpHeaders: true
            }
            acknowledgementConnectionSettings: {
              ignoreCertificateNameMismatch: false
              supportHttpStatusCodeContinue: false
              keepHttpConnectionAlive: false
              unfoldHttpHeaders: false
            }
            mdnSettings: {
              needMDN: false
              signMDN: false
              sendMDNAsynchronously: false
              dispositionNotificationTo: 'http://localhost'
              signOutboundMDNIfOptional: false
              sendInboundMDNToMessageBox: true
              micHashingAlgorithm: 'SHA2256'
            }
            securitySettings: {
              overrideGroupSigningCertificate: false
              enableNRRForInboundEncodedMessages: false
              enableNRRForInboundDecodedMessages: false
              enableNRRForOutboundMDN: false
              enableNRRForOutboundEncodedMessages: false
              enableNRRForOutboundDecodedMessages: false
              enableNRRForInboundMDN: false
            }
            validationSettings: {
              overrideMessageProperties: false
              encryptMessage: false
              signMessage: false
              compressMessage: false
              checkDuplicateMessage: false
              interchangeDuplicatesValidityDays: 5
              checkCertificateRevocationListOnSend: false
              checkCertificateRevocationListOnReceive: false
              encryptionAlgorithm: 'DES3'
            }
            envelopeSettings: {
              messageContentType: 'text/plain'
              transmitFileNameInMimeHeader: false
              fileNameTemplate: '%FILE().ReceivedFileName%'
              suspendMessageOnFileNameGenerationError: true
              autogenerateFileName: false
            }
            errorSettings: {
              suspendDuplicateMessage: false
              resendIfMDNNotReceived: false
            }
          }
          senderBusinessIdentity: {
            qualifier: 'AS2Identity'
            value: 'FabrikamSales'
          }
          receiverBusinessIdentity: {
            qualifier: 'AS2Identity'
            value: 'Contoso'
          }
        }
        sendAgreement: {
          protocolSettings: {
            messageConnectionSettings: {
              ignoreCertificateNameMismatch: false
              supportHttpStatusCodeContinue: true
              keepHttpConnectionAlive: true
              unfoldHttpHeaders: true
            }
            acknowledgementConnectionSettings: {
              ignoreCertificateNameMismatch: false
              supportHttpStatusCodeContinue: false
              keepHttpConnectionAlive: false
              unfoldHttpHeaders: false
            }
            mdnSettings: {
              needMDN: false
              signMDN: false
              sendMDNAsynchronously: false
              dispositionNotificationTo: 'http://localhost'
              signOutboundMDNIfOptional: false
              sendInboundMDNToMessageBox: true
              micHashingAlgorithm: 'SHA2256'
            }
            securitySettings: {
              overrideGroupSigningCertificate: false
              enableNRRForInboundEncodedMessages: false
              enableNRRForInboundDecodedMessages: false
              enableNRRForOutboundMDN: false
              enableNRRForOutboundEncodedMessages: false
              enableNRRForOutboundDecodedMessages: false
              enableNRRForInboundMDN: false
            }
            validationSettings: {
              overrideMessageProperties: false
              encryptMessage: false
              signMessage: false
              compressMessage: false
              checkDuplicateMessage: false
              interchangeDuplicatesValidityDays: 5
              checkCertificateRevocationListOnSend: false
              checkCertificateRevocationListOnReceive: false
              encryptionAlgorithm: 'DES3'
            }
            envelopeSettings: {
              messageContentType: 'text/plain'
              transmitFileNameInMimeHeader: false
              fileNameTemplate: '%FILE().ReceivedFileName%'
              suspendMessageOnFileNameGenerationError: true
              autogenerateFileName: false
            }
            errorSettings: {
              suspendDuplicateMessage: false
              resendIfMDNNotReceived: false
            }
          }
          senderBusinessIdentity: {
            qualifier: 'AS2Identity'
            value: 'Contoso'
          }
          receiverBusinessIdentity: {
            qualifier: 'AS2Identity'
            value: 'FabrikamSales'
          }
        }
      }
    }
  }
  name: '${contosoIntegrationAccountName}/Contoso-FabrikamSales'
  dependsOn: [
    contosoIntegrationAccountName_resource
  ]
}

resource fabrikamIntegrationAccountName_FabrikamSales_Contoso 'Microsoft.Logic/integrationAccounts/agreements@2016-06-01' = {
  properties: {
    hostPartner: 'FabrikamSales'
    guestPartner: 'Contoso'
    hostIdentity: {
      qualifier: 'AS2Identity'
      value: 'FabrikamSales'
    }
    guestIdentity: {
      qualifier: 'AS2Identity'
      value: 'Contoso'
    }
    agreementType: 'AS2'
    content: {
      aS2: {
        receiveAgreement: {
          protocolSettings: {
            messageConnectionSettings: {
              ignoreCertificateNameMismatch: false
              supportHttpStatusCodeContinue: true
              keepHttpConnectionAlive: true
              unfoldHttpHeaders: true
            }
            acknowledgementConnectionSettings: {
              ignoreCertificateNameMismatch: false
              supportHttpStatusCodeContinue: false
              keepHttpConnectionAlive: false
              unfoldHttpHeaders: false
            }
            mdnSettings: {
              needMDN: false
              signMDN: false
              sendMDNAsynchronously: false
              dispositionNotificationTo: 'http://localhost'
              signOutboundMDNIfOptional: false
              sendInboundMDNToMessageBox: true
              micHashingAlgorithm: 'SHA2256'
            }
            securitySettings: {
              overrideGroupSigningCertificate: false
              enableNRRForInboundEncodedMessages: false
              enableNRRForInboundDecodedMessages: false
              enableNRRForOutboundMDN: false
              enableNRRForOutboundEncodedMessages: false
              enableNRRForOutboundDecodedMessages: false
              enableNRRForInboundMDN: false
            }
            validationSettings: {
              overrideMessageProperties: false
              encryptMessage: false
              signMessage: false
              compressMessage: false
              checkDuplicateMessage: false
              interchangeDuplicatesValidityDays: 5
              checkCertificateRevocationListOnSend: false
              checkCertificateRevocationListOnReceive: false
              encryptionAlgorithm: 'DES3'
            }
            envelopeSettings: {
              messageContentType: 'text/plain'
              transmitFileNameInMimeHeader: false
              fileNameTemplate: '%FILE().ReceivedFileName%'
              suspendMessageOnFileNameGenerationError: true
              autogenerateFileName: false
            }
            errorSettings: {
              suspendDuplicateMessage: false
              resendIfMDNNotReceived: false
            }
          }
          senderBusinessIdentity: {
            qualifier: 'AS2Identity'
            value: 'Contoso'
          }
          receiverBusinessIdentity: {
            qualifier: 'AS2Identity'
            value: 'FabrikamSales'
          }
        }
        sendAgreement: {
          protocolSettings: {
            messageConnectionSettings: {
              ignoreCertificateNameMismatch: false
              supportHttpStatusCodeContinue: true
              keepHttpConnectionAlive: true
              unfoldHttpHeaders: true
            }
            acknowledgementConnectionSettings: {
              ignoreCertificateNameMismatch: false
              supportHttpStatusCodeContinue: false
              keepHttpConnectionAlive: false
              unfoldHttpHeaders: false
            }
            mdnSettings: {
              needMDN: true
              signMDN: false
              sendMDNAsynchronously: false
              dispositionNotificationTo: 'http://localhost'
              signOutboundMDNIfOptional: false
              sendInboundMDNToMessageBox: true
              micHashingAlgorithm: 'SHA2256'
            }
            securitySettings: {
              overrideGroupSigningCertificate: false
              enableNRRForInboundEncodedMessages: false
              enableNRRForInboundDecodedMessages: false
              enableNRRForOutboundMDN: false
              enableNRRForOutboundEncodedMessages: false
              enableNRRForOutboundDecodedMessages: false
              enableNRRForInboundMDN: false
            }
            validationSettings: {
              overrideMessageProperties: false
              encryptMessage: false
              signMessage: false
              compressMessage: false
              checkDuplicateMessage: false
              interchangeDuplicatesValidityDays: 5
              checkCertificateRevocationListOnSend: false
              checkCertificateRevocationListOnReceive: false
              encryptionAlgorithm: 'DES3'
            }
            envelopeSettings: {
              messageContentType: 'text/plain'
              transmitFileNameInMimeHeader: false
              fileNameTemplate: '%FILE().ReceivedFileName%'
              suspendMessageOnFileNameGenerationError: true
              autogenerateFileName: false
            }
            errorSettings: {
              suspendDuplicateMessage: false
              resendIfMDNNotReceived: false
            }
          }
          senderBusinessIdentity: {
            qualifier: 'AS2Identity'
            value: 'FabrikamSales'
          }
          receiverBusinessIdentity: {
            qualifier: 'AS2Identity'
            value: 'Contoso'
          }
        }
      }
    }
  }
  name: '${fabrikamIntegrationAccountName}/FabrikamSales-Contoso'
  dependsOn: [
    fabrikamIntegrationAccountName_resource
  ]
}

resource contosoIntegrationAccountName_Contoso_FabrikamFinance 'Microsoft.Logic/integrationAccounts/agreements@2016-06-01' = {
  properties: {
    hostPartner: 'Contoso'
    guestPartner: 'FabrikamFinance'
    hostIdentity: {
      qualifier: 'AS2Identity'
      value: 'Contoso'
    }
    guestIdentity: {
      qualifier: 'AS2Identity'
      value: 'FabrikamFinance'
    }
    agreementType: 'AS2'
    content: {
      aS2: {
        receiveAgreement: {
          protocolSettings: {
            messageConnectionSettings: {
              ignoreCertificateNameMismatch: false
              supportHttpStatusCodeContinue: true
              keepHttpConnectionAlive: true
              unfoldHttpHeaders: true
            }
            acknowledgementConnectionSettings: {
              ignoreCertificateNameMismatch: false
              supportHttpStatusCodeContinue: false
              keepHttpConnectionAlive: false
              unfoldHttpHeaders: false
            }
            mdnSettings: {
              needMDN: false
              signMDN: false
              sendMDNAsynchronously: false
              dispositionNotificationTo: 'http://localhost'
              signOutboundMDNIfOptional: false
              sendInboundMDNToMessageBox: true
              micHashingAlgorithm: 'SHA2256'
            }
            securitySettings: {
              overrideGroupSigningCertificate: false
              enableNRRForInboundEncodedMessages: false
              enableNRRForInboundDecodedMessages: false
              enableNRRForOutboundMDN: false
              enableNRRForOutboundEncodedMessages: false
              enableNRRForOutboundDecodedMessages: false
              enableNRRForInboundMDN: false
            }
            validationSettings: {
              overrideMessageProperties: false
              encryptMessage: false
              signMessage: false
              compressMessage: false
              checkDuplicateMessage: false
              interchangeDuplicatesValidityDays: 5
              checkCertificateRevocationListOnSend: false
              checkCertificateRevocationListOnReceive: false
              encryptionAlgorithm: 'DES3'
            }
            envelopeSettings: {
              messageContentType: 'text/plain'
              transmitFileNameInMimeHeader: false
              fileNameTemplate: '%FILE().ReceivedFileName%'
              suspendMessageOnFileNameGenerationError: true
              autogenerateFileName: false
            }
            errorSettings: {
              suspendDuplicateMessage: false
              resendIfMDNNotReceived: false
            }
          }
          senderBusinessIdentity: {
            qualifier: 'AS2Identity'
            value: 'FabrikamFinance'
          }
          receiverBusinessIdentity: {
            qualifier: 'AS2Identity'
            value: 'Contoso'
          }
        }
        sendAgreement: {
          protocolSettings: {
            messageConnectionSettings: {
              ignoreCertificateNameMismatch: false
              supportHttpStatusCodeContinue: true
              keepHttpConnectionAlive: true
              unfoldHttpHeaders: true
            }
            acknowledgementConnectionSettings: {
              ignoreCertificateNameMismatch: false
              supportHttpStatusCodeContinue: false
              keepHttpConnectionAlive: false
              unfoldHttpHeaders: false
            }
            mdnSettings: {
              needMDN: false
              signMDN: false
              sendMDNAsynchronously: false
              dispositionNotificationTo: 'http://localhost'
              signOutboundMDNIfOptional: false
              sendInboundMDNToMessageBox: true
              micHashingAlgorithm: 'SHA2256'
            }
            securitySettings: {
              overrideGroupSigningCertificate: false
              enableNRRForInboundEncodedMessages: false
              enableNRRForInboundDecodedMessages: false
              enableNRRForOutboundMDN: false
              enableNRRForOutboundEncodedMessages: false
              enableNRRForOutboundDecodedMessages: false
              enableNRRForInboundMDN: false
            }
            validationSettings: {
              overrideMessageProperties: false
              encryptMessage: false
              signMessage: false
              compressMessage: false
              checkDuplicateMessage: false
              interchangeDuplicatesValidityDays: 5
              checkCertificateRevocationListOnSend: false
              checkCertificateRevocationListOnReceive: false
              encryptionAlgorithm: 'DES3'
            }
            envelopeSettings: {
              messageContentType: 'text/plain'
              transmitFileNameInMimeHeader: false
              fileNameTemplate: '%FILE().ReceivedFileName%'
              suspendMessageOnFileNameGenerationError: true
              autogenerateFileName: false
            }
            errorSettings: {
              suspendDuplicateMessage: false
              resendIfMDNNotReceived: false
            }
          }
          senderBusinessIdentity: {
            qualifier: 'AS2Identity'
            value: 'Contoso'
          }
          receiverBusinessIdentity: {
            qualifier: 'AS2Identity'
            value: 'FabrikamFinance'
          }
        }
      }
    }
  }
  name: '${contosoIntegrationAccountName}/Contoso-FabrikamFinance'
  dependsOn: [
    contosoIntegrationAccountName_resource
  ]
}

resource contosoAS2ReceiveLogicAppName_resource 'Microsoft.Logic/workflows@2019-05-01' = {
  name: contosoAS2ReceiveLogicAppName
  location: location
  tags: {
    displayName: 'Contoso AS2 Receive'
  }
  properties: {
    state: 'Enabled'
    integrationAccount: {
      id: contosoIntegrationAccountName_resource.id
    }
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      actions: {
        Check_MDN_Expected: {
          type: 'If'
          expression: '@equals(body(\'Decode_AS2_message\')?[\'AS2Message\']?[\'MdnExpected\'], \'Expected\')'
          actions: {
            Check_MDN_Type: {
              type: 'If'
              expression: '@equals(body(\'Decode_AS2_message\')?[\'OutgoingMdn\']?[\'MdnType\'], \'Async\')'
              actions: {
                Send_200_OK_for_Async_MDN: {
                  type: 'Response'
                  inputs: {
                    statusCode: 200
                  }
                }
                Send_Async_MDN: {
                  type: 'Http'
                  inputs: {
                    method: 'POST'
                    uri: '@{body(\'Decode_AS2_message\')?[\'OutgoingMdn\']?[\'ReceiptDeliveryOption\']}'
                    headers: '@body(\'Decode_AS2_message\')?[\'OutgoingMdn\']?[\'OutboundHeaders\']'
                    body: '@base64ToBinary(body(\'Decode_AS2_message\')?[\'OutgoingMdn\']?[\'Content\'])'
                  }
                  runAfter: {
                    Send_200_OK_for_Async_MDN: [
                      'Succeeded'
                    ]
                  }
                }
              }
              else: {
                actions: {
                  Send_Sync_MDN: {
                    type: 'Response'
                    inputs: {
                      statusCode: 200
                      headers: '@body(\'Decode_AS2_message\')?[\'OutgoingMdn\']?[\'OutboundHeaders\']'
                      body: '@base64ToBinary(body(\'Decode_AS2_message\')?[\'OutgoingMdn\']?[\'Content\'])'
                    }
                  }
                }
              }
            }
          }
          runAfter: {
            Decode_AS2_message: [
              'Succeeded'
            ]
          }
          else: {
            actions: {
              Send_200_OK: {
                type: 'Response'
                inputs: {
                  statusCode: 200
                }
              }
            }
          }
        }
        Decode_AS2_message: {
          type: 'ApiConnection'
          inputs: {
            host: {
              api: {
                runtimeUrl: 'https://logic-apis-${location}.azure-apim.net/apim/as2'
              }
              connection: {
                name: '@parameters(\'$connections\')[\'as2\'][\'connectionId\']'
              }
            }
            method: 'post'
            body: '@triggerBody()'
            path: '/decode'
            headers: '@triggerOutputs()[\'headers\']'
          }
        }
      }
      parameters: {
        '$connections': {
          type: 'Object'
        }
      }
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
        }
      }
      contentVersion: '1.0.0.0'
    }
    parameters: {
      '$connections': {
        value: {
          as2: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/as2'
            connectionId: '${resourceGroup().id}/providers/Microsoft.Web/connections/${contoso_AS2_Connection_Name}'
            connectionName: contoso_AS2_Connection_Name
          }
        }
      }
    }
  }
  dependsOn: [
    contosoIntegrationAccountName_resource
    contoso_AS2_Connection_Name_resource
  ]
}

resource fabrikamSalesAS2SendLogicAppName_resource 'Microsoft.Logic/workflows@2019-05-01' = {
  name: fabrikamSalesAS2SendLogicAppName
  location: location
  tags: {
    displayName: 'Fabrikam Sales AS2 Send'
  }
  properties: {
    state: 'Enabled'
    integrationAccount: {
      id: fabrikamIntegrationAccountName_resource.id
    }
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      actions: {
        HTTP: {
          inputs: {
            method: 'POST'
            uri: listCallbackURL('${contosoAS2ReceiveLogicAppName_resource.id}/triggers/manual', '2016-06-01').value
            headers: {
              'AS2-From': 'FabrikamSales'
              'AS2-To': 'Contoso'
              'Message-Id': '@guid()'
              'content-type': 'text/plain'
            }
            body: 'Fabrikam Sales - sample message'
          }
          type: 'Http'
        }
      }
      parameters: {
        '$connections': {
          type: 'Object'
        }
      }
      triggers: {
        Recurrence: {
          recurrence: {
            frequency: 'Hour'
            interval: 1
          }
          type: 'Recurrence'
        }
      }
      contentVersion: '1.0.0.0'
    }
    parameters: {
      '$connections': {
        value: {
          as2: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/as2'
            connectionId: '${resourceGroup().id}/providers/Microsoft.Web/connections/${fabrikam_AS2_Connection_Name}'
            connectionName: fabrikam_AS2_Connection_Name
          }
        }
      }
    }
  }
  dependsOn: [
    fabrikamIntegrationAccountName_resource
    fabrikam_AS2_Connection_Name_resource
    contosoAS2ReceiveLogicAppName_resource
  ]
}

resource fabrikamFinanceAS2SendLogicAppName_resource 'Microsoft.Logic/workflows@2019-05-01' = {
  name: fabrikamFinanceAS2SendLogicAppName
  location: location
  tags: {
    displayName: 'Fabrikam Finance AS2 Send'
  }
  properties: {
    state: 'Enabled'
    integrationAccount: {
      id: fabrikamIntegrationAccountName_resource.id
    }
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      actions: {
        Encode_to_AS2_message: {
          inputs: {
            body: 'Fabrikam Finance - sample message'
            host: {
              api: {
                runtimeUrl: 'https://logic-apis-${location}.azure-apim.net/apim/as2'
              }
              connection: {
                name: '@parameters(\'$connections\')[\'as2\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/encode'
            queries: {
              as2From: 'FabrikamFinance'
              as2To: 'Contoso'
            }
          }
          type: 'ApiConnection'
        }
        HTTP: {
          inputs: {
            body: '@base64ToBinary(body(\'Encode_to_AS2_message\')?[\'AS2Message\']?[\'Content\'])'
            headers: '@body(\'Encode_to_AS2_message\')?[\'AS2Message\']?[\'OutboundHeaders\']'
            method: 'POST'
            uri: listCallbackURL('${contosoAS2ReceiveLogicAppName_resource.id}/triggers/manual', '2016-06-01').value
          }
          runAfter: {
            Encode_to_AS2_message: [
              'Succeeded'
            ]
          }
          type: 'Http'
        }
      }
      parameters: {
        '$connections': {
          type: 'Object'
        }
      }
      triggers: {
        Recurrence: {
          recurrence: {
            frequency: 'Hour'
            interval: 1
          }
          type: 'Recurrence'
        }
      }
      contentVersion: '1.0.0.0'
    }
    parameters: {
      '$connections': {
        value: {
          as2: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/as2'
            connectionId: '${resourceGroup().id}/providers/Microsoft.Web/connections/${fabrikam_AS2_Connection_Name}'
            connectionName: fabrikam_AS2_Connection_Name
          }
        }
      }
    }
  }
  dependsOn: [
    fabrikamIntegrationAccountName_resource
    fabrikam_AS2_Connection_Name_resource
    contosoAS2ReceiveLogicAppName_resource
  ]
}

resource fabrikamFinanceAS2ReceiveMDNLogicAppName_resource 'Microsoft.Logic/workflows@2019-05-01' = {
  name: fabrikamFinanceAS2ReceiveMDNLogicAppName
  location: location
  tags: {
    displayName: 'Fabrikam Finance AS2 Receive MDN'
  }
  properties: {
    state: 'Enabled'
    integrationAccount: {
      id: fabrikamIntegrationAccountName_resource.id
    }
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      actions: {
        Decode_AS2_message: {
          type: 'ApiConnection'
          inputs: {
            host: {
              api: {
                runtimeUrl: 'https://logic-apis-${location}.azure-apim.net/apim/as2'
              }
              connection: {
                name: '@parameters(\'$connections\')[\'as2\'][\'connectionId\']'
              }
            }
            method: 'post'
            body: '@triggerBody()'
            path: '/decode'
            headers: '@triggerOutputs()[\'headers\']'
          }
        }
        Response: {
          inputs: {
            statusCode: 200
          }
          runAfter: {
            Decode_AS2_message: [
              'Succeeded'
            ]
          }
          type: 'Response'
        }
      }
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
        }
      }
      contentVersion: '1.0.0.0'
    }
    parameters: {
      '$connections': {
        value: {
          as2: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/as2'
            connectionId: '${resourceGroup().id}/providers/Microsoft.Web/connections/${fabrikam_AS2_Connection_Name}'
            connectionName: fabrikam_AS2_Connection_Name
          }
        }
      }
    }
  }
  dependsOn: [
    fabrikamIntegrationAccountName_resource
    fabrikam_AS2_Connection_Name_resource
    contosoAS2ReceiveLogicAppName_resource
  ]
}

resource fabrikamIntegrationAccountName_FabrikamFinance_Contoso 'Microsoft.Logic/integrationAccounts/agreements@2016-06-01' = {
  properties: {
    hostPartner: 'FabrikamFinance'
    guestPartner: 'Contoso'
    hostIdentity: {
      qualifier: 'AS2Identity'
      value: 'FabrikamFinance'
    }
    guestIdentity: {
      qualifier: 'AS2Identity'
      value: 'Contoso'
    }
    agreementType: 'AS2'
    content: {
      aS2: {
        receiveAgreement: {
          protocolSettings: {
            messageConnectionSettings: {
              ignoreCertificateNameMismatch: false
              supportHttpStatusCodeContinue: true
              keepHttpConnectionAlive: true
              unfoldHttpHeaders: true
            }
            acknowledgementConnectionSettings: {
              ignoreCertificateNameMismatch: false
              supportHttpStatusCodeContinue: false
              keepHttpConnectionAlive: false
              unfoldHttpHeaders: false
            }
            mdnSettings: {
              needMDN: false
              signMDN: false
              sendMDNAsynchronously: false
              dispositionNotificationTo: 'http://localhost'
              signOutboundMDNIfOptional: false
              sendInboundMDNToMessageBox: true
              micHashingAlgorithm: 'SHA2256'
            }
            securitySettings: {
              overrideGroupSigningCertificate: false
              enableNRRForInboundEncodedMessages: false
              enableNRRForInboundDecodedMessages: false
              enableNRRForOutboundMDN: false
              enableNRRForOutboundEncodedMessages: false
              enableNRRForOutboundDecodedMessages: false
              enableNRRForInboundMDN: false
            }
            validationSettings: {
              overrideMessageProperties: false
              encryptMessage: false
              signMessage: false
              compressMessage: false
              checkDuplicateMessage: false
              interchangeDuplicatesValidityDays: 5
              checkCertificateRevocationListOnSend: false
              checkCertificateRevocationListOnReceive: false
              encryptionAlgorithm: 'DES3'
            }
            envelopeSettings: {
              messageContentType: 'text/plain'
              transmitFileNameInMimeHeader: false
              fileNameTemplate: '%FILE().ReceivedFileName%'
              suspendMessageOnFileNameGenerationError: true
              autogenerateFileName: false
            }
            errorSettings: {
              suspendDuplicateMessage: false
              resendIfMDNNotReceived: false
            }
          }
          senderBusinessIdentity: {
            qualifier: 'AS2Identity'
            value: 'Contoso'
          }
          receiverBusinessIdentity: {
            qualifier: 'AS2Identity'
            value: 'FabrikamFinance'
          }
        }
        sendAgreement: {
          protocolSettings: {
            messageConnectionSettings: {
              ignoreCertificateNameMismatch: false
              supportHttpStatusCodeContinue: true
              keepHttpConnectionAlive: true
              unfoldHttpHeaders: true
            }
            acknowledgementConnectionSettings: {
              ignoreCertificateNameMismatch: false
              supportHttpStatusCodeContinue: false
              keepHttpConnectionAlive: false
              unfoldHttpHeaders: false
            }
            mdnSettings: {
              needMDN: true
              signMDN: false
              sendMDNAsynchronously: true
              receiptDeliveryUrl: listCallbackURL('${fabrikamFinanceAS2ReceiveMDNLogicAppName_resource.id}/triggers/manual', '2016-06-01').value
              dispositionNotificationTo: 'http://localhost'
              signOutboundMDNIfOptional: false
              sendInboundMDNToMessageBox: true
              micHashingAlgorithm: 'SHA2256'
            }
            securitySettings: {
              overrideGroupSigningCertificate: false
              enableNRRForInboundEncodedMessages: false
              enableNRRForInboundDecodedMessages: false
              enableNRRForOutboundMDN: false
              enableNRRForOutboundEncodedMessages: false
              enableNRRForOutboundDecodedMessages: false
              enableNRRForInboundMDN: false
            }
            validationSettings: {
              overrideMessageProperties: false
              encryptMessage: false
              signMessage: false
              compressMessage: false
              checkDuplicateMessage: false
              interchangeDuplicatesValidityDays: 5
              checkCertificateRevocationListOnSend: false
              checkCertificateRevocationListOnReceive: false
              encryptionAlgorithm: 'DES3'
            }
            envelopeSettings: {
              messageContentType: 'text/plain'
              transmitFileNameInMimeHeader: false
              fileNameTemplate: '%FILE().ReceivedFileName%'
              suspendMessageOnFileNameGenerationError: true
              autogenerateFileName: false
            }
            errorSettings: {
              suspendDuplicateMessage: false
              resendIfMDNNotReceived: false
            }
          }
          senderBusinessIdentity: {
            qualifier: 'AS2Identity'
            value: 'FabrikamFinance'
          }
          receiverBusinessIdentity: {
            qualifier: 'AS2Identity'
            value: 'Contoso'
          }
        }
      }
    }
  }
  name: '${fabrikamIntegrationAccountName}/FabrikamFinance-Contoso'
  dependsOn: [
    fabrikamIntegrationAccountName_resource
    fabrikamFinanceAS2ReceiveMDNLogicAppName_resource
  ]
}

resource contoso_AS2_Connection_Name_resource 'Microsoft.Web/connections@2018-07-01-preview' = {
  name: contoso_AS2_Connection_Name
  location: location
  properties: {
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/as2'
    }
    displayName: 'Contoso AS2 connection'
    parameterValues: {
      integrationAccountId: concat(contosoIntegrationAccountName_resource.id)
      integrationAccountUrl: listCallbackURL(concat(contosoIntegrationAccountName_resource.id), '2016-06-01').value
    }
  }
}

resource fabrikam_AS2_Connection_Name_resource 'Microsoft.Web/connections@2018-07-01-preview' = {
  name: fabrikam_AS2_Connection_Name
  location: location
  properties: {
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/as2'
    }
    displayName: 'Fabrikam AS2 connection'
    parameterValues: {
      integrationAccountId: concat(fabrikamIntegrationAccountName_resource.id)
      integrationAccountUrl: listCallbackURL(concat(fabrikamIntegrationAccountName_resource.id), '2016-06-01').value
    }
  }
}