!**********************************************************************C
!                                                                      C
!     *** SUBROUTINE WATERBAL ***                                      C
!     SIMULATES MONTHLY WATER BALANCE USING 2 LAYER SOIL MOISTURE      C
!     ALGORITHM FROM NOAA NATIONAL WEATHER SERVICE SACRAMENTO SOIL     C
!     MOISTURE ACCOUNTING MODEL (SAC-SMA)                              C
!     Line 591 --- Carbon model                                        C
!     Line 941 --- Area for each cell                                  C
!     IF MODEL in dynamic land cover then LADUSE(I) -----> VEG(I,J) total:38   C
!**********************************************************************C
      
      SUBROUTINE WATERBAL(I,J_S,M,MNDAY)
        Use Common_var
        implicit none       
! ----------------------------------------------------------------------------     
         
      INTEGER I,J,M,IAM,DAY,MNDAY,J_S, LC_N
      
      REAL AETTEMP, RUNOFFTEMP, PBFTEMP, SBFTEMP,IFTEMP, GEPTEMP,&
            RECOTEMP, NEETEMP

      !REAL UZTWC, UZFWC, LZTWC, LZFSC, LZFPC ! soil moisture content parameters    
         
      REAL ETUZTW(MAX_YEARS,12), RESIDET(MAX_YEARS,12), ETUZFW(MAX_YEARS,12)
      
      REAL ETLZTW(MAX_YEARS,12), RATLZT, RATLZ
      
      REAL SNOW, SNOWW
            
      REAL ET(MAX_YEARS,12), SURFRO, GEP(MAX_YEARS,12), INFIL,&
        RECO(MAX_YEARS,12), NEE(MAX_YEARS,12) 
      
      REAL DPAET
      
      REAL UZRAT, TWX, PERCM, PERC, DEFR, LZDEF 
      
      REAL PERCT, PERCF
      
      REAL HPL, RATLP, RATLS, FRACP, PERCP,PERCS
      
      REAL PBF, SBF, INF
      
      REAL TAUZTWC, TAUZFWC, TALZTWC, TALZFPC, TALZFSC, TASM
   
    !REAL :: RUNLAND(NGRID,NYEAR_S+NWARMUP,12,31)
    !REAL :: ETLAND(NGRID,NYEAR_S+NWARMUP,12,31)
    !REAL :: GEPLAND(NGRID,NYEAR_S+NWARMUP,12,31) 
           
! *****************************************************************************************************

! Assign landcoer type to LC_N
!----Set the simulate ID for the start year
    J=J_S+IYSTART-1-NWARMUP
    LC_N=LADUSE(I)
    !print*,I,LC_N

! --- INITIALIZE VARIABLES FOR START OF SIMULATION

             AETTEMP =0.0
             RUNOFFTEMP = 0.0
             PBFTEMP = 0.0
             SBFTEMP = 0.0
             IFTEMP = 0.0
                          
             GEPTEMP = 0.0
             RECOTEMP = 0.0
             NEETEMP =0.0
             
        IF (J .EQ. 1 .AND. M .EQ. 1) THEN

        IAM =0     
                                          
           UZTWC = 0.1*UZTWM(I)
           UZFWC = 0.0
           LZTWC = 0.1*LZTWM(I)
           LZFSC = 0.75*LZFSM(I)
           LZFPC = 0.75*LZFPM(I)
           SNOWPACK=0.0

        ENDIF 
         
! *****************************************************************************************************
! *****************************************************************************************************
!----- SIMULATE SNOWPACK (SEE VAROSMARTY  ET AL., 1989)
      
             IF (TEMP(I,J, M) .LE.  -1.0) THEN
        
           SNOW = RAIN(I,J,M)
    
           SNOWPACK = SNOWPACK + SNOW
           
           IAM = 0
                                
        ELSE 
        
            IAM = IAM +1 
            
            HUCELE(I) = 1000.
            
            IF (HUCELE(I) .LE. 500.0) THEN
          
              SNOWW = SNOWPACK
              SNOWPACK = 0.
                  
            ELSE 
              
              IF (IAM .EQ. 1) THEN 
              
                 SNOWW = 0.5 * SNOWPACK
              
              ELSEIF (IAM .EQ. 2) THEN
              
                 SNOWW = SNOWPACK
                 
              ELSE
              
                 SNOWW = 0.
                 SNOWPACK = 0.
                                   
              ENDIF
              
              SNOWPACK = SNOWPACK - SNOWW
                            
          ENDIF           
        ENDIF  
                            

