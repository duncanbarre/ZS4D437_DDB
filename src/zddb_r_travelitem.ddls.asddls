@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Flight Travel Item'
@AbapCatalog.extensibility: {
    extensible: true,
    elementSuffix: 'ZDA',    
    dataSources: [ '_Extension' ],
    allowNewDatasources: false    
}
define view entity ZDDB_R_TRAVELITEM
  as select from zddb_tritem
  association to parent ZDDB_R_TRAVEL as _Travel
   on $projection.AgencyId = _Travel.AgencyId
  and $projection.TravelId = _Travel.TravelId 
  
  association to ZDDB_E_TravelItem as _Extension on $projection.ItemUuid = _Extension.ItemUuid
  {
    key item_uuid            as ItemUuid,
        agency_id            as AgencyId,
        travel_id            as TravelId,
        carrier_id           as CarrierId,
        connection_id        as ConnectionId,
        flight_date          as FlightDate,
        booking_id           as BookingId,
        passenger_first_name as PassengerFirstName,
        passenger_last_name  as PassengerLastName,
        @Semantics.systemDateTime.lastChangedAt: true
        changed_at           as ChangedAt,
        @Semantics.user.lastChangedBy: true
        changed_by           as ChangedBy,
        @Semantics.systemDateTime.localInstanceLastChangedAt: true
        loc_changed_at       as LocChangedAt,
        _Travel,
        _Extension
        
  }
