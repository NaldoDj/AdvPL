#include "totvs.ch"
#include "shell.ch"
#include "dbstruct.ch"
#include "parmtype.ch"

/*/{Protheus.doc} utoXML
@author Marinaldo de Jesus (Facile)
@since 28/12/2020
@version 1.0
@Projet void
@description Exportar Query para XML.
@type function
/*/

static outoXMLVar as object

class utoXML

    static method QryToXML(cQuery as character,cFile as character,cExcelTitle as character,lPicture as logical,lX3Titulo as logical,ltxtEditMemo as logical) as logical

    static method setXMLVar(uSection,uPropertyKey,uValue)
    static method getXMLVar(uSection,uPropertyKey,uDefaultValue)
    static method clearXMLVar()

end class

static method QryToXML(cQuery,cFile,cExcelTitle,lPicture,lX3Titulo,ltxtEditMemo) class utoXML

    local cMask         as character
    local cTitle        as character
    local cDirectory    as character

    local nOptions      as numeric

    local lRet          as logical

    DEFAULT cExcelTitle:="QueryToXML"

    if (empty(cQuery))
        cMask:="Query(s) File | *.sql"
        cTitle:="Escolha o script SQL para exportar para XML"
        cDirectory:="C:"
        nOptions:=(GETF_LOCALHARD+GETF_NETWORKDRIVE)
        cQuery:=cGetFile(cMask,cTitle,1,cDirectory,.F.,nOptions,/*[lArvore]*/,/*[lKeepCase]*/)
    endif

    if (empty(cFile))
        cMask:="Excel File | *.xml"
        cTitle:="Escolha/Informe o arquivo para salvar a Query"
        cDirectory:=getTempPath()
        cFile:=cGetFile(cMask,cTitle,1,cDirectory,.T.,nOptions,/*[lArvore]*/,/*[lKeepCase]*/)
        if (empty(cFile))
        	cFile:=nil
        endif
    endif

    DEFAULT ltxtEditMemo:=.F.
    if (ltxtEditMemo)
        ltxtEditMemo:=(!isBlind())
    endif

    if (!empty(cQuery) )
        lRet:=qToXML(@cQuery,@cFile,@cExcelTitle,@lPicture,@lX3Titulo)
        if (ltxtEditMemo)
            if (lRet)
                txtEditMemo():txtFileEdit("Query File :: "+cQuery+CRLF+"Arquivo Excel :: "+cFile+CRLF,"Arquivo Gerado com Sucesso")
            else
                txtEditMemo():txtFileEdit("Query File :: "+cQuery+CRLF+"Arquivo Excel :: "+cFile+CRLF,"Problema na Geração do Arquivo")
            endif
        endif
    else
        lRet:=.F.
        DEFAULT cFile:=""
        if (ltxtEditMemo)
            txtEditMemo():txtFileEdit("Query File :: "+cQuery+CRLF+"Arquivo Excel :: "+cFile+CRLF,"Arquvo(s) não Encontrado(s)")
        endif
    endif

    return(lRet)

 static method setXMLVar(uSection,uPropertyKey,uValue) class utoXML
    DEFAULT outoXMLVar:=tHash():New()
    return(outoXMLVar:SetPropertyValue(uSection,uPropertyKey,uValue))
 
 static method getXMLVar(uSection,uPropertyKey,uDefaultValue) class utoXML
    DEFAULT outoXMLVar:=tHash():New()
    return(outoXMLVar:GetPropertyValue(uSection,uPropertyKey,uDefaultValue))

static method clearXMLVar() class utoXML
    DEFAULT outoXMLVar:=tHash():New()
    return(outoXMLVar:Clear())

