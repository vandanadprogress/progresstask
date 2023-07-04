
/*------------------------------------------------------------------------
    File        : task1.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : vandanad
    Created     : Fri Jul 2 01:29:48 IST 2023
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */
DEFINE STREAM sFile.
DEFINE STREAM sLog.
DEFINE VARIABLE lcRelativeName AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcDetails      AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcDetFormat    AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcFilePath     AS CHARACTER NO-UNDO FORMAT 'x(100)'.
DEFINE VARIABLE lcFileName     AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcInputFile    AS CHARACTER NO-UNDO.
DEFINE VARIABLE ldaBirthDate   AS DATE      NO-UNDO FORMAT "99/99/9999".
DEFINE VARIABLE liOkCnt        AS INTEGER   NO-UNDO.
DEFINE VARIABLE liErrCnt       AS INTEGER   NO-UNDO.
DEFINE VARIABLE lcline         AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcLogFileName  AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcLogFilePath  AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcDate         AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcTime         AS CHARACTER NO-UNDO.
DEFINE VARIABLE liEmpRec       AS INTEGER   NO-UNDO.
DEFINE VARIABLE liFamRec       AS INTEGER   NO-UNDO.
DEFINE VARIABLE liEmpCnt       AS INTEGER   NO-UNDO.
DEFINE VARIABLE liFamCnt       AS INTEGER   NO-UNDO.

DEFINE TEMP-TABLE ttDetails
    FIELD EmpNum    AS INT
    FIELD Relation  AS CHAR
    FIELD FirstName AS CHAR
    FIELD LastName  AS CHAR
    FIELD Birthdate AS CHAR.

DEFINE BUFFER bfFamily FOR Family.

/* ***************************  Main Block  *************************** */

FUNCTION fISOToDate RETURNS DATE
    (INPUT icDate AS CHAR):
        
    DEFINE VARIABLE idaDate AS DATE NO-UNDO FORMAT "99/99/9999".
        
    ASSIGN 
        icDate  = REPLACE(icDate,'-', "").
        idaDate = DATE(INT(SUBSTRING(icDate,5,2)),INT(SUBSTRING(icDate,7,2)),INT(SUBSTRING(icDate,1,4))).
           
    RETURN idaDate.
    
END FUNCTION.

FUNCTION fDateToISO RETURNS CHARACTER():
        
    DEFINE VARIABLE ldtDate2ISO AS DATETIME-TZ NO-UNDO.
      
    ldtDate2ISO = DATETIME(TODAY,TIME * 1000).
           
    RETURN ISO-DATE(ldtDate2ISO).
    
END FUNCTION.

FUNCTION fLogLine RETURNS LOGICAL
    (icMessage AS CHARACTER):

    PUT STREAM sLog UNFORMATTED fDateToISO() ' - '
        lcLine ' - '
        icMessage SKIP.
        
END FUNCTION.

FUNCTION fLog RETURNS LOGICAL
    (icMessage AS CHARACTER, lOk AS LOGICAL):
   
    fLogLine(icMessage).
    IF lOk THEN
        liOkCnt = liOkCnt  + 1 .
    ELSE
        liErrCnt = liErrCnt  + 1 .
         
END FUNCTION.

SET lcFilePath.

ASSIGN 
    lcFilePath    = lcFilePath  +   "\batask\task1\"
    lcLogFilePath = lcFilePath  +   "log\"
    lcDate        = STRING(YEAR(TODAY) * 10000 + MONTH(TODAY) * 100  + DAY(TODAY))
    lcTime        = STRING(TIME, "HH:MM:SS")
    lcTime        = ENTRY(1,lcTime,':') + ENTRY(2,lcTime,':') + ENTRY(3,lcTime,':').

INPUT FROM OS-DIR(lcFilePath).

REPEAT:
    IMPORT lcDetails.
    
    lcFileName = lcFilePath + lcDetails.
    
    IF SEARCH(lcFileName) EQ ? THEN NEXT.
    
    IF NOT(lcDetails MATCHES "Employees*") THEN NEXT.
    
    RUN pReadEmployeesRecords.
    
    RUN pCheckandUpdateRecords.
    
    IF liEmpRec NE liEmpCnt OR liFamCnt EQ liFamRec  THEN
    DO:
        lcLine =    "Employee and family records does not match".
        fLog("ERROR: " + "Inconsistent Input Records",YES).
        NEXT.
    END.
    
    PUT STREAM sLog UNFORMATTED 
        "Records Updated: " + STRING(liOkCnt) ' ; ' "Error Records: " + STRING(liErrCnt) SKIP.     
END.

INPUT STREAM sFile CLOSE.
OUTPUT STREAM sLog CLOSE.