! *****************************************************************************************************
! *****************************************************************************************************
! *****************************************************************************************************
! -- LOOP THROUGH DAYS OF CURRENT MONTH AND CALCULATE SOIL WATER STORAGE, BASEFLOW, RUNOFF, AND AET
        
        DO 100 DAY= 1, MNDAY    
        
             TASM = 0.0
             TAUZTWC = 0.0
             TAUZFWC = 0.0
             TALZTWC = 0.0
             TALZFPC = 0.0
             TALZFSC = 0.0


! *****************************************************************************************************
! *****************************************************************************************************
! -- LOOP THROUGH LAND COVERS IN THE HUC AND PERFORM WATER BALANCE COMPUTATIONS
! -- ASSUMES OPEN WATER LAND COVER IS NEG.

! *****************************************************************************************************
! -- SET ET, SURFACE RUNOFF, INTERFLOW, GEP TO ZERO IF TEMPERATURE IS LE -1.0
! -- BASEFLOW STILL OCCURS

        IF (TEMP (I,J, M) .LE. -1.0) THEN
                ET(J,M) = 0.
                SURFRO = 0.
                INF = 0.
                GEP(J,M) = 0.
                
                
! -- COMPUTE PRIMARY BASEFLOW WHEN T <= -1.0

                PBF = LZFPC * LZPK(I)
                LZFPC = LZFPC - PBF
                IF (LZFPC .LE. 0.0001) THEN 
                   PBF = PBF + LZFPC
                   LZFPC = 0.0
                ENDIF
                
! -- COMPUTE SECONDARY BASEFLOW WHEN T <= -1.0

                SBF = LZFSC * LZSK(I)
                LZFSC = LZFSC - SBF
                IF (LZFSC .LE. 0.0001) THEN
                   SBF = SBF + LZFSC
                   LZFSC = 0.0
                ENDIF  

        ELSE
                  
! **************************----Trmperature > -0.1 -------------*******************************************************
! *****************************************************************************************************
! -- COMPUTE THE DAILY AVERAGE INFILTRATION FOR A GIVEN MONTH FOR EACH LAND USE

                INFIL = RAIN(I,J,M)/MNDAY + SNOWW/MNDAY
          
            
! *****************************************************************************************************
! --- COMPUTE AET GIVEN TOTAL WATER STORED IN UPPER SOIL LAYER STORAGES AND PAET CALCULATED IN PET.FOR
! --- ASSUME ET IS SUPPLIED ONLY FROM UPPER LAYER NO UPWARD FLUX FROM LOWER LAYER TO UPPER LAYER
! --- NOTE THAT SAC-SMA ALLOWS ET TO ALSO BE SUPPLIED UNRESTRICTED BY LZ TENSION WATER STORAGE

                
                   DPAET = PAET(I,J, M)/MNDAY
               
                   ET(J, M) = DPAET
                

! --- COMPUTE ET FROM UZ TENSION WATER STORAGE, RECALCULATE UZTWC, CALCULATE RESIDUAL ET DEMAND

                   ETUZTW(J,M) = ET(J,M) * (UZTWC/UZTWM(I))
                   
                   RESIDET(J,M) = ET(J,M) - ETUZTW(J,M)
                   
                   UZTWC = UZTWC - ETUZTW(J,M)
                   
                   ETUZFW(J,M) = 0.0
                   
                   IF (UZTWC.GE.0.0) GOTO 220
                   
                   ETUZTW(J,M) = ETUZTW(J,M) + UZTWC
                   
                   UZTWC = 0.0
                   
                   RESIDET(J,M) = ET(J,M) - ETUZTW(J,M)
                   
! --- COMPUTE ET FROM UZ FREE WATER STORAGE, RECALCULATE UZFWC, CALCULATE RESIDUAL ET DEMAND                   
                   
                   IF (UZFWC .GE. RESIDET(J,M)) GO TO 221
                   
                   ETUZFW(J,M) = UZFWC
                   
                   UZFWC = 0.0
                   
                   RESIDET(J,M) = RESIDET(J,M) - ETUZFW(J,M)
                   
                   GO TO 225
                   
