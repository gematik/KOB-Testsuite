# language: de
@OPTIONAL @EPA_3_0
# can only be run against gematik VAU Mock Service,
# as the necessary crypto key information is contained in the VAU handshake responses
@Mock
Funktion: Test ePA VAU handshake

  Szenario: VAU handshake
    Gegeben sei TGR lösche aufgezeichnete Nachrichten
    Und TGR lösche die benutzerdefinierte Fehlermeldung
    Und KOB setze alle EPA sessions des Primärsystems zurück
    Und KOB stecke EGK mit der KVNR "${kob.kvnr}"

    ### VAU Handshake
    # Message 1
    Und TGR wait for message with node "$.path" matching "/VAU"
    Und TGR find last request to path "/VAU"
    Und TGR current request with attribute "$.method" matches "POST"
    Und TGR current request with attribute "$.header.[~'accept']" matches ".*application/cbor.*"
    Und TGR current request with attribute "$.header.[~'content-type']" matches "application/cbor"
    Und TGR current request with attribute "$.body.MessageType" matches "M1"
    Und TGR current request with attribute "$.body.ECDH_PK.crv" matches "P-256"
    Und the current request at node "$.body.ECDH_PK.x" has a CBOR byte string with length 32
    Und the current request at node "$.body.ECDH_PK.y" has a CBOR byte string with length 32
    # check body structure
    Und TGR current request at "$.body" matches as JSON:
    """
    {
      "MessageType" : "M1",
      "ECDH_PK" : {
        "crv" : "P-256",
        "x" : "${json-unit.ignore}",
        "y" : "${json-unit.ignore}"
      },
      "Kyber768_PK" : "${json-unit.ignore}",
    }
    """

    # Message 2
    Dann TGR wait for message with node "$.body.MessageType" matching "M2"
    Und TGR current response with attribute "$.responseCode" matches "200"
    Und TGR current response with attribute "$.header.[~'content-type']" matches "application/cbor"
    Und TGR current response contains node "$.header.VAU-CID"
    Und TGR set global variable "vauCid" to "!{rbel:currentResponseAsString('$.header.VAU-CID')}"
    Und TGR current response with attribute "$.body.MessageType" matches "M2"
    Und TGR current response with attribute "$.body.ECDH_ct.crv" matches "P-256"
    # check body structure
    Und TGR current response at "$.body" matches as JSON:
    """
    {
      "MessageType" : "M2",
      "ECDH_ct" : {
        "crv" : "P-256",
        "x" : "${json-unit.ignore}",
        "y" : "${json-unit.ignore}"
      },
      "Kyber768_ct" : "${json-unit.ignore}",
      "AEAD_ct" : "${json-unit.ignore}"
    }
    """
    Und TGR current response with attribute "$.body.AEAD_ct.decrypted_content.cdv" matches "1"
    Und TGR current response at "$.body.AEAD_ct.decrypted_content" matches as JSON:
    """
    {
      "signed_pub_keys" : "${json-unit.ignore}",
      "signature-ES256" : "${json-unit.ignore}",
      "cert_hash" : "${json-unit.ignore}",
      "cdv" : 1,
      "ocsp_response" : "${json-unit.ignore}"
    }
    """
    Und TGR current response with attribute "$.body.AEAD_ct.decrypted_content.signed_pub_keys.content.ECDH_PK.crv" matches "P-256"
    Und TGR current response with attribute "$.body.AEAD_ct.decrypted_content.signed_pub_keys.content.comment" matches "VAU Server Keys"
    Und TGR current response at "$.body.AEAD_ct.decrypted_content.signed_pub_keys.content" matches as JSON:
    """
      {
        "ECDH_PK" : {
          "crv" : "P-256",
          "x" : "${json-unit.ignore}",
          "y" : "${json-unit.ignore}"
        },
        "Kyber768_PK" : "${json-unit.ignore}",
        "iat" : "[\\d]*",
        "exp" : "[\\d]*",
        "comment" : "VAU Server Keys"
      }
    """

    # Message 3
    Dann TGR find next request to path "${vauCid}" containing node "$.body.MessageType"
    Und TGR current request with attribute "$.method" matches "POST"
    Und TGR current request with attribute "$.header.[~'accept']" matches ".*application/cbor.*"
    Und TGR current request with attribute "$.header.[~'content-type']" matches "application/cbor"
    Und TGR current request with attribute "$.body.MessageType" matches "M3"
    Und the current request at node "$.body.AEAD_ct" is a CBOR byte string
    Und the current request at node "$.body.AEAD_ct_key_confirmation" is a CBOR byte string
    # check body structure
    Und TGR current request at "$.body" matches as JSON:
    """
    {
      "MessageType" : "M3",
      "AEAD_ct" : "${json-unit.ignore}",
      "AEAD_ct_key_confirmation" : "${json-unit.ignore}"
    }
    """
    Und TGR current request with attribute "$.body.AEAD_ct.decrypted_content.ECDH_ct.crv" matches "P-256"
    Und the current request at node "$.body.AEAD_ct.decrypted_content.ECDH_ct.x" has a CBOR byte string with length 32
    Und the current request at node "$.body.AEAD_ct.decrypted_content.ECDH_ct.y" has a CBOR byte string with length 32
    Und TGR current request with attribute "$.body.AEAD_ct.decrypted_content.ERP" matches "[f|F]alse"
    Und TGR current request with attribute "$.body.AEAD_ct.decrypted_content.ESO" matches "[f|F]alse"
    Und TGR current request at "$.body.AEAD_ct.decrypted_content" matches as "JSON":
    """
    {
      "ECDH_ct" : {
        "crv" : "P-256",
        "x" : "${json-unit.ignore}",
        "y" : "${json-unit.ignore}"
      },
      "Kyber768_ct" : "${json-unit.ignore}",
      "ERP" : False,
      "ESO" : False
    }
    """

    # Message 4
    Dann TGR wait for message with node "$.body.MessageType" matching "M4"
    Und TGR current response with attribute "$.responseCode" matches "200"
    Und TGR current response with attribute "$.header.[~'content-type']" matches "application/cbor"
    Und TGR current response with attribute "$.body.MessageType" matches "M4"
    Und TGR current response at "$.body" matches as "JSON":
    """
    {
     "MessageType" : "M4",
     "AEAD_ct_key_confirmation" : "${json-unit.ignore}"
   }
    """
