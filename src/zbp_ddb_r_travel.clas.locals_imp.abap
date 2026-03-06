CLASS lsc_zddb_r_travel DEFINITION INHERITING FROM cl_abap_behavior_saver.



  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

  PRIVATE SECTION.

    METHODS map_message
      IMPORTING i_msg        TYPE symsg
      RETURNING VALUE(r_msg) TYPE REF TO if_abap_behv_message.

ENDCLASS.

CLASS lsc_zddb_r_travel IMPLEMENTATION.

  METHOD save_modified.

    DATA(model) = NEW /lrn/cl_s4d437_tritem( 'zddb_tritem' ).


    LOOP AT delete-item ASSIGNING FIELD-SYMBOL(<item_d>).
      DATA(msg_d) = model->delete_item( <item_d>-ItemUuid ).

      IF msg_d IS NOT INITIAL.
        APPEND VALUE #( %tky-itemuuid = <item_d>-ItemUuid
                        %msg = map_message( msg_d ) )
            TO reported-item.
      ENDIF.
    ENDLOOP.

    LOOP AT create-item ASSIGNING FIELD-SYMBOL(<item_c>).
      DATA(msg_c) = model->create_item( CORRESPONDING #( <item_c> ) ).

      IF msg_c IS NOT INITIAL.
        APPEND VALUE #( %tky-itemuuid = <item_c>-ItemUuid
                        %msg = map_message( msg_c ) )
            TO reported-item.
      ENDIF.
    ENDLOOP.

    LOOP AT update-item ASSIGNING FIELD-SYMBOL(<item_u>).
      DATA(msg_u) = model->update_item(
         i_item = CORRESPONDING #( <item_u> MAPPING FROM ENTITY )
         i_itemx = CORRESPONDING #( <item_u> MAPPING FROM ENTITY USING CONTROL ) ).

      IF msg_u IS NOT INITIAL.
        APPEND VALUE #( %tky-itemuuid = <item_d>-ItemUuid
                        %msg = map_message( msg_u ) )
            TO reported-item.
      ENDIF.
    ENDLOOP.

    IF create-travel_ddb IS NOT INITIAL.
      DATA event_in TYPE TABLE FOR EVENT ZDDB_R_Travel~TravelCreated.
      LOOP AT create-travel_ddb ASSIGNING FIELD-SYMBOL(<new_travel>).
        APPEND VALUE #( AgencyId = <new_travel>-AgencyId
                        TravelId = <new_travel>-TravelId
                        origin = 'ZDDB_R_TRAVEL' ) TO event_in.
      ENDLOOP.
      RAISE ENTITY EVENT ZDDB_R_Travel~TravelCreated FROM event_in.
    ENDIF.


  ENDMETHOD.

  METHOD map_message.
    DATA(severity) = SWITCH #( i_msg-msgty
    WHEN 'S' THEN if_abap_behv_message=>severity-success
    WHEN 'I' THEN if_abap_behv_message=>severity-information
    WHEN 'W' THEN if_abap_behv_message=>severity-warning
    WHEN 'E' THEN if_abap_behv_message=>severity-error
    ELSE if_abap_behv_message=>severity-none ).

    r_msg = new_message(
              id       = i_msg-msgid
              number   = i_msg-msgno
              severity = severity
            ).

  ENDMETHOD.

ENDCLASS.

CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS validateFlightDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR Item~validateFlightDate.
    METHODS determineTravelDates FOR DETERMINE ON SAVE
      IMPORTING keys FOR Item~determineTravelDates.

ENDCLASS.

CLASS lhc_item IMPLEMENTATION.

  METHOD validateFlightDate.
    READ ENTITIES OF zddb_r_travel IN LOCAL MODE
     ENTITY Item
        FIELDS ( FlightDate AgencyId TravelId )
        WITH CORRESPONDING #( keys )
     RESULT DATA(items).

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).
      APPEND VALUE #( %tky = <item>-%tky
                       %state_area = 'FLIGHTDATE' )
    TO reported-item.

      IF <item>-FlightDate IS INITIAL.
        APPEND VALUE #( %tky = <item>-%tky )
            TO failed-item.
        APPEND VALUE #( %tky = <item>-%tky
                        %msg = NEW /lrn/cm_s4d437( textid = /lrn/cm_s4d437=>field_empty )
                        %element-FlightDate = if_abap_behv=>mk-on
                        %state_area = 'FLIGHTDATE'
                        %path-travel_ddb  = CORRESPONDING #( <item> ) )
           TO reported-item.
      ELSEIF <item>-FlightDate <  cl_abap_context_info=>get_system_date( ).
        APPEND VALUE #( %tky = <item>-%tky )
            TO failed-item.
        APPEND VALUE #( %tky = <item>-%tky
                        %msg = NEW /lrn/cm_s4d437( textid = /lrn/cm_s4d437=>begin_date_past )
                        %element-FlightDate = if_abap_behv=>mk-on
                        %state_area = 'FLIGHTDATE'
                        %path-travel_ddb  = CORRESPONDING #( <item> ) )
            TO reported-item.

      ENDIF.
    ENDLOOP.


  ENDMETHOD.

  METHOD determineTravelDates.
    READ ENTITIES OF zddb_r_travel IN LOCAL MODE
      ENTITY Item
         FIELDS ( FlightDate )
         WITH CORRESPONDING #( keys )
         RESULT DATA(items)
         BY \_Travel
         FIELDS ( BeginDate EndDate )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels)
         LINK DATA(link).


    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).
      ASSIGN travels[ KEY id %tky =
      link[ KEY id source-%tky = <item>-%tky ]-target-%tky ]
      TO FIELD-SYMBOL(<travel>).

      IF <travel>-EndDate < <item>-FlightDate.
        <travel>-EndDate = <item>-FlightDate.
      ENDIF.

      IF <item>-FlightDate > cl_abap_context_info=>get_system_date( )
      AND <item>-FlightDate < <travel>-BeginDate.
        <travel>-BeginDate = <item>-FlightDate.
      ENDIF.

      MODIFY ENTITIES OF ZDDB_R_Travel IN LOCAL MODE ENTITY Travel_DDB
      UPDATE FIELDS ( BeginDate EndDate )
      WITH CORRESPONDING #( travels ).

    ENDLOOP.
