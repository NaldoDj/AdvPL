#include "totvs.ch"
#include "fileio.ch"

#xtranslate NToS([<n,...>]) => LTrim(Str([<n>]))

#define ARRAY_IS_FULL    50000
#define ARRAY_MAX_SIZE   25000

#define ROOT_PATH    "\shwusers\"
#define TEMP_PATH    getTempPath()

#define FILE_KILL    "shwusers.kill"
#define FILE_ARRAY   (ROOT_PATH+"shwusers.array")
#define FILE_RUNCMD  (ROOT_PATH+"shwusers.ini")

procedure u_ShwUsers()

    static aUsersArray  as array

    local cMSG          as character

    local cRunCMD       as character
    local cRunCMDPath   as character

    local cINIFile      as character

    local lRecursa      as logical
    local lWaitRunSRV   as logical

    local nUsersArray   as numeric

    local oTFINI        as object
    local oArrayUtils   as object

    __SetCentury("on")

    if !(lIsDir(ROOT_PATH))
        MakeDir(ROOT_PATH)
    endif

    oArrayUtils:=U_DJLIB029()
    if (file(FILE_ARRAY))
        aUsersArray:=oArrayUtils:RestArray(FILE_ARRAY)
        fErase(FILE_ARRAY)
    else
        DEFAULT aUsersArray:=array(0)
    endif

    cMSG:="Monitorando Acessos"
    PutInternal(ProcName()+" :: "+cMSG)
    lRecursa:=.F.
    MsgRun("Aguarde",cMSG,{||ShwUsers(@aUsersArray,@lRecursa)})
    if (lRecursa)
        nUsersArray:=len(aUsersArray)
        while (nUsersArray>ARRAY_MAX_SIZE)
            aDel(aUsersArray,1)
            aSize(aUsersArray,--nUsersArray)
        end while
        oArrayUtils:SaveArray(aUsersArray,FILE_ARRAY)
        cINIFile:=FILE_RUNCMD
        oTFINI:=TFINI():New(cINIFile,"#")
        cRunCMD:=oTFINI:GetPropertyValue("waitrun","RunCMD","F:\Protheus12\scripts\BAT\monitor.bat")
        cRunCMDPath:=oTFINI:GetPropertyValue("waitrun","RunCMDPath","F:\Protheus12\scripts\BAT\")
        lWaitRunSRV:=(oTFINI:GetPropertyValue("waitrun","WaitRunSRV","1")=="1")
        if (lWaitRunSRV)
            WaitRunSRV(cRunCMD,.F.,cRunCMDPath)
        else
            WaitRun(cRunCMD)
        endif
    endif
    aFill(aUsersArray,0)
    return

static procedure ShwUsers(aUsersArray as array,lRecursa as logical)

    local aTmp          as array
    local aPathKill     as array
    local aUserInfo     as array
    local aINISessions  as array

    local cCRLF         as character
    local cCHR10        as character
    local cCHR13        as character
    local cCHR59        as character
    local cINIFile      as character
    local cSession      as character
    local cFileUsers    as character
    local cUsersArray   as character

    local nC            as numeric
    local nS            as numeric
    local nD            as numeric
    local nJ            as numeric

    local nAT           as numeric

    local nUsersArray   as numeric

    local oTFINI        as object

    aPathKill:=array(2)
    aPathKill[1]:=TEMP_PATH
    aPathKill[2]:=ROOT_PATH

    begin sequence

        if !(lIsDir(aPathKill[2]))
            MakeDir(aPathKill[2])
        endif

        if !(lIsDir(strTran(aPathKill[1]+ROOT_PATH,"\\","\")))
            MakeDir(strTran(aPathKill[1]+ROOT_PATH,"\\","\"))
        endif

        cINIFile:=aPathKill[2]
        cINIFile+="schema.ini"

        oTFINI:=TFINI():New(cINIFile,"#")

        if (File(cINIFile))
            aINISessions:=oTFINI:GetAllSessions(cINIFile)
            nJ:=len(aINISessions)
            for nD:=1 to nJ
                cSession:=aINISessions[nD]
                cFileUsers:=aPathKill[2]
                cFileUsers+=cSession
                if (!File(cFileUsers))
                    oTFINI:RemoveSession(cSession,cINIFile)
                endif
            next nD
            aSize(aINISessions,0)
        endif

        oTFINI:SaveAs(cINIFile)

        cFileUsers:=aPathKill[2]
        cFileUsers+="GetUserInfoArray"
        cFileUsers+="_"
        cFileUsers+=DToS(MsDate())
        cFileUsers+="_"
        cFileUsers+=strTran(Time(),":","")
        cFileUsers+="_"
        cFileUsers+=StrZero(Randomize(1,999),3)
        cFileUsers+=".csv"

        nUsersArray:=fCreate(cFileUsers)
        if (nUsersArray=-1)
            ConOut(ProcName()+" :: "+DToC(MsDate())+" :: "+Time(),fError())
            break
        endif
        fClose(nUsersArray)

        nUsersArray:=fOpen(cFileUsers,FO_READWRITE+FO_SHARED)
        if (nUsersArray=-1)
            ConOut(ProcName()+" :: "+DToC(MsDate())+" :: "+Time(),fError())
            break
        endif

        cSession:=StrTran(cFileUsers,aPathKill[2],"")

        oTFINI:AddNewSession(cSession)

        oTFINI:AddNewProperty(cSession,"ColNameHeader","True")
        oTFINI:AddNewProperty(cSession,"Format","Delimited(;)")
        oTFINI:AddNewProperty(cSession,"MaxScanRows","1")
        oTFINI:AddNewProperty(cSession,"CharacterSet","ANSI")
        oTFINI:AddNewProperty(cSession,"Col1","USUARIO Char Width 255")
        oTFINI:AddNewProperty(cSession,"Col2","COMPUTADOR Char Width 255")
        oTFINI:AddNewProperty(cSession,"Col3","ID Integer")
        oTFINI:AddNewProperty(cSession,"Col4","CONEXAO Char Width 255")
        oTFINI:AddNewProperty(cSession,"Col5","PROGRAMA Char Width 255")
        oTFINI:AddNewProperty(cSession,"Col6","ENVIRONMENT Char Width 255")
        oTFINI:AddNewProperty(cSession,"Col7","DATA Char Width 255")
        oTFINI:AddNewProperty(cSession,"Col8","TEMPO_DE_USO Date")
        oTFINI:AddNewProperty(cSession,"Col9","NRO_INTRUCOES Integer")
        oTFINI:AddNewProperty(cSession,"Col10","INTRUCOES Integer")
        oTFINI:AddNewProperty(cSession,"Col11","OBSERVACAO Char Width 255")
        oTFINI:AddNewProperty(cSession,"Col12","MEMORIA Integer")
        oTFINI:AddNewProperty(cSession,"Col13","SID Integer")
        oTFINI:AddNewProperty(cSession,"Col14","NONAME Char Width 1")

        oTFINI:SaveAs(cINIFile)

        cCRLF:=CRLF
        cCHR10=CHR(10)
        cCHR13:=CHR(13)
        cCHR59:=CHR(59)

        cUsersArray:="usuario"
        cUsersArray+=cCHR59
        cUsersArray+="computador"
        cUsersArray+=cCHR59
        cUsersArray+="ID"
        cUsersArray+=cCHR59
        cUsersArray+="conexao"
        cUsersArray+=cCHR59
        cUsersArray+="programa"
        cUsersArray+=cCHR59
        cUsersArray+="environment"
        cUsersArray+=cCHR59
        cUsersArray+="data"
        cUsersArray+=cCHR59
        cUsersArray+="tempo_de_uso"
        cUsersArray+=cCHR59
        cUsersArray+="nro_intrucoes"
        cUsersArray+=cCHR59
        cUsersArray+="intrucoes"
        cUsersArray+=cCHR59
        cUsersArray+="observacao"
        cUsersArray+=cCHR59
        cUsersArray+="memoria"
        cUsersArray+=cCHR59
        cUsersArray+="SID"
        cUsersArray+=cCHR59
        cUsersArray+=cCRLF
        fWrite(nUsersArray,cUsersArray)

        while (.not.(file(aPathKill[1]+FILE_KILL).or.file(aPathKill[2]+FILE_KILL)))
            aUserInfo:=GetUserInfoArray()
            if (aScan(aUsersArray,{|e|compare(e,aUserInfo)})==0)
                aEval(aUsersArray,{|c|aEval(c,{|s|aTmp:=s,if((nAT:=aScan(aUserInfo,{|d|compare(aTmp,d)}))>0,(aDel(aUserInfo,nAT),aSize(aUserInfo,len(aUserInfo)-1)),nil)})})
                if (len(aUserInfo)>0)
                    aAdd(aUsersArray,aUserInfo)
                endif
            endif
            nS:=len(aUsersArray)
            lRecursa:=(nS>=ARRAY_IS_FULL)
             for nC:=nS to nS
                 cUsersArray:=""
                 nJ:=len(aUsersArray[nC])
                 for nD:=1 to nJ
                     cUsersArray:=""
                     aEval(aUsersArray[nC][nD],{|e|cUsersArray+=(cValToChar(e)+cCHR59)})
                     cUsersArray:=StrTran(StrTran(cUsersArray,cCHR10,""),cCHR13,"")
                     cUsersArray+=cCRLF
                     fWrite(nUsersArray,cUsersArray)
                 next nD
             next nD
            if ((lRecursa).or.(KillApp(.F.)))
                nUsersArray:=fCreate(aPathKill[1]+FILE_KILL)
                fClose(nUsersArray)
                exit
            endif
        end while

         fClose(nUsersArray)

         __CopyFile(cFileUsers,strTran(aPathKill[1]+cFileUsers,"\\","\"))

    end sequence

    aEval(aPathKill,{|p|fErase(p+FILE_KILL)})

    return

static function PutInternal(cInternal as character) as logical

    #IFDEF TOP
        local cTCInternal   as character
    #ENDIF
    local cPTInternal       as character

    local lInternal         as logical

    lInternal:=.T.

    if !(Type("cEmpAnt")=="C")
        private cEmpAnt as character
        cEmpAnt:="99"
    endif

    if !(Type("cFilAnt")=="C")
        private cFilAnt as character
        cFilAnt:="01"
    endif

    if !(Type("cUserName")=="C")
        private cUserName   as character
        cUserName:="Admin"
    endif

    if !(Type("cModulo")=="C")
        private cModulo as character
        cModulo:="ESP"
    endif

    #ifDEF TOP
        TCInternal(8,cUserName)
        cTCInternal:=cInternal
        cTCInternal+="::"
        cTCInternal+=ConType()
        TCInternal(1,cTCInternal)
    #endif

    cPTInternal:="Emp:"
    cPTInternal+=cEmpAnt
    cPTInternal+="/"
    cPTInternal+=cFilAnt
    cPTInternal+=" "
    cPTInternal+="Logged:"+cUserName
    cPTInternal+=" "
    cPTInternal+="SIGA"+cModulo
    cPTInternal+=" "
    cPTInternal+="Obj:"+cInternal

    PTInternal(1,cPTInternal)

    return(lInternal)