static function qToXML(cQuery,cFile,cExcelTitle,lPicture,lX3Titulo) as logical

    local cFileTmp      as character
    local cExtension    as character

    local lRet          as logical

    DEFAULT cQuery:=""

    cExtension:=".xml"

    DEFAULT cFile:=(getFileTmp("")+cExtension)

    DEFAULT lPicture:=.T.

    DEFAULT lX3Titulo:=.T.

    lRet:=ToXML(@cQuery,@cFile,@cExcelTitle,@lPicture,@lX3Titulo)

    if (!isBlind())
        if (!getTempPath()$cFile)
            cFileTmp:=getFileTmp(cFile)
            if (!(cFile==cFileTmp))
                lRet:=__CopyFile(cFile,cFileTmp)
            endif
        else
            cFileTmp:=cFile
        endif
        lRet:=file(cFileTmp)
        if (lRet)
            ShellExecute("open",cFileTmp,"","",SW_SHOWMAXIMIZED)
        endif
    endif
    
    return(lRet)

static function ToXML(cQuery as character,cFile as character,cExcelTitle as character,lPicture as logical,lX3Titulo as logical) as logical

    local aArea     as array

    local cAlias    as character

    local lRet      as logical
    local lMsOpenDB as logical

    aArea:=getArea()

    DEFAULT cFile:=(getFileTmp("")+".xml")

    begin sequence

        if (empty(cQuery))
            break
        endif

        if (file(cQuery))
            cQuery:=ReadMemo(cQuery)
            if (empty(cQuery))
                break
            endif
        endif

        lMsOpenDB:=(select(cQuery)>0)
        
        if (!lMsOpenDB)
            cAlias:=getNextAlias()
            MsAguarde({||lMsOpenDB:=MsOpenDBF(.T.,"TOPCONN",TCGenQry(nil,nil,cQuery),cAlias,.T.,.T.,.F.,.F.)},"Selecionando dados no SGBD","Aguarde...")
        else
            cAlias:=cQuery
        endif

        if (!lMsOpenDB)
            break
        endif

        MsAguarde({||cFile:=dbToXML(@cAlias,@cFile,@cExcelTitle,@lPicture,@lX3Titulo)},"Gerando arquivo","Aguarde...")

        lRet:=file(cFile)

    end sequence

    if (!(cQuery==cAlias))
        if (select(cAlias)>0)
            (cAlias)->(dbCloseArea())
        endif
    endif

    restArea(aArea)

    DEFAULT lRet:=.F.

    return(lRet)

