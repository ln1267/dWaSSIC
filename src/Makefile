FC= gfortran
OBJ= GLOBALVARS.o GENERAL.o PET.o OUTPUT.o SUMMARY.o WARMUP.o WATERBAL.o WATERBAL_MON_LC.o WATERBAL_MON.o

PRGENV= ${PE_ENV}

ifeq ($(PRGENV),INTEL)
	OMPFLAG=-openmp
	DEBUG=-g
else ifeq ($(PRGENV),GNU)
	OMPFLAG=-fopenmp
	DEBUG=-g
else ifeq ($(PRGENV),CRAY)
	OMPFLAG=-homp
	DEBUG=-G2
else
	OMPFLAG=-fopenmp
	DEBUG=-g
#	CRAY_REVEAL="-h profile_generate"

endif
DEBUG = -g -fcheck=all -Wall
FCFLAGS = $(DEBUG) $(CRAY_REVEAL)
FFLAGS = $(DEBUG)

all: $(OBJ)
	$(FC) $(FFLAGS)  $+ $(OMPFLAG) -o dWaSSIC
%.o: %.F90
	$(FC) $(FCFLAGS) -c $(OMPFLAGS) $<

clean:
	rm *.o *.mod dWaSSIC fort.*