PROCEDURE pReadEmployeesRecords:
    
    lcLogFileName = lcLogFilePath + "Family_Import.log".
    
    OUTPUT STREAM sLog TO VALUE(lcLogFileName).
    
    PUT STREAM sLog UNFORMATTED "Reading File: " + lcFileName + lcDate + lcTime SKIP.
    
    INPUT STREAM sFile FROM VALUE(lcFileName).

    IMPORT STREAM sFile UNFORMATTED lcDetFormat.
   
    REPEAT:

        IMPORT STREAM sFile DELIMITER ';' lcLine.
        
        IF NUM-ENTRIES(lcLine,';') < 5 THEN
        DO:
            IF TRIM(ENTRY(1,lcLine,';')) NE "" THEN
            DO: 
                ASSIGN liEmpRec     =   INT(TRIM(ENTRY(2,lcLine,';'),'"'))
                       liFamRec     =   INT(TRIM(ENTRY(4,lcLine,';'),'"')).
                fLog("TRACE: " + "Footer Details", NO).
            END.
            IF TRIM(ENTRY(1,lcLine,';')) EQ "" THEN
                fLog("ERROR: " + "Invalid Input Format",NO).
            NEXT.
        END. 
        
        CREATE  ttDetails.
        ASSIGN  
            ttDetails.EmpNum    = INT(TRIM(ENTRY(1,lcLine,';'),'"'))
            ttDetails.Relation  = TRIM(ENTRY(2,lcLine,';'),'"')
            ttDetails.FirstName = TRIM(ENTRY(3,lcLine,';'),'"')
            ttDetails.LastName  = TRIM(ENTRY(4,lcLine,';'),'"')                
            ttDetails.BirthDate = TRIM(ENTRY(5,lcLine,';'),'"') NO-ERROR.
            
        IF ERROR-STATUS:ERROR THEN
        DO:
            lcLine = ERROR-STATUS:GET-MESSAGE(1).
            fLog("ERROR: " + "Invalid Input Details",NO).
            NEXT.
        END.
    END.
          
END PROCEDURE.

PROCEDURE pCheckandUpdateRecords:
    
    FOR EACH ttDetails
        WHERE ttDetails.Relation EQ "Employee"
        BREAK BY ttDetails.Relation:
            
            liEmpCnt = liEmpCnt + 1.
            
            MESSAGE ttDetails.FirstName ttDetails.LastName ttDetails.Relation.
    
        FIND FIRST Employee NO-LOCK
             WHERE Employee.EmpNum =   ttDetails.EmpNum NO-ERROR.
        IF NOT AVAILABLE Employee THEN 
        DO:
            lcLine = ttDetails.FirstName + ";" + ttDetails.LastName + ";" + ttDetails.Relation + ";" + ttDetails.Birthdate.
            fLog("FATAL: " + "Employee Details not available",NO).            
            NEXT.
        END.
        
        RUN pUpdateFamilyRec.
               
    END.

END PROCEDURE.

PROCEDURE pUpdateFamilyRec:
    
    FOR EACH  ttDetails 
        WHERE ttDetails.LastName  =  Employee.LastName
          AND ttDetails.Relation  <> "Employee":     
                                  
        ASSIGN 
            lcRelativeName = TRIM(ttDetails.Firstname + " " + ttDetails.LastName)
            ldaBirthDate   = fISOToDate(ttDetails.Birthdate)
            lcLine         = ttDetails.FirstName + ";" + ttDetails.LastName + ";" + ttDetails.Relation + ";" + ttDetails.Birthdate.             
                        
        FIND FIRST Family NO-LOCK
             WHERE Family.EmpNum          = Employee.EmpNum
               AND Family.RelativeName    = lcRelativeName NO-ERROR.                                      
        IF AVAILABLE Family THEN                
        DO:
            IF ldaBirthDate <> Family.BirthDate OR ttDetails.Relation <> Family.Relation THEN
            DO:
                FIND bfFamily EXCLUSIVE-LOCK WHERE ROWID(bfFamily) = ROWID(Family) NO-ERROR.
                         
                ASSIGN  
                    bfFamily.BirthDate = ldaBirthDate
                    bfFamily.Relation  = ttDetails.Relation.
                                
                RELEASE bfFamily.
                        
                fLog("WARN: Family record updated.", YES).
            END.                   
            ELSE
                fLog("FATAL: Family record already exists.", NO).  
                                  
        END.  
                
        ELSE IF NOT AVAILABLE Family THEN
        DO:
            CREATE bfFamily.
            ASSIGN bfFamily.EmpNum       = Employee.EmpNum
                   bfFamily.RelativeName = lcRelativeName
                   bfFamily.Relation     = ttDetails.Relation
                   bfFamily.BirthDate    = ldaBirthDate
                   bfFamily.BenefitDate  = TODAY.
                                                        
            fLog("INFO: Family record created.", YES).                           
        END. 
    END.

END PROCEDURE.