221                ETUZFW(J,M) = RESIDET(J,M)

                   UZFWC = UZFWC - ETUZFW(J,M)
                   
                   RESIDET(J,M) = 0.0
                   
! --- REDISTRIBUTE WATER BETWEEN UZ TENSION WATER AND FREE WATER STORAGES

220                IF((UZTWC/UZTWM(I)).GE.(UZFWC/UZFWM(I))) GO TO 225

                   UZRAT=(UZTWC+UZFWC)/(UZTWM(I)+UZFWM(I))
                      
                   UZTWC = UZTWM(I) * UZRAT
                      
                   UZFWC = UZFWM(I) * UZRAT
                        
225                IF (UZTWC .LT. 0.00001) UZTWC = 0.0

                   IF (UZFWC .LT. 0.00001) UZFWC = 0.0
                   
                   
! --- COMPUTE ET FROM LZ TENSION WATER STORAGE, RECALCULATE LZTWC, CALCULATE RESIDUAL ET DEMAND

                   ETLZTW(J,M) = RESIDET(J,M) * (LZTWC / &
                  (UZTWM(I) + LZTWM(I)))
                   
                   LZTWC = LZTWC - ETLZTW(J,M)
                   
                   IF(LZTWC .GE. 0.0) GO TO 226
                   
                   ETLZTW(J,M) = ETLZTW(J,M) + LZTWC
                   
                   LZTWC = 0.0
                   
226                RATLZT = LZTWC / LZTWM(I)

                   RATLZ = (LZTWC + LZFPC + LZFSC) / &
                  (LZTWM(I) + LZFPM(I) + LZFSM(I))
     
                   IF (RATLZT .GE. RATLZ) GO TO 230
                  
                   LZTWC = LZTWC + (RATLZ - RATLZT)*LZTWM(I)

                   
                   LZFSC = LZFSC - (RATLZ - RATLZT)*LZTWM(I)
                   
                   IF(LZFSC .GE. 0.0) GO TO 230
                   
                   LZFPC = LZFPC + LZFSC
                   
                   LZFSC = 0.0
                   
230                IF (LZTWC .LT. 0.00001) LZTWC = 0.0


! --- CALCULATE TOTAL ET SUPPLIED BY UPPER AND LOWER LAYERS

                   ET(J,M) = ETUZTW(J,M) + ETUZFW(J,M) + ETLZTW(J,M)

! for check
!WRITE(99,*) 'ET=',ET(J,M),'ETUZTW=',ETUZTW(J,M) ,'ETUZFW=',ETUZFW(J,M),'ETLZTW=', ETLZTW(J,M)


                  IF (ET(J,M) .LT. 0.00001) ET(J,M) = 0.0
! *****************************************************************************************************
! *****************************************************************************************************
! --- COMPUTE PERCOLATION INTO SOIL WATER STORAGES AND SURFACE RUNOFF

!     --- COMPUTE WATER IN EXCESS OF UZ TENSION WATER CAPACITY (TWX)

                  TWX = INFIL + UZTWC - UZTWM(I)
           
                  IF (TWX.GE.0.0) THEN
                 
!     --- IF INFIL EXCEEDS UZ TENSION WATER CAPACITY, SET UZ TENSION WATER STORAGE TO CAPACITY, 
!         REMAINDER OF INFIL GOES TO UZFWC IF EXCEEDS UZFWC EXCESS GOES TO SURFACE RUNOFF

                     UZTWC = UZTWM(I)     
                
                     UZFWC = UZFWC + TWX
                
                     IF (UZFWC .GT. UZFWM(I)) THEN
                
                        SURFRO = UZFWC - UZFWM(I)
                
                        UZFWC = UZFWM(I)
                
                     ELSE
                
                        SURFRO = 0.0
                
                     ENDIF 

                  ELSE            
           

!     --- IF INFIL DOES NOT EXCEED UZ TENSION WATER CAPACITY, ALL INFIL GOES TO UZ TENSION WATER STORAGE

                    UZTWC = UZTWC + INFIL
                    SURFRO = 0.0
                  ENDIF
           
