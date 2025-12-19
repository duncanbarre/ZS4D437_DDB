CLASS lhc_travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR travel_ddb RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR travel_ddb RESULT result.
    METHODS cancel_travel FOR MODIFY
      IMPORTING keys FOR ACTION travel_ddb~cancel_travel.
    METHODS validatedescription FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel_ddb~validatedescription.
    METHODS validatecustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel_ddb~validatecustomer.
    METHODS validatebegindate FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel_ddb~validatebegindate.
    METHODS validateenddate FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel_ddb~validateenddate.
    METHODS validatedatesequence FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel_ddb~validatedatesequence.
    METHODS determinestatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR travel_ddb~determinestatus.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR travel_ddb RESULT result.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE travel_ddb.


ENDCLASS.

CLASS lhc_travel IMPLEMENTATION.

  METHOD get_instance_authorizations.

    result = CORRESPONDING #( keys ).


    LOOP AT result ASSIGNING FIELD-SYMBOL(<result>).

      DATA(checkApproved) = /lrn/cl_s4d437_model=>authority_check( i_agencyid = <result>-AgencyId
                                             i_actvt = '02' ).

      IF checkApproved <> 0.
        <result>-%action-cancel_travel = if_abap_behv=>auth-allowed.
        <result>-%update = if_abap_behv=>auth-allowed.
      ELSE.
        <result>-%action-cancel_travel = if_abap_behv=>auth-unauthorized.
        <result>-%update = if_abap_behv=>auth-unauthorized.
      ENDIF.
    ENDLOOP.


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

  METHOD validateDescription.
    READ ENTITIES OF zddb_r_travel IN LOCAL MODE
      ENTITY travel_ddb
         FIELDS ( Description )
         WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      IF <travel>-Description IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky )
            TO failed-travel_ddb.
        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( textid = /lrn/cm_s4d437=>field_empty )
                        %element-description = if_abap_behv=>mk-on )
            TO reported-travel_ddb.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateCustomer.
    READ ENTITIES OF zddb_r_travel IN LOCAL MODE
      ENTITY travel_ddb
         FIELDS ( CustomerId )
         WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      IF <travel>-CustomerID IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky )
            TO failed-travel_ddb.
        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( textid = /lrn/cm_s4d437=>field_empty )
                        %element-customerid = if_abap_behv=>mk-on )
            TO reported-travel_ddb.
      ELSE.
        SELECT SINGLE customerId
        FROM /DMO/I_Customer
        WHERE CustomerID = @<travel>-CustomerID
        INTO @DATA(customerFound).

        IF customerFound IS INITIAL.
          APPEND VALUE #( %tky = <travel>-%tky )
              TO failed-travel_ddb.
          APPEND VALUE #( %tky = <travel>-%tky
                          %msg = NEW /lrn/cm_s4d437( textid = /lrn/cm_s4d437=>customer_not_exist
                                                     customerid = <travel>-CustomerID )
                          %element-customerid = if_abap_behv=>mk-on )
              TO reported-travel_ddb.
        ENDIF.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateBeginDate.
    READ ENTITIES OF zddb_r_travel IN LOCAL MODE
    ENTITY travel_ddb
       FIELDS ( BeginDate )
       WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      IF <travel>-BeginDate IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky )
            TO failed-travel_ddb.
        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( textid = /lrn/cm_s4d437=>field_empty )
                        %element-begindate = if_abap_behv=>mk-on )
            TO reported-travel_ddb.
      ELSE.
        IF <travel>-BeginDate < cl_abap_context_info=>get_system_date( ).
          APPEND VALUE #( %tky = <travel>-%tky )
              TO failed-travel_ddb.
          APPEND VALUE #( %tky = <travel>-%tky
                          %msg = NEW /lrn/cm_s4d437( textid = /lrn/cm_s4d437=>begin_date_past
                                                     begindate = <travel>-BeginDate )
                          %element-begindate = if_abap_behv=>mk-on )
              TO reported-travel_ddb.
        ENDIF.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateEndDate.
    READ ENTITIES OF zddb_r_travel IN LOCAL MODE
     ENTITY travel_ddb
        FIELDS ( EndDate )
        WITH CORRESPONDING #( keys )
     RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      IF <travel>-EndDate IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky )
            TO failed-travel_ddb.
        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( textid = /lrn/cm_s4d437=>field_empty )
                        %element-EndDate = if_abap_behv=>mk-on )
            TO reported-travel_ddb.
      ELSE.
        IF <travel>-EndDate < cl_abap_context_info=>get_system_date( ).
          APPEND VALUE #( %tky = <travel>-%tky )
              TO failed-travel_ddb.
          APPEND VALUE #( %tky = <travel>-%tky
                          %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>end_date_past )
                          %element-EndDate = if_abap_behv=>mk-on )
              TO reported-travel_ddb.
        ENDIF.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateDateSequence.
    READ ENTITIES OF zddb_r_travel IN LOCAL MODE
     ENTITY travel_ddb
        FIELDS ( BeginDate EndDate )
        WITH CORRESPONDING #( keys )
     RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      IF <travel>-EndDate < <travel>-BeginDate.

        APPEND VALUE #( %tky = <travel>-%tky )
        TO failed-travel_ddb.

        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>dates_wrong_sequence )
                        %element = VALUE #( BeginDate = if_abap_behv=>mk-on EndDate = if_abap_behv=>mk-on ) )
        TO reported-travel_ddb.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD earlynumbering_create.

    DATA(agencyId) = /lrn/cl_s4d437_model=>get_agency_by_user( ).

    mapped-travel_ddb = CORRESPONDING #( entities ).

    LOOP AT mapped-travel_ddb ASSIGNING FIELD-SYMBOL(<mapping>).
      <mapping>-AgencyID = agencyId.
      <mapping>-TravelID = /lrn/cl_s4d437_model=>get_next_travelid( ).
    ENDLOOP.

  ENDMETHOD.

  METHOD determineStatus.
    READ ENTITIES OF zddb_r_travel IN LOCAL MODE
      ENTITY travel_ddb
         FIELDS ( status )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    DELETE travels WHERE status IS NOT INITIAL.

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      <travel>-status = 'N'.
    ENDLOOP.

    MODIFY ENTITIES OF zddb_r_travel IN LOCAL MODE
      ENTITY travel_ddb
      UPDATE FIELDS ( status )
      WITH CORRESPONDING #( travels )
      REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zddb_r_travel IN LOCAL MODE
      ENTITY travel_ddb
         FIELDS ( Status BeginDate EndDate )
         WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      APPEND CORRESPONDING #( <travel> ) TO result ASSIGNING FIELD-SYMBOL(<result>).

      IF <travel>-Status = 'C' OR ( <travel>-EndDate IS NOT INITIAL AND <travel>-EndDate < cl_abap_context_info=>get_system_date( ) ).
        <result>-%update = if_abap_behv=>fc-o-disabled.
        <result>-%action-cancel_travel = if_abap_behv=>fc-o-disabled.
      ELSE.
        <result>-%update = if_abap_behv=>fc-o-enabled.
        <result>-%action-cancel_travel = if_abap_behv=>fc-o-enabled.
      ENDIF.

      IF <travel>-BeginDate IS NOT INITIAL AND <travel>-BeginDate < cl_abap_context_info=>get_system_date( ).
        <result>-%field-BeginDate = if_abap_behv=>fc-f-read_only.
        <result>-%field-CustomerId = if_abap_behv=>fc-f-read_only.
      ELSE.
        <result>-%field-BeginDate = if_abap_behv=>fc-f-mandatory.
        <result>-%field-CustomerId = if_abap_behv=>fc-f-mandatory.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