*
*    MODIFY ENTITIES OF zddb_r_travel IN LOCAL MODE
*      ENTITY Item
*      UPDATE FIELDS ( TravelID )
*      WITH CORRESPONDING #( items ).

  ENDMETHOD.

ENDCLASS.

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
    METHODS determineduration FOR DETERMINE ON SAVE
      IMPORTING keys FOR travel_ddb~determineduration.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE travel_ddb.

    CONSTANTS:
      c_area    TYPE string VALUE 'DESC',
      begindate TYPE string VALUE 'begindate',
      enddate   TYPE string VALUE 'enddate',
      sequence  TYPE string VALUE 'sequence'.


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


      APPEND VALUE #( %tky = <travel>-%tky
                      %state_area = c_area ) TO reported-travel_ddb.

      IF <travel>-Description IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky )
            TO failed-travel_ddb.
        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( textid = /lrn/cm_s4d437=>field_empty )
                        %element-description = if_abap_behv=>mk-on
                        %state_area = c_area )
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

      APPEND VALUE #( %tky = <travel>-%tky
                        %state_area = c_area ) TO reported-travel_ddb.

      IF <travel>-CustomerID IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky )
            TO failed-travel_ddb.
        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( textid = /lrn/cm_s4d437=>field_empty )
                        %element-customerid = if_abap_behv=>mk-on
                        %state_area = c_area )
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
                          %element-customerid = if_abap_behv=>mk-on
                          %state_area = c_area )
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
      APPEND VALUE #( %tky = <travel>-%tky
                     %state_area = begindate ) TO reported-travel_ddb.

      IF <travel>-BeginDate IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky )
            TO failed-travel_ddb.
        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( textid = /lrn/cm_s4d437=>field_empty )
                        %element-begindate = if_abap_behv=>mk-on
                        %state_area = begindate )
            TO reported-travel_ddb.
      ELSE.
        IF <travel>-BeginDate < cl_abap_context_info=>get_system_date( ).
          APPEND VALUE #( %tky = <travel>-%tky )
              TO failed-travel_ddb.
          APPEND VALUE #( %tky = <travel>-%tky
                          %msg = NEW /lrn/cm_s4d437( textid = /lrn/cm_s4d437=>begin_date_past
                                                     begindate = <travel>-BeginDate )
                          %element-begindate = if_abap_behv=>mk-on
                          %state_area = begindate )
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
      APPEND VALUE #( %tky = <travel>-%tky
                  %state_area = enddate ) TO reported-travel_ddb.


      IF <travel>-EndDate IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky )
            TO failed-travel_ddb.
        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( textid = /lrn/cm_s4d437=>field_empty )
                        %element-EndDate = if_abap_behv=>mk-on
                        %state_area = enddate )
            TO reported-travel_ddb.
      ELSE.
        IF <travel>-EndDate < cl_abap_context_info=>get_system_date( ).
          APPEND VALUE #( %tky = <travel>-%tky )
              TO failed-travel_ddb.
          APPEND VALUE #( %tky = <travel>-%tky
                          %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>end_date_past )
                          %element-EndDate = if_abap_behv=>mk-on
                          %state_area = enddate )
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
      APPEND VALUE #( %tky = <travel>-%tky
                   %state_area = enddate ) TO reported-travel_ddb.

      IF <travel>-EndDate < <travel>-BeginDate.

        APPEND VALUE #( %tky = <travel>-%tky )
        TO failed-travel_ddb.

        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>dates_wrong_sequence )
                        %element = VALUE #( BeginDate = if_abap_behv=>mk-on EndDate = if_abap_behv=>mk-on
                         )
                        %state_area = sequence  )
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


      IF <travel>-%is_draft = if_abap_behv=>mk-on.
        READ ENTITIES OF zddb_r_travel IN LOCAL MODE
        ENTITY travel_ddb
        FIELDS ( BeginDate EndDate )
        WITH VALUE #( ( %key = <travel>-%key ) )
        RESULT DATA(travels_active).

        IF travels_active IS NOT INITIAL.
          <travel>-BeginDate = travels_active[ 1 ]-begindate.
          <travel>-EndDate = travels_active[ 1 ]-enddate.
        ELSE.
          CLEAR <travel>-BeginDate.
          CLEAR <travel>-EndDate.
        ENDIF.
      ENDIF.

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

  METHOD determineDuration.
    READ ENTITIES OF zddb_r_travel IN LOCAL MODE
    ENTITY travel_ddb
       FIELDS ( BeginDate EndDate )
       WITH CORRESPONDING #( keys )
      RESULT DATA(travels).


    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      <travel>-Duration = <travel>-EndDate - <travel>-BeginDate.
    ENDLOOP.

    MODIFY ENTITIES OF zddb_r_travel IN LOCAL MODE
      ENTITY travel_ddb
      UPDATE FIELDS ( Duration )
      WITH CORRESPONDING #( travels ).


  ENDMETHOD.

ENDCLASS.