! --- COMPUTE PERCOLATION TO LZ IF FREE WATER IS AVAILABLE IN UZ

        
              IF (UZFWC .GT. 0.0) THEN
        

!     --- COMPUTE PERCOLATION DEMAND FROM LZ

                     PERCM = LZFPM(I) * LZPK(I) + LZFSM(I) * LZSK(I)
                
                     PERC = PERCM * (UZFWC/UZFWM(I))
                
                     DEFR=1.0-((LZTWC+LZFPC+LZFSC)/ (LZTWM(I)+LZFPM(I)+LZFSM(I)))
      
                
                     PERC = PERC * (1.0 + ZPERC(I) * (DEFR**REXP(I)))
            

!     --- COMPARE LZ PERCOLATION DEMAND TO UZ FREE WATER AVAILABLE AND COMPUTE ACTUAL PERCOLATION

                    IF (PERC .LT. UZFWC) THEN
                
                       UZFWC = UZFWC - PERC
                
                    ELSE
                
                       PERC = UZFWC
                
                       UZFWC = 0.0
                
                    ENDIF
            
!      --- CHECK TO SEE IF PERC EXCEEDS LZ TENSION AND FREE WATER DEFICIENCY, IF SO SET PERC TO LZ DEFICIENCY


                    LZDEF = (LZTWC + LZFPC + LZFSC) - (LZTWM(I) + LZFPM(I) + LZFSM(I)) + PERC
                    
                    IF (LZDEF .GT. 0.0) THEN
                    
                       PERC = PERC - LZDEF
          
                       UZFWC = UZFWC + LZDEF
                       
                    ENDIF
                
                
! --- DISRIBUTE PERCOLATED WATER INTO THE LZ STORAGES AND COMPUTE THE REMAINDER IN UZ FREE WATER STORAGE AND RESIDUAL AVAIL FOR RUNOFF
   

!     --- COMPUTE PERC WATER GOING INTO LZ TENSION WATER STORAGE AND COMPARE TO AVAILABLE STORAGE

                    PERCT = PERC * (1.0 - PFREE(I))
                
                    IF ((PERCT + LZTWC) .GT. LZTWM(I)) THEN
                
!     --- WHEN PERC IS GREATER THAN AVAILABLE TENSION WATER STORAGE, SET TENSION WATER STORAGE TO MAX, REMAINDER OF PERC GETS EVALUATED AGAINST FREE WATER STORAGE

                       PERCF = PERCT + LZTWC - LZTWM(I)
                
                       LZTWC = LZTWM(I)
                
                    ELSE
                
!     --- WHEN PERC IS LESS THAN AVAILABLE TENSION WATER STORAGE, UPDATE TENSION WATER STORAGE

                       LZTWC = LZTWC + PERCT
                
                       PERCF = 0.0
                
                    ENDIF
                
!     --- COMPUTE TOTAL PERC WATER GOING INTO LZ FREE WATER STORAGE

                    PERCF = PERCF + PERC * PFREE(I)            

                    IF(PERCF .GT. 0.0) THEN
                
!     --- COMPUTE RELATIVE SIZE OF LZ PRIMARY FREE WATER STORAGE COMPARED TO LZ TOTAL FREE WATER STORAGE

                       HPL = LZFPM(I) / (LZFPM(I) + LZFSM(I))
                
!     --- COMPUTE LZ PRIMARY AND SECONDARY FREE WATER CONTENT TO CAPACITY RATIOS

                       RATLP = LZFPC / LZFPM(I)
                
                       RATLS = LZFSC / LZFSM(I)
                
!     --- COMPUTE FRACTIONS AND PERCENTAGES OF FREE WATER PERC TO GO TO LZ PRIMARY STORAGE

                       FRACP = (HPL * 2.0 * (1.0 - RATLP)) &
                      / ((1.0 - RATLP) + (1.0 - RATLS))
                
                       IF (FRACP .GT. 1.0) FRACP = 1.0

                          PERCP = PERCF * FRACP
                
                          PERCS = PERCF - PERCP
                
!     --- COMPUTE NEW PRIMARY AND SECONDARY STORAGE

