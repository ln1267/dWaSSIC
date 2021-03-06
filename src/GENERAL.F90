! This is the latest version of Gridded daily WASSIC for parellel simulating
PROGRAM WaSSICBZB 
         
    use common_var

    implicit none 

    INTEGER ICELL,ICOUNT,IYEAR,MONTHD(12),MONTHL(12)
    INTEGER YEAR,NDAY,IM,MNDAY
      
    ! --- Number of days for each month during regular year
    DATA MONTHD/31,28,31,30,31,30,31,31,30,31,30,31/

    ! --- Number of days for each month during leap year
    DATA MONTHL/31,29,31,30,31,30,31,31,30,31,30,31/
      
    ! --- For reading in the command line arguments 
    CHARACTER(len=256),ALLOCATABLE:: ARGS(:) 
    CHARACTER(256) ARCH,INPATH,OUTPATH
    INTEGER (kind=4) iargc,INDX
    
    ! --- Write introductory information to screen
    WRITE(*,10)
10 FORMAT(' *************************************************'//,&
            '                   *** Revised Gridded OR CATCHMENT SCALE Monthly WaSSI-CB by Ning Liu  ***'//,&
       '   Water Supply Stress Index Modeling System'//,&
       ' Eastern Forest Environmental Threat Assessment Center'/,&
         ' USDA Forest Service Southern Research Station '/,&
            ' Raleigh, NC'//,&
            ' Sep 2018 -'//)
 

Print*, "Please set the first parameter as '1' and '/' in you directory if you are using Linux system",NEW_LINE('A')

! --- For reading global setting information  
    ALLOCATE (ARGS(iargc()))
    DO INDX=1,iargc()
        CALL getarg(INDX, ARGS(INDX))
    END DO
    
    ARCH=ARGS(1)
    INPATH=ARGS(2)
    OUTPATH=ARGS(3)

    !WRITE(*,*) 'ARCH set to ',TRIM(ARCH)
    WRITE(*,*) 'INPUT files will be read from directory ',TRIM(INPATH),NEW_LINE('A')
    WRITE(*,*) 'OUTPUT files will be written in directory ',TRIM(OUTPATH),NEW_LINE('A')    
    
    IF (ARCH == '1')  then 
	
        Print*,"LINUX system was selected",NEW_LINE('A')
        !!! This is for Linux  
        
        !--Open Input files----------------------------------------------
        OPEN(1,FILE=TRIM(INPATH)//'/GENERAL.TXT')
        OPEN(2,FILE=TRIM(INPATH)//'/CELLINFO.TXT') 
        !OPEN(3,FILE=TRIM(INPATH)//'/VEGINFO.TXT') ! DYNAMIC VEGETATION TYPE INPUT
        OPEN(4,FILE=TRIM(INPATH)//'/CLIMATE.TXT')
        OPEN(7,FILE=TRIM(INPATH)//'/SOILINFO.TXT')
        OPEN(8,FILE=TRIM(INPATH)//'/LANDLAI.TXT')
        !OPEN(9,FILE=TRIM(INPATH)//'/WUE_input.TXT')
        OPEN(9,FILE=TRIM(INPATH)//'/WUE_theory.csv')
        OPEN(10,FILE=TRIM(INPATH)//'/ET_theory.csv')
        ! ---Open Output files---------------------------------------- 
        OPEN(77,FILE=TRIM(OUTPATH)//'/BASICOUT.TXT')
        OPEN(78,FILE=TRIM(OUTPATH)//'/MONTHFLOW.TXT')
        OPEN(79,FILE=TRIM(OUTPATH)//'/ANNUALFLOW.TXT')
        OPEN(80,FILE=TRIM(OUTPATH)//'/HUCFLOW.TXT')
        OPEN(400,FILE=TRIM(OUTPATH)//'/MONTHCARBON.TXT')
        OPEN(500,FILE=TRIM(OUTPATH)//'/ANNUALCARBON.TXT')
        OPEN(600,FILE=TRIM(OUTPATH)//'/HUCCARBON.TXT')
        OPEN(900,FILE=TRIM(OUTPATH)//'/SOILSTORAGE.TXT')

    ELSEIF (ARCH /= '1') THEN
	
        Print*,"Windows system was selected",NEW_LINE('A')
    
	!!! This is for Windows
    !!--Open Input files------------------ 
        OPEN(1,FILE=TRIM(INPATH)//'\GENERAL.TXT')
        OPEN(2,FILE=TRIM(INPATH)//'\CELLINFO.TXT') 
        !OPEN(3,FILE=TRIM(INPATH)//'\VEGINFO.TXT') ! DYNAMIC VEGETATION TYPE INPUT
        OPEN(4,FILE=TRIM(INPATH)//'\CLIMATE.TXT')
        OPEN(7,FILE=TRIM(INPATH)//'\SOILINFO.TXT')
        OPEN(8,FILE=TRIM(INPATH)//'\LANDLAI.TXT')
        ! ! ---Open Output files---------------------------------------- 
        !
        OPEN(77,FILE=TRIM(OUTPATH)//'\BASICOUT.TXT')
        OPEN(78,FILE=TRIM(OUTPATH)//'\MONTHFLOW.TXT')
        OPEN(79,FILE=TRIM(OUTPATH)//'\ANNUALFLOW.TXT')
        OPEN(80,FILE=TRIM(OUTPATH)//'\HUCFLOW.TXT')
        OPEN(400,FILE=TRIM(OUTPATH)//'\MONTHCARBON.TXT')
        OPEN(500,FILE=TRIM(OUTPATH)//'\ANNUALCARBON.TXT')
        OPEN(600,FILE=TRIM(OUTPATH)//'\HUCCARBON.TXT')
        OPEN(900,FILE=TRIM(OUTPATH)//'\SOILSTORAGE.TXT')
     
    ELSE

        Print*,"Please input 1 for LINUX or 2 for Windows after the program: eg './aout 1 ../in ../out'"
    ENDIF  
 
   WRITE(*,30)
   30 FORMAT('       *** PROGRAM IS RUNNING, PLEASE WAIT ***'//)
 
!  --------- Read input data -------------------------------
    CALL RPSDF       ! Set up column headings for each output files
    
    CALL RPSWUE            ! Read WUE parameters
    
    CALL RPSINT      ! Read Landuse, elevation and Soil parameters
          
    print*,"finish read Land cover  data",NEW_LINE('A')
      
    CALL RPSLAI     ! Read LAI data
      
    print*,"finish read LAI  data",NEW_LINE('A')
      
    CALL RPSCLIMATE  ! Read calimate data

    !  CALL  RPSVALID   ! Read Runoff validation data

    print*,"finish read Climate data",NEW_LINE('A')

    WRITE(77,2051)
2051  FORMAT(/'SOIL PARAMETERS FOR EACH SIMULATION CELL'/)

!          
!----------------------Modelling for each Cell and year start------------------------------------  

!$OMP PARALLEL DO DEFAULT(SHARED) PRIVATE(ICELL,IYEAR,IM,MNDAY)          
    DO 200 ICELL=1,NGRID       
        
        ICOUNT=0 

        DO 300 IYEAR=1, NYEAR_S+NWARMUP
            YEAR = YSTART + ICOUNT-NWARMUP
            ICOUNT=ICOUNT+1 
            NDAY = 365
            IF(YEAR/4*4.NE.YEAR) GO TO 110
            IF(YEAR/400*400.EQ.YEAR) GO TO 110
            NDAY=366   
             
110         CONTINUE 

            DO 400 IM=1, 12
               IF (NDAY .EQ. 365) THEN
                 MNDAY=MONTHD(IM)
               ELSE
                 MNDAY=MONTHL(IM)
               ENDIF
        
               CALL WARMPET(ICELL, IYEAR, IM, MNDAY)  ! Caculate MONTHLY PET AND POTENTIAL AET 

               IF (modelscale .eq. 0) THEN
               
                    CALL WATERBAL_MON_LC(ICELL, IYEAR, IM) ! monthly SMA-SAC
                    !CALL WATERBAL_LC(ICELL, IYEAR, IM, MNDAY) ! Average daily SMA-SAC
                ELSE
                    CALL WATERBAL_MON(ICELL, IYEAR, IM) ! Caculate MONTHLY GPP and ET
                ENDIF
400         CONTINUE ! END LOOP MONTH        

            CALL SUMMARY_MONTH(ICELL,IYEAR)
300        CONTINUE  ! END LOOP YEAR

!     CALCULATE AVERAGE WATER BALANCE COMPONENTS FROM IYSTART TO IYEND
!     WRITE TO SUMMARRUNOFF.TXT   
 
        CALL SUMMARY_YEAR(ICELL) 
        CALL SUMMARY_CABON(ICELL)

200 CONTINUE  ! END LOOP GRID
!$OMP END PARALLEL DO

! This is for output result
    PRINT *, 'WATER BALANCE SECTION SUCCEEDED! and RUNNING OUTPUT'
    
    CALL OUTPUT !(ICELL,IYEAR)  ! Output Annual water and carbon balances

    PRINT *, '-------------PROGRAM RUN ENDS----------------!'
    Stop
    
END

