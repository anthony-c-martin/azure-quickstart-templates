param integrationAccountName string {
  minLength: 1
  maxLength: 80
  metadata: {
    description: 'Name of the Integration Account.'
  }
  default: 'IntegrationAccount'
}
param logicAppName string {
  minLength: 1
  maxLength: 80
  metadata: {
    description: 'Name of the Logic App.'
  }
  default: 'VETERPipeline'
}
param logicAppLocation string {
  allowed: [
    resourceGroup().location
    'australiaeast'
    'australiasoutheast'
    'brazilsouth'
    'centralus'
    'eastasia'
    'eastus'
    'eastus2'
    'japaneast'
    'japanwest'
    'northcentralus'
    'northeurope'
    'southcentralus'
    'southeastasia'
    'westeurope'
    'westus'
  ]
  metadata: {
    description: 'Location of the Logic App.'
  }
  default: resourceGroup().location
}

resource integrationAccountName_resource 'Microsoft.Logic/integrationAccounts@2016-06-01' = {
  properties: {}
  sku: {
    name: 'Standard'
  }
  name: integrationAccountName
  location: logicAppLocation
}

resource integrationAccountName_Order 'Microsoft.Logic/integrationAccounts/schemas@2016-06-01' = {
  properties: {
    schemaType: 'xml'
    content: '<?xml version="1.0" encoding="utf-8"?><xs:schema xmlns="http://Integration.Order" xmlns:b="https://schemas.microsoft.com/BizTalk/2003" targetNamespace="http://Integration.Order" xmlns:xs="http://www.w3.org/2001/XMLSchema"><xs:element name="Order"><xs:complexType><xs:sequence><xs:element name="Orderheader"><xs:complexType><xs:sequence><xs:element name="OrderDate" type="xs:string" /><xs:element name="EstimatedDeliveryDate" type="xs:string" /><xs:element name="OrderNumber" type="xs:string" /></xs:sequence></xs:complexType></xs:element><xs:element name="CustomDetails"><xs:complexType><xs:sequence><xs:element name="Name" type="xs:string" /><xs:element name="Address" type="xs:string" /></xs:sequence></xs:complexType></xs:element><xs:element name="OrderDetails"><xs:complexType><xs:sequence><xs:element name="ItemDescription" type="xs:string" /><xs:element name="ItemCustomerCode" type="xs:string" /><xs:element name="TotalAmount" type="xs:string" /><xs:element name="UnitType" type="xs:string" /></xs:sequence></xs:complexType></xs:element></xs:sequence></xs:complexType></xs:element></xs:schema>'
    contentType: 'application/xml'
  }
  name: '${integrationAccountName}/Order'
  dependsOn: [
    integrationAccountName_resource
  ]
}

resource integrationAccountName_SAPOrderMap 'Microsoft.Logic/integrationAccounts/maps@2016-06-01' = {
  properties: {
    mapType: 'xslt'
    content: '<?xml version="1.0" encoding="utf-8"?><xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:var="https://schemas.microsoft.com/BizTalk/2003/var" exclude-result-prefixes="msxsl var s0 userCSharp" version="1.0" xmlns:ns0="http://Integration.SAPOrder" xmlns:s0="http://Integration.Order" xmlns:userCSharp="https://schemas.microsoft.com/BizTalk/2003/userCSharp"><xsl:import href="https://az818438.vo.msecnd.net/functoids/functoidsscript.xslt" /><xsl:output omit-xml-declaration="yes" method="xml" version="1.0" /><xsl:template match="/"><xsl:apply-templates select="/s0:Order" /></xsl:template><xsl:template match="/s0:Order"><xsl:variable name="var:v1" select="userCSharp:DateCurrentDateTime()" /><ns0:SAPOrder><OrderId><xsl:value-of select="Orderheader/OrderNumber/text()" /></OrderId><ClientId><xsl:text>1</xsl:text></ClientId><Dates><ProcessDate><xsl:value-of select="$var:v1" /></ProcessDate><OrderDate><xsl:value-of select="Orderheader/OrderDate/text()" /></OrderDate><EstimatedDeliveryDate><xsl:value-of select="Orderheader/EstimatedDeliveryDate/text()" /></EstimatedDeliveryDate></Dates><Details><ItemId><xsl:value-of select="OrderDetails/ItemCustomerCode/text()" /></ItemId><Units><xsl:value-of select="OrderDetails/TotalAmount/text()" /></Units><UnitType><xsl:value-of select="OrderDetails/UnitType/text()" /></UnitType></Details></ns0:SAPOrder></xsl:template></xsl:stylesheet>'
    contentType: 'application/xml'
  }
  name: '${integrationAccountName}/SAPOrderMap'
  dependsOn: [
    integrationAccountName_resource
  ]
}

resource logicAppName_resource 'Microsoft.Logic/workflows@2016-06-01' = {
  name: logicAppName
  location: logicAppLocation
  tags: {
    displayName: 'LogicApp'
  }
  properties: {
    state: 'Enabled'
    integrationAccount: {
      id: integrationAccountName_resource.id
    }
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      actions: {
        Condition: {
          actions: {
            Response: {
              inputs: {
                body: '@body(\'Transform_XML\')'
                statusCode: 200
              }
              runAfter: {}
              type: 'Response'
            }
          }
          expression: '@equals(xpath(xml(body(\'Transform_XML\')), \'string(count(/.))\'), \'1\')'
          runAfter: {
            Transform_XML: [
              'Succeeded'
            ]
          }
          type: 'If'
        }
        Transform_XML: {
          inputs: {
            content: '@{triggerBody()}'
            integrationAccount: {
              map: {
                name: 'SAPOrderMap'
              }
            }
          }
          runAfter: {
            XML_Validation: [
              'Succeeded'
            ]
          }
          type: 'Xslt'
        }
        XML_Validation: {
          inputs: {
            content: '@{triggerBody()}'
            integrationAccount: {
              schema: {
                name: 'Order'
              }
            }
          }
          runAfter: {}
          type: 'XmlValidation'
        }
      }
      contentVersion: '1.0.0.0'
      outputs: {}
      parameters: {}
      triggers: {
        manual: {
          inputs: {
            schema: {}
          }
          kind: 'Http'
          type: 'Request'
        }
      }
    }
  }
  dependsOn: [
    integrationAccountName_resource
  ]
}