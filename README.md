# Azure Purview - Publish and Subscribe to Kafka Topics via Eventhubs <!-- omit in toc -->

This sample documents and showcases how you can publish and subscribe to [Azure Purview](https://azure.microsoft.com/en-au/services/purview/) events through a Kafka Topic via Eventhubs. It documents the diffrent payload expected formats and corresponding samples including how to log custom lineage via Eventhubs.

This sample is meant to complement the [official Microsoft documentation](https://docs.microsoft.com/en-us/azure/purview/manage-kafka-dotnet).

## Table of Contents <!-- omit in toc -->

- [Publish](#publish)
  - [Known Issues](#known-issues)
  - [How to use the sample](#how-to-use-the-sample)
  - [Publish Payload Formats](#publish-payload-formats)
    - [ENTITY_CREATE_V2 and ENTITY_FULL_UPDATE_V2](#entity_create_v2-and-entity_full_update_v2)
    - [ENTITY_PARTIAL_UPDATE_V2](#entity_partial_update_v2)
    - [ENTITY_DELETE_V2](#entity_delete_v2)
    - [ENTITY_OBJECT_ID](#entity_object_id)
- [Subscribe](#subscribe)
  - [Supported Operations](#supported-operations)
  - [Subscribe Payload Formats](#subscribe-payload-formats)
    - [ENTITY_CREATE](#entity_create)
    - [ENTITY_UPDATE](#entity_update)
    - [ENTITY_DELETE](#entity_delete)
    - [CLASSIFICATION_ADD](#classification_add)
    - [CLASSIFICATION UPDATE](#classification-update)
    - [CLASSIFICATION DELETE](#classification-delete)
- [Additional Resources](#additional-resources)

## Publish

To publish events to Purview, publish to provided `ATLAS_HOOK` eventhub.

### Known Issues

This sample uses the [Eventhub REST API](https://docs.microsoft.com/en-us/rest/api/eventhub/) because the [Eventhub SDKs will batch messages into array](https://stackoverflow.com/questions/66321726/does-eventhubproducerclient-offer-sendasync-with-single-eventdata). As of June 2021, Azure Purview does not support reading this batched format.

### How to use the sample

1. Set the following environment variables:

    - EVENTHUB_URI - for example: `atlas-6ef6c5b5-3f00-4511-aba3-163bd76a9d7d.servicebus.windows.net`
    - EVENTHUB_SHARED_ACCESS_KEY

    > Retrieve these information from `Atlas Kafka endpoint connectionstring` in the `Properties` of your Purview instance.

2. Run `./publish.sh <FILE_PATH_TO_ATLAS_DEFINITION>`.
    - To create entity: `./publish.sh atlas_definitions/eh_create_entity.json`
    - To log custom lineage: `./publish.sh atlas_definitions/eh_create_entity_lineage.json`
    - To update (full) entity: `./publish.sh atlas_definitions/eh_full_update_entity.json`
    - To update (partial) entity: `./publish.sh atlas_definitions/eh_partial_update_entity.json`
    - To delete entity: `./publish.sh atlas_definitions/eh_delete_entity_by_qualified_name.json`

### Publish Payload Formats

Hook Notification Types (Atlas V2 only):

- ENTITY_CREATE_V2
- ENTITY_FULL_UPDATE_V2
- ENTITY_PARTIAL_UPDATE_V2
- ENTITY_DELETE_V2

The following are the expected Payload format for each Hook Notification Type.

#### ENTITY_CREATE_V2 and ENTITY_FULL_UPDATE_V2

```json
{
    "message": {
        "entities": {
            "entities": [ { <ENTITY_DEFINITION> } ],
            "referredEntities": { 
                "<ID1_REFERRED_IN_ENTITY_DEFINITION>": {},
                "<ID1_REFERRED_IN_ENTITY_DEFINITION>": {}
                ...
            }
        },
        "type": "<ENTITY_CREATE_V2 or ENTITY_FULL_UPDATE_V2>",
        "user": "<user>"
    },
    "version": {
        "version": "1.0.0"
    }
}
```

Sample payloads:

- [eh_create_entity.json](atlas_definitions/eh_create_entity.json)
- [eh_full_update_entity.json](atlas_definitions/eh_full_update_entity.json)

#### ENTITY_PARTIAL_UPDATE_V2

```json
{
    "message": {
        "entityId": { <ENTITY_OBJECT_ID> },
        "entity": {
            "entity": {
                "typeName": "<TypeName>",
                "attributes": {
                    "<attr1>": "<value>"
                }
            }
        },
        "type": "ENTITY_PARTIAL_UPDATE_V2",
        "user": "<user>"
    },
    "version": {
        "version": "1.0.0"
    }
}
```

Sample payloads:

- [eh_delete_entity_by_qualified_name.json](atlas_definitions/eh_partial_update_entity.json)

#### ENTITY_DELETE_V2

```json
{
    "message": {
        "entities": [ { <ENTITY_OBJECT_ID> }],
        "type": "ENTITY_DELETE_V2",
        "user": "<user>"
    },
    "version": {
        "version": "1.0.0"
    }
}
```

Sample payloads:

- [eh_delete_entity_by_qualified_name.json](atlas_definitions/eh_delete_entity_by_qualified_name.json)
- [eh_delete_entity_by_id.json](atlas_definitions/eh_delete_entity_by_id.json)

#### ENTITY_OBJECT_ID

1. TypeName and UniqueAttribute

    ```json
    {
        "typeName": "<TYPE_NAME>",
        "uniqueAttributes": {
            "qualifiedName": "<QUALIFIED_NAME>"
        }
    }
    ```

2. GUID

    ```json
    {
        "guid": "<ENTITY_GUID>"
    }

## Subscribe

Purview allows subscribing to events via the `ATLAS_ENTITIES` eventhub. Refer to [official documentation](https://docs.microsoft.com/en-us/azure/event-hubs/event-hubs-dotnet-standard-getstarted-send#receive-events) on how to receive events from an eventhub.

Alternatively, you can also utilize tooling such as [VSCode Eventhub Explorer](https://marketplace.visualstudio.com/items?itemName=Summer.azure-event-hub-explorer).

### Supported Operations

The following are supported operation types:

- ENTITY_CREATE
- ENTITY_UPDATE
- ENTITY_DELETE
- CLASSIFICATION_ADD - when classifications are added to Entity.
- CLASSIFICATION_UPDATE - when classifications are added to an Entity with **existing** classifications
- CLASSIFICATION_DELETE - when classifications are deleted from an Entity

The following does **not** result in a notification (not exhaustive):

1. Creating/updating/deleting:

   - Glossary Terms
   - Term Templates
   - Classifications
   - Classification Rules
   - Collections
   - Resource Set Pattern Rules

2. Registering Data Sources

3. Adding a Data Factory and Data Share connection.

### Subscribe Payload Formats

#### ENTITY_CREATE

```json
{
  "version": {
    "version": "1.0.0",
    "versionParts": [
      1
    ]
  },
  "msgCompressionKind": "NONE",
  "msgSplitIdx": 1,
  "msgSplitCount": 1,
  "msgSourceIP": "<IP_ADDRESS>",
  "msgCreatedBy": "",
  "msgCreationTime": 1627361202541,
  "message": {
    "type": "ENTITY_NOTIFICATION_V2",
    "entity": {
      "typeName": "DataSet",
      "attributes": {
        "qualifiedName": "MyDataset",
        "name": "My Dataset"
      },
      "guid": "938fa19f-c616-4e98-a3ad-0cf46250ccc6",
      "status": "ACTIVE",
      "displayText": "My Dataset"
    },
    "operationType": "ENTITY_CREATE",
    "eventTime": 1627361202110
  }
}
```

#### ENTITY_UPDATE

```json
{
  "version": {
    "version": "1.0.0",
    "versionParts": [
      1
    ]
  },
  "msgCompressionKind": "NONE",
  "msgSplitIdx": 1,
  "msgSplitCount": 1,
  "msgSourceIP": "<IP_ADDRESS>",
  "msgCreatedBy": "",
  "msgCreationTime": 1627361228916,
  "message": {
    "type": "ENTITY_NOTIFICATION_V2",
    "entity": {
      "typeName": "DataSet",
      "attributes": {
        "qualifiedName": "MyDataset",
        "name": "My UPDATED Dataset"
      },
      "guid": "938fa19f-c616-4e98-a3ad-0cf46250ccc6",
      "status": "ACTIVE",
      "displayText": "My UPDATED Dataset"
    },
    "operationType": "ENTITY_UPDATE",
    "eventTime": 1627361228523
  }
}
```

#### ENTITY_DELETE

```json
  "version": {
    "version": "1.0.0",
    "versionParts": [
      1
    ]
  },
  "msgCompressionKind": "NONE",
  "msgSplitIdx": 1,
  "msgSplitCount": 1,
  "msgSourceIP": "<IP_ADDRESS>",
  "msgCreatedBy": "",
  "msgCreationTime": 1627361099553,
  "message": {
    "type": "ENTITY_NOTIFICATION_V2",
    "entity": {
      "typeName": "DataSet",
      "attributes": {
        "qualifiedName": "MyDataset",
        "name": "My Dataset"
      },
      "guid": "cbb31970-c9f4-438f-b080-c11e3d73ac98",
      "displayText": "My Dataset"
    },
    "operationType": "ENTITY_DELETE",
    "eventTime": 1627361099055
  }
}
```

#### CLASSIFICATION_ADD

```json
{
  "version": {
    "version": "1.0.0",
    "versionParts": [
      1
    ]
  },
  "msgCompressionKind": "NONE",
  "msgSplitIdx": 1,
  "msgSplitCount": 1,
  "msgSourceIP": "<IP_ADDRESS>",
  "msgCreatedBy": "",
  "msgCreationTime": 1627361507682,
  "message": {
    "type": "ENTITY_NOTIFICATION_V2",
    "entity": {
      "typeName": "DataSet",
      "attributes": {
        "qualifiedName": "MyDataset",
        "name": "My Dataset"
      },
      "guid": "938fa19f-c616-4e98-a3ad-0cf46250ccc6",
      "status": "ACTIVE",
      "displayText": "My Dataset",
      "classificationNames": [
        "MICROSOFT.FINANCIAL.US.ABA_ROUTING_NUMBER"
      ],
      "classifications": [
        {
          "typeName": "MICROSOFT.FINANCIAL.US.ABA_ROUTING_NUMBER",
          "lastModifiedTS": "1",
          "entityGuid": "938fa19f-c616-4e98-a3ad-0cf46250ccc6",
          "entityStatus": "ACTIVE"
        }
      ]
    },
    "operationType": "CLASSIFICATION_ADD",
    "eventTime": 1627361507445
  }
}
```

#### CLASSIFICATION UPDATE

```json
{
  "version": {
    "version": "1.0.0",
    "versionParts": [
      1
    ]
  },
  "msgCompressionKind": "NONE",
  "msgSplitIdx": 1,
  "msgSplitCount": 1,
  "msgSourceIP": "<IP_ADDRESS>",
  "msgCreatedBy": "",
  "msgCreationTime": 1627363314455,
  "message": {
    "type": "ENTITY_NOTIFICATION_V2",
    "entity": {
      "typeName": "DataSet",
      "attributes": {
        "qualifiedName": "MyDataset",
        "name": "My Dataset"
      },
      "guid": "938fa19f-c616-4e98-a3ad-0cf46250ccc6",
      "status": "ACTIVE",
      "displayText": "My Dataset",
      "classificationNames": [
        "Test Classification",
        "MICROSOFT.FINANCIAL.US.ABA_ROUTING_NUMBER"
      ],
      "classifications": [
        {
          "typeName": "Test Classification",
          "lastModifiedTS": "1",
          "entityGuid": "938fa19f-c616-4e98-a3ad-0cf46250ccc6",
          "entityStatus": "ACTIVE"
        },
        {
          "typeName": "MICROSOFT.FINANCIAL.US.ABA_ROUTING_NUMBER",
          "lastModifiedTS": "1",
          "entityGuid": "938fa19f-c616-4e98-a3ad-0cf46250ccc6",
          "entityStatus": "ACTIVE"
        }
      ]
    },
    "operationType": "CLASSIFICATION_UPDATE",
    "eventTime": 1627363314138
  }
}
```

#### CLASSIFICATION DELETE

```json
{
  "version": {
    "version": "1.0.0",
    "versionParts": [
      1
    ]
  },
  "msgCompressionKind": "NONE",
  "msgSplitIdx": 1,
  "msgSplitCount": 1,
  "msgSourceIP": "<IP_ADDRESS>",
  "msgCreatedBy": "",
  "msgCreationTime": 1627361853716,
  "message": {
    "type": "ENTITY_NOTIFICATION_V2",
    "entity": {
      "typeName": "DataSet",
      "attributes": {
        "qualifiedName": "MyDataset",
        "name": "My Dataset"
      },
      "guid": "938fa19f-c616-4e98-a3ad-0cf46250ccc6",
      "status": "ACTIVE",
      "displayText": "My Dataset"
    },
    "operationType": "CLASSIFICATION_DELETE",
    "eventTime": 1627361853275
  }
}
```

## Additional Resources

- [Altas Notifications](https://atlas.apache.org/2.0.0/Notifications.html)