!         --- COMPUTE NEW SECONDARY FREE WATER STORAGE

                          LZFSC = LZFSC + PERCS

                          IF(LZFSC .GT. LZFSM(I)) THEN
                
!         --- IF NEW SECONDARY FREE WATER STORAGE EXCEEDS CAPACITY SET SECONDARY STORAGE TO CAPACITY AND EXCESS GOES TO PRIMARY FREE WATER STORAGE

                             PERCS = PERCS - LZFSC + LZFSM(I)
                
                             LZFSC = LZFSM(I)
                          
                          ENDIF
                
            
!         --- IF NEW LZ SECONDARY FREE WATER STORAGE IS LESS THAN CAPACITY MOVE ON TO COMPUTE NEW PRIMARY FREE WATER STORAGE


                       LZFPC = LZFPC + (PERCF - PERCS)

                
                       IF (LZFPC .GT. LZFPM(I)) THEN

!             --- IF LZ FREE PRIMARY WATER STORAGE EXCEEDS CAPACITY SET PRIMARY STORAGE TO CAPACITY AND EVALUATE EXCESS AGAINST LZ TENSION WATER STORAGE

                          LZTWC = LZTWC + LZFPC - LZFPM(I)
                
                          LZFPC = LZFPM(I)
                
                          IF (LZTWC .GT. LZTWM(I)) THEN

!            --- IF LZ TENSION WATER EXCEEDS CAPACITY EVALUATE EXCESS AGAINST UZ FREE WATER CAPACITY AND SET LZ TENSION WATER STORAGE TO CAPACITY

                             UZFWC = UZFWC + LZTWC - LZTWM(I)
                
                             LZTWC = LZTWM(I)
                             
                          ENDIF
                          
                       ENDIF
                       
                    ENDIF
                
               ENDIF
         
! ***************************************************************************************************** 
! *****************************************************************************************************                
! --- COMPUTE BASEFLOW AND UPDATE LZ PRIMARY AND SECONDARY FREE WATER STORAGES

                
!      --- COMPUTE PRIMARY BASEFLOW AND COMPARE TO AVAILABLE FREE PRIMARY STORAGE

                 PBF = LZFPC * LZPK(I)
                
                 LZFPC = LZFPC - PBF
                
                 IF (LZFPC .LE. 0.0001) THEN 
                
                    PBF = PBF + LZFPC
                
                    LZFPC = 0.0
                
                 ENDIF
                

!      --- COMPUTE SECONDARY BASEFLOW AND COMPARE TO AVAILABLE FREE PRIMARY STORAGE

                 SBF = LZFSC * LZSK(I)
                
                 LZFSC = LZFSC - SBF
                
                 IF (LZFSC .LE. 0.0001) THEN
                
                   SBF = SBF + LZFSC
                
                   LZFSC = 0.0
                
                 ENDIF                
                 

! *****************************************************************************************************
! --- COMPUTE INTERFLOW FROM UZ

                 INF = UZFWC * UZK(I)
                
                 IF (UZFWC .LT. INF) THEN
                 
                    INF = UZFWC
                    
                    UZFWC = 0.0
                 
                 ELSE
                    
                    UZFWC = UZFWC - INF
                
                 ENDIF

        ENDIF
        
!Print *, 'Finish calculate Water balances and Soil Water Content'        
! **************************----Finish calculate Water balances and Soil water--------******************************************************

! *****************************************************************************************************
    ! Calculate GEP based on ET and the equation
        IF (LC_N .LE. 0) THEN 
            GEP(J,M)=0.0
            RECO(J,M)=0.0
            goto 6101
        ENDIF
        
        GEP(J,M) = wue_k(LC_N) * ET(J,M)

        IF (GEP(J,M) .LE. 0)   THEN
            GEP(J,M)=0.0 
        ENDIF         
        !print*,I,LADUSE(I)
        RECO(J,M)= (reco_inter(LC_N) + reco_slope(LC_N) * GEP(J,M)*MNDAY)/MNDAY
        
6101        NEE(J,M)=  RECO(J,M)- GEP(J,M) 


! **************************----Finish calculate Carbon balances--------************************************************
        
                RECO(J,M) = RECO(J,M)/MNDAY 
                                                            
                NEE(J,M) = -GEP(J,M) + RECO(J,M)
                
