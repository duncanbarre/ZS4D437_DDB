@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Extension Include for Travel items'
@Metadata.ignorePropagatedAnnotations: true
@AbapCatalog.extensibility: {
    extensible: true,
    allowNewDatasources: false,
    dataSources: ['Item'],
    elementSuffix: 'ZDB'
}
define view entity ZDDB_E_TravelItem as select from zddb_tritem as Item
{
    key item_uuid as ItemUuid
 
}
