
/*------------------------------------------------------------------------
    File        : task2.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : vandanad
    Created     : Thu Jun 29 21:38:03 IST 2023
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

DEFINE STREAM   strReport.
DEFINE VARIABLE lcFilePath  AS CHARACTER    NO-UNDO FORMAT 'X(100)'.
DEFINE VARIABLE lcFileName  AS CHARACTER    NO-UNDO.
DEFINE VARIABLE lcDate      AS CHARACTER    NO-UNDO.
DEFINE VARIABLE lcTime      AS CHARACTER    NO-UNDO.
DEFINE VARIABLE liAge       AS INTEGER      NO-UNDO.
DEFINE VARIABLE lcFirstName AS CHARACTER    NO-UNDO.
DEFINE VARIABLE lclastname  AS CHARACTER    NO-UNDO.
DEFINE VARIABLE lcEmpCnt    AS INTEGER      NO-UNDO.
DEFINE VARIABLE lcFamCnt    AS INTEGER      NO-UNDO.
DEFINE VARIABLE lcBirthDate AS CHARACTER    NO-UNDO.

SET lcFilePath.

ASSIGN 
    lcFilePath =    lcFilePath + "\batask\task2\report\"
    lcDate     =    STRING(YEAR(TODAY) * 10000 + MONTH(TODAY) * 100  + DAY(TODAY))
    lcTime     =    STRING(TIME, "HH:MM:SS")
    lcTime     =    ENTRY(1,lcTime,':') + ENTRY(2,lcTime,':') + ENTRY(3,lcTime,':')
    lcFileName =    "EmployeesReport_" + lcDate + '_' + lcTime + ".csv".

OUTPUT STREAM strReport TO VALUE(lcFilePath + lcFileName).
EXPORT STREAM strReport DELIMITER ';' "EmpNum" "Type" "FirstName" "LastName" "BirthDate".

FOR EACH Employee NO-LOCK
    BY Employee.Birthdate:
        
    liAge = YEAR(TODAY) - YEAR(Employee.Birthdate).
    
    IF liAge > 40 THEN NEXT.
    
    IF NOT CAN-FIND(FIRST Family WHERE Family.EmpNum = Employee.EmpNum) THEN NEXT.
       
    EXPORT STREAM strReport DELIMITER ';' Employee.EmpNum "Employee" Employee.FirstName Employee.LastName ISO-DATE(Employee.BirthDate).
    
    lcEmpCnt = lcEmpCnt + 1.
    
    FOR EACH Family NO-LOCK
        WHERE Family.EmpNum = Employee.empnum
        BY birthdate DESCENDING:
            
        ASSIGN lcFirstName  =   ENTRY(1, Family.RelativeName, " ")
               lcLastName   =   ENTRY(2, Family.RelativeName, " ")
               lcFamCnt     =   lcFamCnt + 1.
                
        EXPORT STREAM strReport DELIMITER ';' "" Family.Relation lcFirstName lcLastName ISO-DATE(Family.BirthDate).
        
    END.
           
END.

PUT STREAM strReport UNFORMATTED "Total Employees - " + STRING(lcEmpCnt) + '    ' +  " Total Family Members - " + STRING(lcFamCnt) SKIP.

OUTPUT STREAM strReport CLOSE.