! for check
!print *, I,J,M,' LANDUSE=', LADUSE(I),' ET=', ET(J,M),' GEP=', GEP(J,M),' RECO=', RECO(J,M)
                                    
! --- COMPUTE FRACTION OF EACH WATER BALANCE COMPONENT AND GEP FOR EACH LAND COVER

! *****************************************************************************************************
! -- CALCULATE THE daily GEP

               GEPTEMP = GEPTEMP + GEP(J,M)  
               RECOTEMP = RECOTEMP + RECO(J,M)            
               NEETEMP = NEETEMP + NEE(J,M)
                            

! *****************************************************************************************************
! --- CALCULATE THE daily AET
               
               AETTEMP = AETTEMP + ET(J,M)
               
! *****************************************************************************************************
!--- CALCULATE THE daily SURFACE RUNOFF
              
               RUNOFFTEMP = RUNOFFTEMP + SURFRO
               
! *****************************************************************************************************
!--- CALCULATE THE DAILY PRIMARY BASEFLOW
              
               PBFTEMP = PBFTEMP + PBF              
               
! *****************************************************************************************************
!--- CALCULATE THE DAILY SECONDARY BASEFLOW
              
               SBFTEMP = SBFTEMP + SBF                

! *****************************************************************************************************
!--- CALCULATE THE DAILY INTERFLOW
              
               IFTEMP = IFTEMP + INF                   
! *****************************************************************************************************

    !        RUNLAND(I,J_S,M,DAY) = SURFRO + PBF + SBF + INF
      !      ETLAND(I,J_S,M,DAY) = ET(J,M)
       !     GEPLAND(I,J_S,M,DAY) = GEP(J,M)
            
!--- calculate the monthly total soil moisture 
              
              TAUZTWC = TAUZTWC + UZTWC
              
              TAUZFWC = TAUZFWC + UZFWC
              
              TALZTWC = TALZTWC + LZTWC
              
              TALZFPC = TALZFPC + LZFPC
              
              TALZFSC = TALZFSC + LZFSC
              
              TASM = TASM + (UZTWC+UZFWC+LZTWC+LZFPC+LZFSC)
                      
!40         CONTINUE
 
100        CONTINUE


           AET(I,J,M) = AETTEMP        
           RUNOFF(I,J,M) = RUNOFFTEMP
           PRIBF(I,J,M) = PBFTEMP
           SECBF(I,J,M) = SBFTEMP
           INTF(I,J,M) = IFTEMP
           SP(I,J,M)=SNOWPACK
            
!! --  AVERAGE soil moisture
                   
           AVSMC(I,J,M)= TASM/MNDAY
           AVUZTWC(I,J,M) = TAUZTWC/MNDAY
           AVUZFWC(I,J,M) = TAUZFWC/MNDAY
           AVLZTWC(I,J,M) = TALZTWC/MNDAY
           AVLZFPC(I,J,M) = TALZFPC/MNDAY
           AVLZFSC(I,J,M) = TALZFSC/MNDAY
           
!--- End of month soil moisture 
              
              EMUZTWC(I,J,M) = UZTWC
              
              EMUZFWC(I,J,M) = UZFWC
              
              EMLZTWC(I,J,M) = LZTWC
              
              EMLZFPC(I,J,M) = LZFPC
              
              EMLZFSC(I,J,M) = LZFSC
              
              EMSMC(I,J,M) = UZTWC+UZFWC+LZTWC+LZFPC+LZFSC           
  
           
                   
           IF (RUNOFF(I,J,M) .LT. 0.) THEN
           
           RUNOFF(I,J,M)=0.
           
           ENDIF            
       
           GEPM(I,J,M) = GEPTEMP
           RECOM(I,J,M)  = RECOTEMP
           NEEM(I,J,M) = NEETEMP

! -- STREAMFLOW IN MILLION M3 FOR EACH HUC FOR MONTH M. HUCAREA IN SQ. METERS 
        STRFLOW(I, J, M) = (RUNOFF(I,J,M) + PRIBF(I,J,M) + SECBF(I,J,M) + INTF(I,J,M))*1/1000. 
        ! 64=8*8 8 is the area of each cell (KM2)

      RETURN
      END
