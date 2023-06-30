
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

define stream   strReport.
define variable lcFilePath as character no-undo format 'X(100)'.
define variable lcFileName as character no-undo.
define variable lcDate     as character no-undo.
define variable lcTime     as character no-undo.
define variable liAge      as integer   no-undo.
define variable lcFirstName as character no-undo.
define variable lclastname  as character no-undo.
define variable lcEmpCnt    as integer no-undo.
define variable lcFamCnt    as integer no-undo.
define variable lcBirthDate as character no-undo.

set lcFilePath.

assign 
    lcFilePath =    lcFilePath + "\task2\report\"
    lcDate     =    string(year(today) * 10000 + MONTH(today) * 100  + DAY(today))
    lcTime     =    string(time, "HH:MM:SS")
    lcTime     =    entry(1,lcTime,':') + ENTRY(2,lcTime,':') + ENTRY(3,lcTime,':')
    lcFileName =    "EmployeesReport_" + lcDate + '_' + lcTime + ".csv".

output stream strReport to value(lcFilePath + lcFileName).
export stream strReport delimiter ';' "EmpNum" "Type" "FirstName" "LastName" "BirthDate".

for each employee no-lock
    by employee.birthdate:
        
    liAge = year(today) - YEAR(birthdate).
    
    if liAge > 40 then next.
    
    if not can-find(first Family where Family.EmpNum = Employee.EmpNum) then next.
    
    lcBirthDate =   SUBST("&1-&2-&3", string(year(Employee.BirthDate),"9999"), string(month(Employee.BirthDate),"99"), string(day(Employee.BirthDate),"99")).
    
    export stream strReport delimiter ';' Employee.EmpNum "Employee" Employee.FirstName Employee.LastName lcBirthDate.
    
    lcEmpCnt = lcEmpCnt + 1.
    
    for each Family no-lock
        where Family.EmpNum = Employee.empnum
        by birthdate descending:
            
        assign lcFirstName  =   entry(1, Family.RelativeName, " ")
               lcLastName   =   entry(2, Family.RelativeName, " ")
               lcBirthDate  =   SUBST("&1-&2-&3", string(year(Family.BirthDate),"9999"), 
                                string(month(Family.BirthDate),"99"), string(day(Family.BirthDate),"99"))
               lcFamCnt     =   lcFamCnt + 1.
                
        export stream strReport delimiter ';' ""  sports2020.Family.Relation lcFirstName lcLastName  lcBirthDate.
        
    end.
           
end.

put stream strReport unformatted "Total Employees - " + String(lcEmpCnt) + '    ' +  " Total Family Members - " + String(lcFamCnt) skip.