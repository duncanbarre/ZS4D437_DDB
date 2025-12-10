CLASS zcl_437t_eml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .

    CONSTANTS c_agency_id TYPE /dmo/agency_id VALUE '070000'.
    CONSTANTS c_travel_id TYPE /dmo/travel_id VALUE '00005450'.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_437t_eml IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    READ ENTITIES OF zddb_r_travel
        ENTITY travel_ddb
          ALL FIELDS
            WITH VALUE #( ( %key = VALUE #( TravelID = c_travel_id
                                            AgencyId = c_agency_id ) ) )
              RESULT DATA(travels)
                FAILED DATA(failed).

    IF failed IS NOT INITIAL.
      out->write( 'Travel does not exist!' ).
    ELSE.


      MODIFY ENTITIES OF zddb_r_travel
        ENTITY travel_ddb
        UPDATE
        FIELDS ( Description )
        WITH VALUE #( (   TravelID = c_travel_id
                          AgencyId = c_agency_id
                          Description = 'test duncan 2'  ) )
       FAILED failed.
    ENDIF.

    IF failed IS INITIAL.
      COMMIT ENTITIES RESPONSE OF zddb_r_travel FAILED failed.
    ELSE.
      ROLLBACK ENTITIES.
    ENDIF.

    IF failed IS INITIAL.
      out->write( 'Description was updated successfully.' ).
    ELSE.
      out->write( 'Failed to update description.' ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
