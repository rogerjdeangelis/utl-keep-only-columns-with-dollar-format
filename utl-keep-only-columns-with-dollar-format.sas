Keep only columns with specified format

StaackOverflow
https://stackoverflow.com/questions/53265289/keep-columns-with-specific-format

Since sql dictionaries are so slow on EG servers, here are other solutions.


  Four solutions

      1. vformat and vname
      2. attrn varfmt varname (SCL)
      3. put (_all_)  then parse for '$'
      4. proc contents


INPUT
=====

  sashelp.cars

  Variable       Type     Format

  MAKE           Char13
  MODEL          Char40
  TYPE           Char8
  ORIGIN         Char6
  DRIVETRAIN     Char5
  MSRP           Num8    DOLLAR8.   (keeo pnly these two)
  INVOICE        Num8    DOLLAR8.
  ENGINESIZE     Num8
  CYLINDERS      Num8
  HORSEPOWER     Num8
  MPG_CITY       Num8
  MPG_HIGHWAY    Num8
  WEIGHT         Num8
  WHEELBASE      Num8
  LENGTH         Num8


RULES (Keep only variables with dollar format ieMRSP INVOICE)

    Variables in Creation Order

  Variable    Type    Len    Format

  MSRP        Num       8    DOLLAR8.
  INVOICE     Num       8    DOLLAR8.


EXAMPLE OUTPUT
--------------

 WANT total obs=428

   MSRP      INVOICE

  $36,945    $33,337
  $23,820    $21,761
  $26,990    $24,647
  $33,195    $30,299
  $43,755    $39,014
  $46,100    $41,100
  ...

   \
PROCESS
=======

 1. vformat and vname
 ---------------------

    data want;

     if _n_=0 then do; %let rc = %sysfunc(dosubl('
        data _null_;
           length dlr $200;
           set sashelp.cars(keep=_numeric_ obs=1);
           array nums[*] _numeric_;
           do idx=1 to dim(nums);
              if substr(vformat(nums[idx]),1,6)="DOLLAR" then
                  dlr=catx(" ",dlr,vname(nums[idx]));
           end;
           call symputx("dlr",dlr);
        run;quit;
        '));
      end;

      set sashelp.cars(keep=&dlr);

    run;quit;


 2. attrn(sashelp.cars,NVARS)
 ----------------------------

    %symdel dlr / nowarn;
    data want;

       set sashelp.cars(where=(0=%sysfunc(dosubl('
         data _null_;
            length dlr $200;
            dsd=open('sashelp.cars(keep=_numeric_)');
            do i=1 to attrn(dsd,'nvars');
               vfmt=varfmt(dsd,i);
               if length(vfmt) > 6 and vfmt=:"DOLLAR" then
                  dlr=catx(" ",dlr,varname(dsd,i));
            end;
             call symputx("dlr",dlr);
           rc=close(dsd);
         run;quit;
         '))));

         keep &dlr;
    run;quit;


3. put (_all_)
---------------


    %symdel kep / nowarn;
    options nolabel;
    data want;
     if _n_=0 then do; %let rc = %sysfunc(dosubl('
        filename inp temp;
        data _null_;
           file inp;
           set sashelp.cars(keep=_numeric_ obs=1);
           put (_all_) (= /);
        run;quit;
        data _null_;
          retain kep;
          length kep $4096;
          infile inp end=dne;
             input;
             if indexc(_infile_,"$")>0 then
                kep=catx(" ",kep,scan(_infile_,1,"="));
           if dne then call symputx("kep",kep);
        run;quit;
        filename inp clear;
        '));
     end;

        set sashelp.cars(keep=&kep);

     run;quit;


4. proc contents

   %symdel kep / nowarn;
   data want;

        *get the meta data;
        if _n_=0 then do; %let rc = %sysfunc(dosubl('
           ods output variables=havCon;
           proc contents data=sashelp.cars;
           run;quit;
           data _null_;
             length kep $4096;
             retain kep;
             set havCon(where=(index(format,'DOLLAR'))) end=dne;
             kep =catx(" ",kep,variable);
             if dne then call symputx("kep",kep);
           run;quit;
           '));
        end;

        set sashelp.cars(keep=&kep);

   run;quit;

