CLASS lhc_travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR travel_ddb RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR travel_ddb RESULT result.
    METHODS cancel_travel FOR MODIFY
      IMPORTING keys FOR ACTION travel_ddb~cancel_travel.

ENDCLASS.

CLASS lhc_travel IMPLEMENTATION.

  METHOD get_instance_authorizations.

  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD cancel_travel.
    READ ENTITIES OF zddb_r_travel IN LOCAL MODE
      ENTITY travel_ddb
         ALL FIELDS
         WITH CORRESPONDING #( keys )
      RESULT DATA(travels).



    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      IF <travel>-status <> 'C'.
        MODIFY ENTITIES OF ZDDB_R_Travel IN LOCAL MODE
        ENTITY travel_ddb
        UPDATE FIELDS ( status )
        WITH VALUE #( ( %tky = <travel>-%tky
                        status = 'C' ) ).
      ELSE.
        APPEND VALUE #( %tky = <travel>-%tky )
            TO failed-travel_ddb.
        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW zcm_ddb_travel( textid = zcm_ddb_travel=>already_canceled ) )
           TO reported-travel_ddb.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