static function dbToXML(cAlias as character,cFile as character,cExcelTitle as character,lPicture as logical,lX3Titulo as logical) as character

    local aCells        as array
    local aHeader       as array
    local aX3CBox       as array

    local cType         as character
    local cField        as character
    local cWBreak       as character
    local cTBreak       as character
    local cColumn       as character
    local cX3CBox       as character
    local cPicture      as character
    local cWorkSheet    as character

    local nAlign        as numeric
    local nField        as numeric
    local nFields       as numeric
    local nFormat       as numeric
    local nX3CBox       as numeric

    local lTotal        as logical

    local oFWMSExcel    as object

    local uCell

    aHeader:=(cAlias)->(dbStruct())

    oFWMSExcel:=FWMsExcel():New()

    aCells:=Array(0)

    cWorkSheet:=cExcelTitle
    cWBreak:=cWorkSheet
    cTBreak:=cWBreak+if((Type("c_pExcelTitle")=="C"),&("c_pExcelTitle"),"")

    nFields:=Len(aHeader)

    oFWMSExcel:AddworkSheet(cWBreak)
    oFWMSExcel:AddTable(cWBreak,cTBreak)

    for nField := 1 to nFields
        cField:=aHeader[nField][DBS_NAME]
        cType:=uToXML():getXMLVar(cField,"X3_TIPO","")
        if (empty(cType))
            cType:=getSX3Cache(cField,"X3_TIPO")
            if (empty(cType))
                cType:=aHeader[nField][DBS_TYPE]
            endif
        endif
        nAlign:=if(cType=="C",1,if(cType=="N",3,2))
        nFormat:=if(cType=="D",4,if(cType=="N",2,1))
        if (lX3Titulo)
            cColumn:=uToXML():getXMLVar(cField,"X3_TITULO","")
            if (empty(cColumn))
                cColumn:=getSX3Cache(cField,"X3_TITULO")
                if (empty(cColumn))
                    cColumn:=cField
                endif
            endif
        else
            cColumn:=cField
        endif
        cColumn:=OemToAnsi(cColumn)
        oFWMSExcel:AddColumn(@cWBreak,@cTBreak,@cColumn,@nAlign,@nFormat,@lTotal)
    next nField

    while (cAlias)->(!(eof()))

        aSize(aCells,0)

        for nField := 1 to nFields
            uCell:=(cAlias)->(FieldGet(nField))
            cField:=aHeader[nField][DBS_NAME]
            cType:=uToXML():getXMLVar(cField,"X3_TIPO","")
            if (empty(cType))
                cType:=getSX3Cache(cField,"X3_TIPO")
            endif
            if (cType=="D")
                if (cType!=aHeader[nField][DBS_TYPE])
                    uCell:=SToD(uCell)
                endif
            endif
            if (lPicture)
                nX3CBox:=0
                if (cType=="C")
                    cX3CBox:=uToXML():getXMLVar(cField,"X3_CBOX","")
                    if (empty(cX3CBox))
                        cX3CBox:=getSX3Cache(cField,"X3_CBOX")
                    endif
                    if (!empty(cX3CBox))
                        aX3CBox:=StrTokArr2(cX3CBox,";")
                        nX3CBox:=aScan(aX3CBox,{|e|(uCell==StrTokArr2(e,"=")[1])})
                    endif
                endif
                if (nX3CBox==0)
                    cPicture:=uToXML():getXMLVar(cField,"X3_PICTURE","")
                    if (empty(cPicture))
                        cPicture:=getSX3Cache(cField,"X3_PICTURE")
                    endif
                    if (!(empty(cPicture)))
                        uCell:=Transform(uCell,cPicture)
                    else
                        if (cType=="D")
                            uCell:=DToC(uCell)
                        endif
                    endif
                else
                    uCell:=aX3CBox[nX3CBox]
                endif
            else
                if (cType=="D")
                    uCell:=DToC(uCell)
                endif
            endif
            aAdd(aCells,uCell)
        next nField

        oFWMSExcel:AddRow(@cWBreak,@cTBreak,aClone(aCells))

        (cAlias)->(dbSkip())

    end while

    oFWMSExcel:Activate()
    oFWMSExcel:GetXMLFile(cFile)
    oFWMSExcel:DeActivate()
    oFWMSExcel:=FreeObj(oFWMSExcel)

    return(cFile)

static function ReadMemo(cFile) as character
	local cMemoRead as character
	cMemoRead:=cTools():ReadMemo(cFile)
	return(cMemoRead)

static function getFileTmp(cFile as character) as character

    local cTrb      as character
    local cSPExt    as character
    local cSPFile   as character
    local cSPPath   as character
    local cSPDrive  as character
    local cFileTmp  as character
    local cTempPath as character

    cSPExt:=""
    cSPFile:=""
    cSPPath:=""
    cSPDrive:=""
    
    splitPath(cFile,@cSPDrive,@cSPPath,@cSPFile,@cSPExt)

    cTrb:=substr(CriaTrab(nil,.F.),3)
    cTempPath:=getTempPath()

    if (cTempPath$cFile)
    
        cFileTmp:=cFile

    else
        
        cFileTmp:=cTempPath
        cFileTmp+=cSPFile
        cFileTmp+="_"
        cFileTmp+=cTrb
        cFileTmp+=cSPExt

        while (file(cFileTmp))
            cTrb:=__Soma1(cTrb)
            cFileTmp:=cTempPath
            cFileTmp+=cSPFile
            cFileTmp+="_"
            cFileTmp+=cTrb
            cFileTmp+=cSPExt
        end while
    endif

    return(cFileTmp)

