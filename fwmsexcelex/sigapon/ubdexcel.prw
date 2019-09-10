#include "totvs.ch"
#include "shell.ch"
#include "fileio.ch"

#xtranslate NToS([<n,...>]) => LTrim(Str([<n>]))

//------------------------------------------------------------------------------------------------
/*
    Programa:uBDExcel.prw
    Autor: Marinaldo de Jesus [ConnectTI]
    Data:04/09/2019
    Descricao:BigData Excel
    Sintaxe:u_BDExcel()
*/
//------------------------------------------------------------------------------------------------
function u_BDExcel() as logical

    local aArea       as array

    local lBDExcel    as logical

    aArea:=GetArea()
    saveInter()

    oPergunte:=tHash():New()

    begin sequence

        //------------------------------------------------------------------------------------------------------
            //Se nao confirmar as perguntas....
        //------------------------------------------------------------------------------------------------------
        if (.not.(Pergunte(@oPergunte)))
            //------------------------------------------------------------------------------------------------------
                //Aborta o Processo
            //------------------------------------------------------------------------------------------------------
            break
        endif

        lBDExcel:=BDExcel(oPergunte)

    end sequence

    oPergunte:=oPergunte:FreeObj()

    restInter()

    restArea(aArea)

    return(lBDExcel)

//------------------------------------------------------------------------------------------------
/*
    Programa:uBDExcel.prw
    Autor: Marinaldo de Jesus [ConnectTI]
    Data:04/09/2019
    Descricao:BigData Excel
    Sintaxe:BDExcel()
*/
//------------------------------------------------------------------------------------------------
static function BDExcel(oPergunte as object) as logical

    local cAlias        as character
    local cADNList      as character
    local cExcelFile    as character

    local lBDExcel      as logical

    local bProcess      as block

    local nRecCount     as numeric
    local nColMarcs     as numeric

    local oFont         as object
    local oMsExcel      as object
    local oProcess      as object
    local oFWMsWExcel   as object

    begin sequence

        cAlias:=getNextAlias()
        nColMarcs:=0
        MsAguarde({||nRecCount:=QueryView(@oPergunte,@cAlias,@nColMarcs)},"Obtendo dados no SGBD","Aguarde...")

        lBDExcel:=(nRecCount>0)

        if (!lBDExcel)
            break
        endif

        //------------------------------------------------------------------------------------------------------
            //Obtem os Eventos de Adicional Noturno
        //------------------------------------------------------------------------------------------------------
        cADNList:=oPergunte:Get("Eventos ADN","")
        if (Right(cADNList,1)==",")
            cADNList:=Left(cADNList,len(cADNList)-1)
        endif
        cADNList:=strTran(cADNList,",","','")
        cADNList:="'"+cADNList+"'"

        oFont:=TFont():New("Lucida Console",nil,18,nil,.T.)

        //------------------------------------------------------------------------------------------------------
            //Define o Bloco de Processamento
        //------------------------------------------------------------------------------------------------------
        bProcess:={|lEnd,oProcess|ProcRedefine(@oProcess,@oFont,0,150,150,.T.,.T.),oProcess:SetRegua1(0),oFWMsWExcel:=BDExcelProc(@oProcess,@lEnd,@cAlias,@nColMarcs,@cADNList)}

        //------------------------------------------------------------------------------------------------------
            //Instancia um novo objeto para o controle de Processamento visual
        //------------------------------------------------------------------------------------------------------
        oProcess:=MsNewProcess():New(bProcess,OemtoAnsi("BiG Data Excel"),"Aguarde...",.T.)

        //------------------------------------------------------------------------------------------------------
            //Ativa e executa o processo
        //------------------------------------------------------------------------------------------------------
        oProcess:Activate()

        if (valType(oProcess:oDlg)=="O")
            oProcess:oDlg:end()
        endif

        //------------------------------------------------------------------------------------------------------
            //Se o objeto nao foi finaliza
        //------------------------------------------------------------------------------------------------------
        if (valType(oProcess)=="O")
            //------------------------------------------------------------------------------------------------------
                //...Finaliza-o
            //------------------------------------------------------------------------------------------------------
            oProcess:=FreeObj(oProcess)
        endif

        if (.not.(lBDExcel))
            break
        endif

        MsAguarde({||oFWMsWExcel:Activate()},"Ativando o Componente FWMsWExcel","Aguarde...")

        cExcelFile:=getTempPath()
        cExcelFile+="bdexcel"
        cExcelFile+="_"
        cExcelFile+=DToS(Date())
        cExcelFile+="_"
        cExcelFile+=StrTran(Time(),":","")
        cExcelFile+="_"
        cExcelFile+=NTOS(RandoMize(1,999))
        cExcelFile+=".xml"

        MsAguarde({||lBDExcel:=oFWMsWExcel:GetXMLFile(cExcelFile)},"Gerando a Planilha BDExcel","Aguarde...")

        oFWMsWExcel:DeActivate()
        if (valType(oFWMsWExcel)=="O")
            oFWMsWExcel:=FreeObj(oFWMsWExcel)
        endif

        if (!lBDExcel)
            break
        endif

        if (!(ApOleClient("MsExcel")))
            ShellExecute("open",cExcelFile,"",getTempPath(),SW_SHOWMAXIMIZED)
            break
        endif

        oMsExcel:=MsExcel():New()
        oMsExcel:WorkBooks:Open(cExcelFile)
        oMsExcel:SetVisible(.T.)
        oMsExcel:=oMsExcel:Destroy()
        if (valType(oMsExcel)=="O")
            oMsExcel:=FreeObj(oMsExcel)
        endif

    end sequence

    if (valType(oFont)=="O")
        oFont:=FreeObj(oFont)
    endif

    return(lBDExcel)

//------------------------------------------------------------------------------------------------
/*
    Programa:uBDExcel.prw
    Autor: Marinaldo de Jesus [ConnectTI]
    Data:04/09/2019
    Descricao:BigData Excel
    Sintaxe:BDExcelProc()
*/
//------------------------------------------------------------------------------------------------
static function BDExcelProc(oProcess as object,lEnd as logical,cAlias as character,nColMarcs as numeric,cADNList as character) as object

    local aRow          as array
    local aTot          as array
    local aFmt            as array

    local cEmp          as character
    local cFil          as character

    local cTime         as character

    local cIdxCol       as character
    local cColumn       as character

    local cAliasM       as character
    local cP8Ordem      as character
    local cP8PAponta    as character
    local cPrefixCPO    as character

    local dDt1          as date
    local dDt2          as date

    local dDate         as date

    local lAliasMSP8    as logical

    local nHr1          as numeric
    local nHr2          as numeric

    local nC            as numeric
    local nS            as numeric
    local nD            as numeric
    local nJ            as numeric

    local nCols         as numeric
    local nTime         as numeric

    local nCTTRecNo     as numeric
    local nSRARecNo     as numeric
    local nSRJRecNo     as numeric
    local nSP8RecNo     as numeric

    local nIdxCol       as numeric
    local nColMarc      as numeric
    local nTotMarc      as numeric

    local oColumn       as object
    local oFWMsWExcel   as object

    oColumn:=THash():New()
    oFWMsWExcel:=FWMsExcelEx():New()

    oFWMsWExcel:AddworkSheet("BDExcel")

    oFWMsWExcel:AddTable("BDExcel","BigData")

    aFmt:=array(0)
    nCols:=0
    cColumn:="NOME"
    (++nCols,aAdd(aFmt,1),oFWMsWExcel:AddColumn("BDExcel","BigData",cColumn,1,aFmt[nCols]),oColumn:Set(cColumn,nCols))
    cColumn:="EMPRESA"
    (++nCols,aAdd(aFmt,1),oFWMsWExcel:AddColumn("BDExcel","BigData",cColumn,1,aFmt[nCols]),oColumn:Set(cColumn,nCols))
    cColumn:="C.CUSTO"
    (++nCols,aAdd(aFmt,1),oFWMsWExcel:AddColumn("BDExcel","BigData",cColumn,1,aFmt[nCols]),oColumn:Set(cColumn,nCols))
    cColumn:="CARGO"
    (++nCols,aAdd(aFmt,1),oFWMsWExcel:AddColumn("BDExcel","BigData",cColumn,1,aFmt[nCols]),oColumn:Set(cColumn,nCols))
    cColumn:="TABELA"
    (++nCols,aAdd(aFmt,1),oFWMsWExcel:AddColumn("BDExcel","BigData",cColumn,1,aFmt[nCols]),oColumn:Set(cColumn,nCols))
    cColumn:="PERIODO"
    (++nCols,aAdd(aFmt,1),oFWMsWExcel:AddColumn("BDExcel","BigData",cColumn,1,aFmt[nCols]),oColumn:Set(cColumn,nCols))
    cColumn:="DATA"
    (++nCols,aAdd(aFmt,4),oFWMsWExcel:AddColumn("BDExcel","BigData",cColumn,1,aFmt[nCols]),oColumn:Set(cColumn,nCols))
    cColumn:="ORDEM"
    (++nCols,aAdd(aFmt,1),oFWMsWExcel:AddColumn("BDExcel","BigData",cColumn,1,aFmt[nCols]),oColumn:Set(cColumn,nCols))
    nIdxCol:=0
    for nColMarc:=1 to nColMarcs
        if (Mod(nColMarc,2)==1)
            cIdxCol:=NTOS(++nIdxCol)
            cColumn:="ENT_"
        else
            cColumn:="SAI_"
        endif
        cColumn+=cIdxCol
        (++nCols,aAdd(aFmt,1),oFWMsWExcel:AddColumn("BDExcel","BigData",cColumn,1,aFmt[nCols]),oColumn:Set(cColumn,nCols))
    next nColMarc
    cColumn:="TOTDIA"
    (++nCols,aAdd(aFmt,1),oFWMsWExcel:AddColumn("BDExcel","BigData",cColumn,1,aFmt[nCols]),oColumn:Set(cColumn,nCols))
    cColumn:="LIBERALIDADEGESTOR"
    (++nCols,aAdd(aFmt,1),oFWMsWExcel:AddColumn("BDExcel","BigData",cColumn,1,aFmt[nCols]),oColumn:Set(cColumn,nCols))
    cColumn:="ABMEDICO"
    (++nCols,aAdd(aFmt,1),oFWMsWExcel:AddColumn("BDExcel","BigData",cColumn,1,aFmt[nCols]),oColumn:Set(cColumn,nCols))
    cColumn:="Ad_Not"
    (++nCols,aAdd(aFmt,1),oFWMsWExcel:AddColumn("BDExcel","BigData",cColumn,1,aFmt[nCols]),oColumn:Set(cColumn,nCols))
    cColumn:="Cred_BH"
    (++nCols,aAdd(aFmt,1),oFWMsWExcel:AddColumn("BDExcel","BigData",cColumn,1,aFmt[nCols]),oColumn:Set(cColumn,nCols))
    cColumn:="Deb_BH"
    (++nCols,aAdd(aFmt,1),oFWMsWExcel:AddColumn("BDExcel","BigData",cColumn,1,aFmt[nCols]),oColumn:Set(cColumn,nCols))

    aRow:=array(nCols)
    aTot:=array(2,nColMarcs)

    cEmp:=&("cEmpAnt")

    begin sequence

        while (cAlias)->(!eof())

            oProcess:IncRegua1()

            if (lEnd)
                break
            endif

            nSRARecNo:=(cAlias)->SRARECNO
            SRA->(dbGoTo(nSRARecNo))

            cFil:=SRA->RA_FILIAL

            aFill(aRow,nil)
            aFill(aTot[1],CToD(""))
            aFill(aTot[2],0)

            nC:=oColumn:Get("NOME")
            aRow[nC]:=SRA->RA_MAT
            aRow[nC]+="-"
            aRow[nC]+=SRA->RA_NOME

            nC:=oColumn:Get("EMPRESA")
            aRow[nC]:=SRA->RA_FILIAL
            aRow[nC]+="-"
            aRow[nC]+=Posicione("SM0",1,cEmp+cFil,"M0_FILIAL")

            nCTTRecNo:=(cAlias)->CTTRECNO
            CTT->(MsGoTo(nCTTRecNo))

            nC:=oColumn:Get("C.CUSTO")
            aRow[nC]:=CTT->CTT_DESC01

            nSRJRecNo:=(cAlias)->SRJRECNO
            SRJ->(MsGoTo(nSRJRecNo))

            nC:=oColumn:Get("CARGO")
            aRow[04]:=SRJ->RJ_DESC

            while (cAlias)->(!eof().and.(SRARECNO==nSRARecNo))

                if (lEnd)
                    break
                endif

                cAliasM:=(cAlias)->ALIASTABLE

                aRow[05]:=cAliasM

                lAliasMSP8:=(cAliasM=="SP8")

                if (lAliasMSP8)
                       cPrefixCPO:="P8_"
                else
                    cPrefixCPO:="PG_"
                endif

                SRA->(MsGoTo(nSRARecNo))

                nSP8RecNo:=(cAlias)->SP8RECNO
                if (nSP8RecNo==0)
                    (cAlias)->(dbSkip())
                    loop
                endif

                (cAliasM)->(dbGoTo(nSP8RecNo))

                cP8Ordem:=(cAlias)->P8_ORDEM
                cP8PAponta:=(cAlias)->P8_PAPONTA

                nC:=oColumn:Get("PERIODO")
                aRow[nC]:=cP8PAponta

                nC:=oColumn:Get("DATA")
                dDate:=(cAliasM)->(FieldGet(FieldPos(cPrefixCPO+"DATA")))
                aRow[nC]:=DToC(dDate)

                nC:=oColumn:Get("LIBERALIDADEGESTOR")
                nTime:=getTAbono(dDate,"2")
                cTime:=nToTime(nTime)
                aRow[nC]:=cTime

                nC:=oColumn:Get("ABMEDICO")
                nTime:=getTAbono(dDate,"1")
                cTime:=nToTime(nTime)
                aRow[nC]:=cTime

                nC:=oColumn:Get("Ad_Not")
                nTime:=getTADNot(dDate,cADNList,lAliasMSP8)
                cTime:=nToTime(nTime)
                aRow[nC]:=cTime

                nC:=oColumn:Get("Cred_BH")
                nTime:=getTBH(dDate,"1")
                cTime:=nToTime(nTime)
                aRow[nC]:=cTime

                nC:=oColumn:Get("Deb_BH")
                nTime:=getTBH(dDate,"2")
                cTime:=nToTime(nTime)
                aRow[nC]:=cTime

                aRow[nC]:=cTime
                nC:=oColumn:Get("ORDEM")
                aRow[nC]:=cP8Ordem

                nColMarc:=oColumn:Get("ORDEM")
                nTotMarc:=0

                oProcess:SetRegua2(0)

                while (cAlias)->(!eof().and.(SRARECNO==nSRARecNo).and.((ALIASTABLE+P8_PAPONTA+P8_ORDEM)==(cAliasM+cP8PAponta+cP8Ordem)))

                    oProcess:IncRegua2()

                    if (lEnd)
                        break
                    endif

                    nSP8RecNo:=(cAlias)->SP8RECNO
                    if (nSP8RecNo==0)
                        (cAlias)->(dbSkip())
                        loop
                    endif

                    (cAliasM)->(MsGoTo(nSP8RecNo))

                    nTotMarc++

                    dDate:=(cAliasM)->(FieldGet(FieldPos(cPrefixCPO+"DATA")))
                    nTime:=(cAliasM)->(FieldGet(FieldPos(cPrefixCPO+"HORA")))

                    aTot[1][nTotMarc]:=dDate
                    aTot[2][nTotMarc]:=nTime

                    cTime:=nToTime(nTime)
                    aRow[++nColMarc]:=cTime

                    (cAlias)->(dbSkip())

                end while

                nJ:=nColMarcs
                nTime:=0
                for nD:=2 to nJ step 2
                    nS:=(nD-1)
                    dDt1:=aTot[1][nD]
                    if empty(dDt1)
                        loop
                    endif
                    dDt2:=aTot[1][nS]
                    if empty(dDt2)
                        loop
                    endif
                    nHr1:=aTot[2][nD]
                    nHr2:=aTot[2][nS]
                    nTime:=__TimeSum(nTime,DataHora2Val(dDt1,nHr1,dDt2,nHr2,"H"))
                next nD

                nC:=oColumn:Get("TOTDIA")
                cTime:=nToTime(nTime)
                aRow[nC]:=cTime

                oFWMsWExcel:AddRow("BDExcel","BigData",aClone(aRow),aFmt)

                aFill(aRow,nil,9)
                aFill(aTot[1],CToD(""))
                aFill(aTot[2],0)

            end while

        end while

    end sequence

    oColumn:=oColumn:FreeObj()

    return(oFWMsWExcel)

//------------------------------------------------------------------------------------------------
    /*
        Programa:uBDExcel.prw
        Funcao:Pergunte()
        Autor:Marinaldo de Jesus [ConnectTI]
        Data:10/08/2019
        Descricao:Parametros para selecao
    */
//------------------------------------------------------------------------------------------------
static function Pergunte(oPergunte as object) as logical

    //------------------------------------------------------------------------------------------------
    local aPBoxPrm  as array
    local aPBoxRet  as array

    //------------------------------------------------------------------------------------------------

    local cPBoxTit  as character

    //------------------------------------------------------------------------------------------------

    local lParamBox as logical

    //------------------------------------------------------------------------------------------------

    local nPBox     as numeric

    aPBoxPrm:=array(0)

    //------------------------------------------------------------------------------------------------
        //Carrega as Perguntas do Programa
    //------------------------------------------------------------------------------------------------
    aAdd(aPBoxPrm,array(9))
    nPBox:=Len(aPBoxPrm)
    //01----------------------------------------------------------------------------------------------
    aPBoxPrm[nPBox][1]:=1//[1]:1 - MsGet
    aPBoxPrm[nPBox][2]:="Filial De"//[2]:Descricao
    aPBoxPrm[nPBox][3]:=Space(GetSx3Cache("RA_FILIAL","X3_TAMANHO"))//[3]:String contendo o inicializador do campo
    aPBoxPrm[nPBox][4]:=""//[4]:String contendo a Picture do campo
    aPBoxPrm[nPBox][5]:="AllWaysTrue()" //[5]:String contendo a validacao
    aPBoxPrm[nPBox][6]:="XM0"//[6]:Consulta F3
    aPBoxPrm[nPBox][7]:="AllWaysTrue()"//[7]:String contendo a validacao When
    aPBoxPrm[nPBox][8]:=GetSx3Cache("RA_FILIAL","X3_TAMANHO")//[8]:Tamanho do MsGet
    aPBoxPrm[nPBox][9]:=.F.//[9]:Flag .T./.F. Parametro Obrigatorio ?
    //------------------------------------------------------------------------------------------------
    aAdd(aPBoxPrm,array(9))
    nPBox:=Len(aPBoxPrm)
    //02----------------------------------------------------------------------------------------------
    aPBoxPrm[nPBox][1]:=1//[1]:1 - MsGet
    aPBoxPrm[nPBox][2]:="Filial Ate"//[2]:Descricao
    aPBoxPrm[nPBox][3]:=Space(GetSx3Cache("RA_FILIAL","X3_TAMANHO"))//[3]:String contendo o inicializador do campo
    aPBoxPrm[nPBox][4]:=""//[4]:String contendo a Picture do campo
    aPBoxPrm[nPBox][5]:="NaoVazio()" //[5]:String contendo a validacao
    aPBoxPrm[nPBox][6]:="XM0"//[6]:Consulta F3
    aPBoxPrm[nPBox][7]:="AllWaysTrue()"//[7]:String contendo a validacao When
    aPBoxPrm[nPBox][8]:=GetSx3Cache("RA_FILIAL","X3_TAMANHO")//[8]:Tamanho do MsGet
    aPBoxPrm[nPBox][9]:=.T.//[9]:Flag .T./.F. Parametro Obrigatorio ?
    //------------------------------------------------------------------------------------------------
    aAdd(aPBoxPrm,array(9))
    nPBox:=Len(aPBoxPrm)
    //03----------------------------------------------------------------------------------------------
    aPBoxPrm[nPBox][1]:=1//[1]:1 - MsGet
    aPBoxPrm[nPBox][2]:="Matricula De"//[2]:Descricao
    aPBoxPrm[nPBox][3]:=Space(GetSx3Cache("RA_MAT","X3_TAMANHO"))//[3]:String contendo o inicializador do campo
    aPBoxPrm[nPBox][4]:=GetSx3Cache("RA_MAT","X3_PICTURE")//[4]:String contendo a Picture do campo
    aPBoxPrm[nPBox][5]:="AllWaysTrue()" //[5]:String contendo a validacao
    aPBoxPrm[nPBox][6]:="SRA"//[6]:Consulta F3
    aPBoxPrm[nPBox][7]:="AllWaysTrue()"//[7]:String contendo a validacao When
    aPBoxPrm[nPBox][8]:=GetSx3Cache("RA_MAT","X3_TAMANHO")//[8]:Tamanho do MsGet
    aPBoxPrm[nPBox][9]:=.F.//[9]:Flag .T./.F. Parametro Obrigatorio ?
    //------------------------------------------------------------------------------------------------
    aAdd(aPBoxPrm,array(9))
    nPBox:=Len(aPBoxPrm)
    //04----------------------------------------------------------------------------------------------
    aPBoxPrm[nPBox][1]:=1//[1]:1 - MsGet
    aPBoxPrm[nPBox][2]:="Matricula Ate"//[2]:Descricao
    aPBoxPrm[nPBox][3]:=Space(GetSx3Cache("RA_MAT","X3_TAMANHO"))//[3]:String contendo o inicializador do campo
    aPBoxPrm[nPBox][4]:=GetSx3Cache("RA_MAT","X3_PICTURE")//[4]:String contendo a Picture do campo
    aPBoxPrm[nPBox][5]:="NaoVazio()" //[5]:String contendo a validacao
    aPBoxPrm[nPBox][6]:="SRA"//[6]:Consulta F3
    aPBoxPrm[nPBox][7]:="AllWaysTrue()"//[7]:String contendo a validacao When
    aPBoxPrm[nPBox][8]:=GetSx3Cache("RA_MAT","X3_TAMANHO")//[8]:Tamanho do MsGet
    aPBoxPrm[nPBox][9]:=.T.//[9]:Flag .T./.F. Parametro Obrigatorio ?
    //------------------------------------------------------------------------------------------------
    aAdd(aPBoxPrm,array(9))
    nPBox:=Len(aPBoxPrm)
    //05----------------------------------------------------------------------------------------------
    aPBoxPrm[nPBox][1]:=1//[1]:1 - MsGet
    aPBoxPrm[nPBox][2]:="Nome De"//[2]:Descricao
    aPBoxPrm[nPBox][3]:=Space(GetSx3Cache("RA_NOME","X3_TAMANHO"))//[3]:String contendo o inicializador do campo
    aPBoxPrm[nPBox][4]:=GetSx3Cache("RA_NOME","X3_PICTURE")//[4]:String contendo a Picture do campo
    aPBoxPrm[nPBox][5]:="AllWaysTrue()" //[5]:String contendo a validacao
    aPBoxPrm[nPBox][6]:=""//[6]:Consulta F3
    aPBoxPrm[nPBox][7]:="AllWaysTrue()"//[7]:String contendo a validacao When
    aPBoxPrm[nPBox][8]:=GetSx3Cache("RA_NOME","X3_TAMANHO")+80//[8]:Tamanho do MsGet
    aPBoxPrm[nPBox][9]:=.F.//[9]:Flag .T./.F. Parametro Obrigatorio ?
    //------------------------------------------------------------------------------------------------
    aAdd(aPBoxPrm,array(9))
    nPBox:=Len(aPBoxPrm)
    //06----------------------------------------------------------------------------------------------
    aPBoxPrm[nPBox][1]:=1//[1]:1 - MsGet
    aPBoxPrm[nPBox][2]:="Nome Ate"//[2]:Descricao
    aPBoxPrm[nPBox][3]:=Space(GetSx3Cache("RA_NOME","X3_TAMANHO"))//[3]:String contendo o inicializador do campo
    aPBoxPrm[nPBox][4]:=GetSx3Cache("RA_NOME","X3_PICTURE")//[4]:String contendo a Picture do campo
    aPBoxPrm[nPBox][5]:="NaoVazio()" //[5]:String contendo a validacao
    aPBoxPrm[nPBox][6]:=""//[6]:Consulta F3
    aPBoxPrm[nPBox][7]:="AllWaysTrue()"//[7]:String contendo a validacao When
    aPBoxPrm[nPBox][8]:=GetSx3Cache("RA_NOME","X3_TAMANHO")+80//[8]:Tamanho do MsGet
    aPBoxPrm[nPBox][9]:=.T.//[9]:Flag .T./.F. Parametro Obrigatorio ?
    //------------------------------------------------------------------------------------------------
    aAdd(aPBoxPrm,array(9))
    nPBox:=Len(aPBoxPrm)
    //07----------------------------------------------------------------------------------------------
    aPBoxPrm[nPBox][1]:=1//[1]:1 - MsGet
    aPBoxPrm[nPBox][2]:="Centro de Custo De"//[2]:Descricao
    aPBoxPrm[nPBox][3]:=Space(GetSx3Cache("RA_CC","X3_TAMANHO"))//[3]:String contendo o inicializador do campo
    aPBoxPrm[nPBox][4]:=GetSx3Cache("RA_CC","X3_PICTURE")//[4]:String contendo a Picture do campo
    aPBoxPrm[nPBox][5]:="AllWaysTrue()"//[5]:String contendo a validacao
    aPBoxPrm[nPBox][6]:="CTT"//[6]:Consulta F3
    aPBoxPrm[nPBox][7]:="AllWaysTrue()"//[7]:String contendo a validacao When
    aPBoxPrm[nPBox][8]:=GetSx3Cache("RA_CC","X3_TAMANHO")//[8]:Tamanho do MsGet
    aPBoxPrm[nPBox][9]:=.F.//[9]:Flag .T./.F. Parametro Obrigatorio ?
    //------------------------------------------------------------------------------------------------
    aAdd(aPBoxPrm,array(9))
    nPBox:=Len(aPBoxPrm)
    //08----------------------------------------------------------------------------------------------
    aPBoxPrm[nPBox][1]:=1//[1]:1 - MsGet
    aPBoxPrm[nPBox][2]:="Centro de Custo Ate"//[2]:Descricao
    aPBoxPrm[nPBox][3]:=Space(GetSx3Cache("RA_CC","X3_TAMANHO"))//[3]:String contendo o inicializador do campo
    aPBoxPrm[nPBox][4]:=GetSx3Cache("RA_CC","X3_PICTURE")//[4]:String contendo a Picture do campo
    aPBoxPrm[nPBox][5]:="NaoVazio()"//[5]:String contendo a validacao
    aPBoxPrm[nPBox][6]:="CTT"//[6]:Consulta F3
    aPBoxPrm[nPBox][7]:="AllWaysTrue()"//[7]:String contendo a validacao When
    aPBoxPrm[nPBox][8]:=GetSx3Cache("RA_CC","X3_TAMANHO")//[8]:Tamanho do MsGet
    aPBoxPrm[nPBox][9]:=.T.//[9]:Flag .T./.F. Parametro Obrigatorio ?
    //------------------------------------------------------------------------------------------------
    aAdd(aPBoxPrm,array(9))
    nPBox:=Len(aPBoxPrm)
    //09----------------------------------------------------------------------------------------------
    aPBoxPrm[nPBox][1]:=1//[1]:1 - MsGet
    aPBoxPrm[nPBox][2]:="Departamento De"//[2]:Descricao
    aPBoxPrm[nPBox][3]:=Space(GetSx3Cache("RA_DEPTO","X3_TAMANHO"))//[3]:String contendo o inicializador do campo
    aPBoxPrm[nPBox][4]:=GetSx3Cache("RA_DEPTO","X3_PICTURE")//[4]:String contendo a Picture do campo
    aPBoxPrm[nPBox][5]:="AllWaysTrue()" //[5]:String contendo a validacao
    aPBoxPrm[nPBox][6]:="SQB"//[6]:Consulta F3
    aPBoxPrm[nPBox][7]:="AllWaysTrue()"//[7]:String contendo a validacao When
    aPBoxPrm[nPBox][8]:=GetSx3Cache("RA_DEPTO","X3_TAMANHO")//[8]:Tamanho do MsGet
    aPBoxPrm[nPBox][9]:=.F.//[9]:Flag .T./.F. Parametro Obrigatorio ?
    //------------------------------------------------------------------------------------------------
    aAdd(aPBoxPrm,array(9))
    nPBox:=Len(aPBoxPrm)
    //10----------------------------------------------------------------------------------------------
    aPBoxPrm[nPBox][1]:=1//[1]:1 - MsGet
    aPBoxPrm[nPBox][2]:="Departamento Ate"//[2]:Descricao
    aPBoxPrm[nPBox][3]:=Space(GetSx3Cache("RA_DEPTO","X3_TAMANHO"))//[3]:String contendo o inicializador do campo
    aPBoxPrm[nPBox][4]:=GetSx3Cache("RA_DEPTO","X3_PICTURE")//[4]:String contendo a Picture do campo
    aPBoxPrm[nPBox][5]:="NaoVazio()" //[5]:String contendo a validacao
    aPBoxPrm[nPBox][6]:="SQB"//[6]:Consulta F3
    aPBoxPrm[nPBox][7]:="AllWaysTrue()"//[7]:String contendo a validacao When
    aPBoxPrm[nPBox][8]:=GetSx3Cache("RA_CC","X3_TAMANHO")//[8]:Tamanho do MsGet
    aPBoxPrm[nPBox][9]:=.T.//[9]:Flag .T./.F. Parametro Obrigatorio ?
    //------------------------------------------------------------------------------------------------
    aAdd(aPBoxPrm,array(9))
    nPBox:=Len(aPBoxPrm)
    //11----------------------------------------------------------------------------------------------
    aPBoxPrm[nPBox][1]:=1//[1]:1 - MsGet
    aPBoxPrm[nPBox][2]:="Turno De"//[2]:Descricao
    aPBoxPrm[nPBox][3]:=Space(GetSx3Cache("RA_TNOTRAB","X3_TAMANHO"))//[3]:String contendo o inicializador do campo
    aPBoxPrm[nPBox][4]:=GetSx3Cache("RA_TNOTRAB","X3_PICTURE")//[4]:String contendo a Picture do campo
    aPBoxPrm[nPBox][5]:="AllWaysTrue()" //[5]:String contendo a validacao
    aPBoxPrm[nPBox][6]:="SR6"//[6]:Consulta F3
    aPBoxPrm[nPBox][7]:="AllWaysTrue()"//[7]:String contendo a validacao When
    aPBoxPrm[nPBox][8]:=GetSx3Cache("RA_TNOTRAB","X3_TAMANHO")//[8]:Tamanho do MsGet
    aPBoxPrm[nPBox][9]:=.F.//[9]:Flag .T./.F. Parametro Obrigatorio ?
    //------------------------------------------------------------------------------------------------
    aAdd(aPBoxPrm,array(9))
    nPBox:=Len(aPBoxPrm)
    //12----------------------------------------------------------------------------------------------
    aPBoxPrm[nPBox][1]:=1//[1]:1 - MsGet
    aPBoxPrm[nPBox][2]:="Turno Ate"//[2]:Descricao
    aPBoxPrm[nPBox][3]:=Space(GetSx3Cache("RA_TNOTRAB","X3_TAMANHO"))//[3]:String contendo o inicializador do campo
    aPBoxPrm[nPBox][4]:=GetSx3Cache("RA_TNOTRAB","X3_PICTURE")//[4]:String contendo a Picture do campo
    aPBoxPrm[nPBox][5]:="NaoVazio()" //[5]:String contendo a validacao
    aPBoxPrm[nPBox][6]:="SR6"//[6]:Consulta F3
    aPBoxPrm[nPBox][7]:="AllWaysTrue()"//[7]:String contendo a validacao When
    aPBoxPrm[nPBox][8]:=GetSx3Cache("RA_TNOTRAB","X3_TAMANHO")//[8]:Tamanho do MsGet
    aPBoxPrm[nPBox][9]:=.T.//[9]:Flag .T./.F. Parametro Obrigatorio ?
    //------------------------------------------------------------------------------------------------
    aAdd(aPBoxPrm,array(9))
    nPBox:=Len(aPBoxPrm)
    //13----------------------------------------------------------------------------------------------
    aPBoxPrm[nPBox][1]:=1//[1]:1 - MsGet
    aPBoxPrm[nPBox][2]:="Periodo De"//[2]:Descricao
    aPBoxPrm[nPBox][3]:=Ctod("")//[3]:String contendo o inicializador do campo
    aPBoxPrm[nPBox][4]:="@D"//[4]:String contendo a Picture do campo
    aPBoxPrm[nPBox][5]:="AllWaysTrue()" //[5]:String contendo a validacao
    aPBoxPrm[nPBox][6]:=""//[6]:Consulta F3
    aPBoxPrm[nPBox][7]:="AllWaysTrue()"//[7]:String contendo a validacao When
    aPBoxPrm[nPBox][8]:=50//[8]:Tamanho do MsGet
    aPBoxPrm[nPBox][9]:=.F.//[9]:Flag .T./.F. Parametro Obrigatorio ?
    //------------------------------------------------------------------------------------------------
    aAdd(aPBoxPrm,array(9))
    nPBox:=Len(aPBoxPrm)
    //14----------------------------------------------------------------------------------------------
    aPBoxPrm[nPBox][1]:=1//[1]:1 - MsGet
    aPBoxPrm[nPBox][2]:="Periodo Ate"//[2]:Descricao
    aPBoxPrm[nPBox][3]:=Ctod("")//[3]:String contendo o inicializador do campo
    aPBoxPrm[nPBox][4]:="@D"//[4]:String contendo a Picture do campo
    aPBoxPrm[nPBox][5]:="NaoVazio()" //[5]:String contendo a validacao
    aPBoxPrm[nPBox][6]:=""//[6]:Consulta F3
    aPBoxPrm[nPBox][7]:="AllWaysTrue()"//[7]:String contendo a validacao When
    aPBoxPrm[nPBox][8]:=50//[8]:Tamanho do MsGet
    aPBoxPrm[nPBox][9]:=.T.//[9]:Flag .T./.F. Parametro Obrigatorio ?
    aAdd(aPBoxPrm,array(9))
    nPBox:=Len(aPBoxPrm)
    //15----------------------------------------------------------------------------------------------
    aPBoxPrm[nPBox][1]:=1//[1]:1 - MsGet
    aPBoxPrm[nPBox][2]:="Eventos ADN"//[2]:Descricao
    aPBoxPrm[nPBox][3]:=""//[3]:String contendo o inicializador do campo
    aPBoxPrm[nPBox][4]:="@!"//[4]:String contendo a Picture do campo
    aPBoxPrm[nPBox][5]:="NaoVazio()" //[5]:String contendo a validacao
    aPBoxPrm[nPBox][6]:=""//[6]:Consulta F3
    aPBoxPrm[nPBox][7]:="StaticCall(uBDExcel,getADNList)"//[7]:String contendo a validacao When
    aPBoxPrm[nPBox][8]:=110//[8]:Tamanho do MsGet
    aPBoxPrm[nPBox][9]:=.T.//[9]:Flag .T./.F. Parametro Obrigatorio ?

    //------------------------------------------------------------------------------------------------
    aPBoxRet:=array(nPBox)
    cPBoxTit:=OemtoAnsi("Informe os parametros")

    //------------------------------------------------------------------------------------------------
        //Carrega a Interface com o usuario
        //Parambox(aParametros,@cTitle,@aRet,[bOk],[aButtons],[lCentered],[nPosX],[nPosy],[oDlgWizard],[cLoad],[lCanSave],[lUserSave])
    //------------------------------------------------------------------------------------------------
    while (.not.(lParamBox:=ParamBox(@aPBoxPrm,@cPBoxTit,@aPBoxRet,nil,nil,.T.,nil,nil,nil,nil,.T.,.T.)))
        //------------------------------------------------------------------------------------------------
            //...Verifica se Deseja "Abortar" a Geracao e...
        //------------------------------------------------------------------------------------------------
        lParamBox:=MsgYesNo("Deseja Abortar a Geracao?","Atencao!")
        //------------------------------------------------------------------------------------------------
            //...Se optou por "Abortar" ...
        //------------------------------------------------------------------------------------------------
        if (lParamBox)
            //------------------------------------------------------------------------------------------------
                //...Inverte o Estado de lParamBox ...
            //------------------------------------------------------------------------------------------------
            lParamBox:=.F.
            //------------------------------------------------------------------------------------------------
                //...Abandona.
            //------------------------------------------------------------------------------------------------
            exit
        endif
    end while

    //------------------------------------------------------------------------------------------------
        //Se confirmou ParamBox...
    //------------------------------------------------------------------------------------------------
    if (lParamBox)
        //------------------------------------------------------------------------------------------------
            //...Processa cada elemento e...
        //------------------------------------------------------------------------------------------------
        for nPBox:=1 to Len(aPBoxPrm)
            //------------------------------------------------------------------------------------------------
                //...Carrega os Parametros/Conteudos em oPergunte
            //------------------------------------------------------------------------------------------------
            oPergunte:Set(aPBoxPrm[nPBox][2],aPBoxRet[nPBox])
        next nPBox
    endif

    //------------------------------------------------------------------------------------------------
        //Retorna .T. se confirmou ParamBox, caso contrario: .F.
    //------------------------------------------------------------------------------------------------
    return(lParamBox)

//-------------------------------------------------------------------------------------
    /*
        Programa:uBDExcel.prw
        Funcao:getADNList()
        Autor:Marinaldo de Jesus [ConnectTI]
        Data:06/09/2019
        Desc.:Programa para retornar Consulta Padrao "Especifica" baseada em f_Opcoes
    */
//-------------------------------------------------------------------------------------
static function getADNList() as logical

    static _cSM0F3Ret   as character

    local aArea         as array

    local aOpcoes       as array

    local cAlias        as character

    local cTitulo       as character

    local cReadVar      as character

    local cF3Ret        as character
    local ctoken        as character
    local cOpcoes       as character
    local cCodRet       as character

    local cIDPONNot     as character

    local lgetADNList   as logical

    local nD            as numeric
    local nJ            as numeric

    local nTamKey       as numeric
    local nElemRet      as numeric

    local nSP9RecNo     as numeric

    local uVarRet

    //------------------------------------------------------------------------------------------------
        //Obtem o conteudo do campo utilizado na Consulta Padrao Customizada
    //------------------------------------------------------------------------------------------------
    DEFAULT _cSM0F3Ret:=""

    aArea:=getArea()

    begin sequence

        cReadVar:=readVar()
        if empty(cReadVar)
            break
        endif

        if (!("MV_PAR15"$cReadVar))
            break
        endif

        aOpcoes:=array(0)

        cTitulo:=OemtoAnsi("Selecione os Eventos de ADN")

        cF3Ret:=""
        ctoken:=","
        cOpcoes:=""
        cCodRet:=""

        //------------------------------------------------------------------------------------------------
            //Obtemo Tamanho da chave
        //------------------------------------------------------------------------------------------------
        nTamKey:=getSX3Cache("P9_CODIGO","X3_TAMANHO")

        //------------------------------------------------------------------------------------------------
            //Remove o Separador
        //------------------------------------------------------------------------------------------------
        uVarRet:=StrTran(_cSM0F3Ret,ctoken,"")

        cIDPONNot:="('003N','004A','006A','026A','027N','028A','031A','034A','037A')"
        cIDPONNot:="%"+cIDPONNot+"%"

        cAlias:=getNextAlias()
        beginSQL alias cAlias
            SELECT SP9.R_E_C_N_O_ SP9RECNO
              FROM %table:SP9% SP9
             WHERE SP9.%notDel%
               AND ((SP9.P9_IDPON IN %exp:cIDPONNot%) OR (SP9.P9_DESC LIKE '%NOT%'))
        endSQL

        nElemRet:=0

        //------------------------------------------------------------------------------------------------
            //Carrega as Opcoes para Consulta (Codigo e Nome)
        //------------------------------------------------------------------------------------------------
        while (cAlias)->(!eof())

            nSP9RecNo:=(cAlias)->SP9RECNO
            SP9->(dbGoTo(nSP9RecNo))

            //------------------------------------------------------------------------------------------------
                //Verifica se elemento e Exclusivo
            //------------------------------------------------------------------------------------------------
            if (cAlias)->(UniqueKey({"P9_CODIGO"}))
                //------------------------------------------------------------------------------------------------
                    //Calcula o Maximo de Elementos a serem Selecionados
                //------------------------------------------------------------------------------------------------
                ++nElemRet
                //------------------------------------------------------------------------------------------------
                    //Adiciona os Elementos para Selecao: Codigo+Descricao
                //------------------------------------------------------------------------------------------------
                SP9->(aAdd(aOpcoes,SP9->P9_CODIGO+"-"+SP9->P9_DESC))
                //------------------------------------------------------------------------------------------------
                    //Concatena as Chaves
                //------------------------------------------------------------------------------------------------
                cOpcoes+=SP9->P9_CODIGO
            endif

            //------------------------------------------------------------------------------------------------
                //Proximo Registro
            //------------------------------------------------------------------------------------------------
            (cAlias)->(dbSkip())

        end while

        (cAlias)->(dbCloseArea())
        dbSelectArea("SP9")

        //------------------------------------------------------------------------------------------------
            //Executa f_Opcoes para Selecionar ou Mostrar os Registros Selecionados
        //------------------------------------------------------------------------------------------------
        if f_Opcoes(@uVarRet,;//Variavel de Retorno
                    cTitulo,;//Titulo da Coluna com as opcoes
                    @aOpcoes,;//Opcoes de Escolha (Array de Opcoes)
                    @cOpcoes,;//String de Opcoes para Retorno
                    nil,;//Nao Utilizado
                    nil,;//Nao Utilizado
                    .F.,;//Se a Selecao sera de apenas 1 Elemento por vez
                    nTamKey,;//Tamanho da Chave
                    nElemRet,;//No maximo de elementos na variavel de retorno
                    .T.,;//Inclui Botoes para Selecao de Multiplos Itens
                    .F.,;//Se as opcoes serao montadas a partir de ComboBox de Campo ( X3_CBOX )
                    nil,;//Qual o Campo para a Montagem do aOpcoes
                    .F.,;//Nao Permite a Ordenacao
                    .F.,;//Nao Permite a Pesquisa
                    .F.,;//forca o Retorno Como Array
                    nil;//Consulta F3
            )

            //------------------------------------------------------------------------------------------------
                //Ajusta o Retorno caso exista o separador
            //------------------------------------------------------------------------------------------------
            if (ctoken$cOpcoes)
                aOpcoes:=_StrtokArr(uVarRet,ctoken)
                uVarRet:=""
                aEval(aOpcoes,{uVarRet+=PadR(e,nTamKey)})
            endif

            //------------------------------------------------------------------------------------------------
                //Analisa o Retorno
            //------------------------------------------------------------------------------------------------
            nJ:=Len(uVarRet)
            for nD:=1 to nJ Step nTamKey
                //------------------------------------------------------------------------------------------------
                    //Obtem o Codigo de Retorno Baseado no Tamanho da Chave
                //------------------------------------------------------------------------------------------------
                 cCodRet:=SubStr(uVarRet,nD,nTamKey)
                //------------------------------------------------------------------------------------------------
                    //Normaliza
                //------------------------------------------------------------------------------------------------
                cF3Ret+=PadR(cCodRet,nTamKey)
                //------------------------------------------------------------------------------------------------
                    //Define o Retorno com o separador ","
                //------------------------------------------------------------------------------------------------
                if (nD<nJ)
                    cF3Ret+=ctoken
                endif
            next nD

        else

           //------------------------------------------------------------------------------------------------
                //Se nao confirmou a f_Opcoes retorna o Conteudo de entrada
            //------------------------------------------------------------------------------------------------
            cF3Ret:=uVarRet

        endif

        //------------------------------------------------------------------------------------------------
            //Alimenta a variavel static para uso no Retorno da Consulta Padrao.
        //------------------------------------------------------------------------------------------------
        _cSM0F3Ret:=cF3Ret

        if !empty(cF3Ret)
            &(cReadVar):=cF3Ret
        endif

    end sequence

    //------------------------------------------------------------------------------------------------
        //Restaura os Dados de Entrada
    //------------------------------------------------------------------------------------------------
    restArea(aArea)

    DEFAULT lgetADNList:=.T.

    return(lgetADNList)

//------------------------------------------------------------------------------------------------
    /*
        Programa:uBDExcel.prw
        Funcao:QueryView()
        Autor:Marinaldo de Jesus [ConnectTI]
        Data:10/08/2019
        Descricao:Elabora View para processamento
    */
//------------------------------------------------------------------------------------------------
static function QueryView(oPergunte as object,cAlias as character,nColMarcs as numeric) as numeric

    local cFilDe    as character
    local cFilAte   as caracter
    local cMatDe    as character
    local cMatAte   as character
    local cNomeDe   as character
    local cNomeAte  as character
    local cCCDe     as character
    local cCCAte    as character
    local cDeptoDe  as character
    local cDeptoAte as character
    local cTnoDe    as character
    local cTnoAte   as character
    local cPerDe    as character
    local cPerAte   as character

    local dPerDe    as date
    local dPerAte   as date

    local nRecCount as numeric

    cFilDe:=oPergunte:Get("Filial De")
    cFilAte:=oPergunte:Get("Filial Ate")

    cMatDe:=oPergunte:Get("Matricula De")
    cMatAte:=oPergunte:Get("Matricula Ate")

    cNomeDe:=oPergunte:Get("Nome De")
    cNomeAte:=oPergunte:Get("Nome Ate")

    cCCDe:=oPergunte:Get("Centro de Custo De")
    cCCAte:=oPergunte:Get("Centro de Custo Ate")

    cDeptoDe:=oPergunte:Get("Departamento De")
    cDeptoAte:=oPergunte:Get("Departamento Ate")

    cTnoDe:=oPergunte:Get("Turno De")
    cTnoAte:=oPergunte:Get("Turno Ate")

    dPerDe:=oPergunte:Get("Periodo De")
    dPerAte:=oPergunte:Get("Periodo Ate")

    cPerDe:=DToS(dPerDe)
    cPerAte:=DToS(dPerAte)

    beginSQL alias cAlias
        %noParser%
        SELECT MAX(t.NCOLMARCS) NCOLMARCS
          FROM (
                    SELECT COUNT(*) NCOLMARCS
                      FROM %table:SP8% SP8
                          ,%table:SRA% SRA
                     WHERE SP8.%notDel%
                       AND SRA.%notDel%
                       AND SP8.P8_APONTA='S'
                       AND SP8.P8_PAPONTA<>' '
                       AND SP8.P8_ORDEM<>' '
                       AND SP8.P8_TPMCREP<>'D'
                       AND SRA.RA_FILIAL=SP8.P8_FILIAL
                       AND SRA.RA_MAT=SP8.P8_MAT
                       AND SRA.RA_FILIAL BETWEEN %exp:cFilDe% AND %exp:cFilAte%
                       AND SRA.RA_MAT BETWEEN %exp:cMatDe% AND %exp:cMatAte%
                       AND SRA.RA_NOME BETWEEN %exp:cNomeDe% AND %exp:cNomeAte%
                       AND SRA.RA_CC BETWEEN %exp:cCCDe% AND %exp:cCCAte%
                       AND SRA.RA_DEPTO BETWEEN %exp:cDeptoDe% AND %exp:cDeptoAte%
                       AND SRA.RA_TNOTRAB BETWEEN %exp:cTnoDe% AND %exp:cTnoAte%
                       AND SP8.P8_DATA BETWEEN %exp:cPerDe% AND %exp:cPerAte%
                  GROUP BY SP8.P8_FILIAL
                          ,SP8.P8_MAT
                          ,SP8.P8_PAPONTA
                          ,SP8.P8_ORDEM
                     UNION
                    SELECT COUNT(*) NCOLMARCS
                      FROM %table:SPG% SPG
                          ,%table:SRA% SRA
                     WHERE SPG.%notDel%
                       AND SRA.%notDel%
                       AND SPG.PG_APONTA='S'
                       AND SPG.PG_PAPONTA<>' '
                       AND SPG.PG_ORDEM<>' '
                       AND SPG.PG_TPMCREP<>'D'
                       AND SRA.RA_FILIAL=SPG.PG_FILIAL
                       AND SRA.RA_MAT=SPG.PG_MAT
                       AND SRA.RA_FILIAL BETWEEN %exp:cFilDe% AND %exp:cFilAte%
                       AND SRA.RA_MAT BETWEEN %exp:cMatDe% AND %exp:cMatAte%
                       AND SRA.RA_NOME BETWEEN %exp:cNomeDe% AND %exp:cNomeAte%
                       AND SRA.RA_CC BETWEEN %exp:cCCDe% AND %exp:cCCAte%
                       AND SRA.RA_DEPTO BETWEEN %exp:cDeptoDe% AND %exp:cDeptoAte%
                       AND SRA.RA_TNOTRAB BETWEEN %exp:cTnoDe% AND %exp:cTnoAte%
                       AND SPG.PG_DATA BETWEEN %exp:cPerDe% AND %exp:cPerAte%
                  GROUP BY SPG.PG_FILIAL
                          ,SPG.PG_MAT
                          ,SPG.PG_PAPONTA
                          ,SPG.PG_ORDEM
          ) t
    endSQL

    nColMarcs:=(cAlias)->NCOLMARCS
    nColMarcs+=Mod(nColMarcs,2)

    (cAlias)->(dbCloseArea())
    dbSelectArea("SRA")

    beginSQL alias cAlias
        %noParser%
        SELECT t.*
          FROM (
            SELECT SP8.*
              FROM  (
                    SELECT SRA.RA_FILIAL
                          ,SRA.RA_CC
                          ,SRA.RA_CODFUNC
                          ,SRA.RA_MAT
                          ,COALESCE(SP8.P8_PAPONTA,' ') P8_PAPONTA
                          ,COALESCE(SP8.P8_ORDEM,' ')   P8_ORDEM
                          ,COALESCE(SP8.P8_DATA,' ')    P8_DATA
                          ,COALESCE(SP8.P8_TPMARCA,' ') P8_TPMARCA
                          ,COALESCE(SP8.P8_HORA,0)      P8_HORA
                          ,COALESCE(SRA.R_E_C_N_O_,0)   SRARECNO
                          ,COALESCE(SP8.R_E_C_N_O_,0)   SP8RECNO
                          ,COALESCE(SRJ.R_E_C_N_O_,0)   SRJRECNO
                          ,COALESCE(CTT.R_E_C_N_O_,0)   CTTRECNO
                          ,'SP8'                        ALIASTABLE
                        FROM %table:SRA% SRA
                FULL OUTER
                      JOIN %table:SRJ% SRJ ON SRA.RA_CODFUNC=SRJ.RJ_FUNCAO
                FULL OUTER
                      JOIN %table:CTT% CTT ON SRA.RA_CC=CTT.CTT_CUSTO
                FULL OUTER
                      JOIN %table:SP8% SP8 ON SRA.RA_FILIAL=SP8.P8_FILIAL AND SRA.RA_MAT=SP8.P8_MAT
                     WHERE SRA.%notDel%
                       AND SRJ.%notDel%
                       AND CTT.%notDel%
                       AND SP8.%notDel%
                       AND SRA.RA_FILIAL=SP8.P8_FILIAL
                       AND SRA.RA_MAT=SP8.P8_MAT
                       AND SP8.P8_PAPONTA<>' '
                       AND SP8.P8_ORDEM<>' '
                       AND SP8.P8_APONTA='S'
                       AND SP8.P8_TPMCREP<>'D'
                       AND SRA.RA_FILIAL BETWEEN %exp:cFilDe% AND %exp:cFilAte%
                       AND SRA.RA_MAT BETWEEN %exp:cMatDe% AND %exp:cMatAte%
                       AND SRA.RA_NOME BETWEEN %exp:cNomeDe% AND %exp:cNomeAte%
                       AND SRA.RA_CC BETWEEN %exp:cCCDe% AND %exp:cCCAte%
                       AND SRA.RA_DEPTO BETWEEN %exp:cDeptoDe% AND %exp:cDeptoAte%
                       AND SRA.RA_TNOTRAB BETWEEN %exp:cTnoDe% AND %exp:cTnoAte%
                       AND SP8.P8_DATA BETWEEN %exp:cPerDe% AND %exp:cPerAte%
             ) SP8
             UNION
            SELECT SPG.*
              FROM (
                    SELECT SRA.RA_FILIAL
                          ,SRA.RA_CC
                          ,SRA.RA_CODFUNC
                          ,SRA.RA_MAT
                          ,COALESCE(SPG.PG_PAPONTA,' ') P8_PAPONTA
                          ,COALESCE(SPG.PG_ORDEM,' ')   P8_ORDEM
                          ,COALESCE(SPG.PG_DATA,' ')    P8_DATA
                          ,COALESCE(SPG.PG_TPMARCA,' ') P8_TPMARCA
                          ,COALESCE(SPG.PG_HORA,0)      P8_HORA
                          ,COALESCE(SRA.R_E_C_N_O_,0)   SRARECNO
                          ,COALESCE(SPG.R_E_C_N_O_,0)   SP8RECNO
                          ,COALESCE(SRJ.R_E_C_N_O_,0)   SRJRECNO
                          ,COALESCE(CTT.R_E_C_N_O_,0)   CTTRECNO
                          ,'SPG'                        ALIASTABLE
                        FROM %table:SRA% SRA
                FULL OUTER
                      JOIN %table:SRJ% SRJ ON SRA.RA_CODFUNC=SRJ.RJ_FUNCAO
                FULL OUTER
                      JOIN %table:CTT% CTT ON SRA.RA_CC=CTT.CTT_CUSTO
                FULL OUTER
                      JOIN %table:SPG% SPG ON SRA.RA_FILIAL=SPG.PG_FILIAL AND SRA.RA_MAT=SPG.PG_MAT
                     WHERE SRA.%notDel%
                       AND SRJ.%notDel%
                       AND CTT.%notDel%
                       AND SPG.%notDel%
                       AND SRA.RA_FILIAL=SPG.PG_FILIAL
                       AND SRA.RA_MAT=SPG.PG_MAT
                       AND SPG.PG_PAPONTA<>' '
                       AND SPG.PG_ORDEM<>' '
                       AND SPG.PG_APONTA='S'
                       AND SPG.PG_TPMCREP<>'D'
                       AND SRA.RA_FILIAL BETWEEN %exp:cFilDe% AND %exp:cFilAte%
                       AND SRA.RA_MAT BETWEEN %exp:cMatDe% AND %exp:cMatAte%
                       AND SRA.RA_NOME BETWEEN %exp:cNomeDe% AND %exp:cNomeAte%
                       AND SRA.RA_CC BETWEEN %exp:cCCDe% AND %exp:cCCAte%
                       AND SRA.RA_DEPTO BETWEEN %exp:cDeptoDe% AND %exp:cDeptoAte%
                       AND SRA.RA_TNOTRAB BETWEEN %exp:cTnoDe% AND %exp:cTnoAte%
                       AND SPG.PG_DATA BETWEEN %exp:cPerDe% AND %exp:cPerAte%
            ) SPG
        ) t
      ORDER BY t.RA_FILIAL
              ,t.RA_CC
              ,t.RA_CODFUNC
              ,t.RA_MAT
              ,t.P8_PAPONTA
              ,t.P8_ORDEM
              ,t.P8_DATA
              ,t.P8_TPMARCA
              ,t.P8_HORA
    endSQL

    //-------------------------------------------------------------------------------------
    //Garante que a Area de Trabalho sera a da View
    //-------------------------------------------------------------------------------------
    dbSelectArea(cAlias)

    //-------------------------------------------------------------------------------------
    //Obtem o total de registros a serem processados
    //-------------------------------------------------------------------------------------
    COUNT TO nRecCount

    //-------------------------------------------------------------------------------------
    //Remonta a View
    //-------------------------------------------------------------------------------------
    (cAlias)->(dbGoTop())

    return(nRecCount)

//------------------------------------------------------------------------------------------------
/*
    Programa:uBDExcel.prw
    Funcao:nToTime()
    Autor:Marinaldo de Jesus [ConnectTI]
    Data:06/09/2019
    Descricao:Formata Numero como Time
*/
//------------------------------------------------------------------------------------------------
static function nToTime(nTime as numeric,lSeconds as logical) as character
    local cTime    as character
    DEFAULT lSeconds:=.T.
    if (nTime==0)
        cTime:="00:00"
    else
        cTime:=Transform(nTime,"@Z 99.99")
        cTime:=LTrim(cTime)
        cTime:=PadL(cTime,5,"0")
        cTime:=strTran(cTime,".",":")
    endif
    cTime+=if(lSeconds,":00","")
    return(cTime)

//------------------------------------------------------------------------------------------------
/*
    Programa:uBDExcel.prw
    Funcao:getTAbono()
    Autor:Marinaldo de Jesus [ConnectTI]
    Data:06/09/2019
    Descricao:Obtem o Total de Abonos na Data conforme Tipo
*/
//------------------------------------------------------------------------------------------------
static function getTAbono(dDate as date,cTpAbon as character) as numeric
    local aArea     as array
    local cDate     as character
    local cAlias    as character
    local cXTpAbon  as character
    local nTimes    as numeric
    aArea:=getArea()
    cDate:=DToS(dDate)
    cAlias:=getNextAlias()
    cXTpAbon:=cTpAbon
    beginSQL alias cAlias
        SELECT SPK.PK_HRSABO
          FROM %table:SPK% SPK
              ,%table:SP6% SP6
         WHERE SPK.%notDel%
           AND SP6.%notDel%
           AND SPK.PK_FILIAL=%exp:SRA->RA_FILIAL%
           AND SPK.PK_MAT=%exp:SRA->RA_MAT%
           AND SPK.PK_CODABO=SP6.P6_CODIGO
           AND SP6.P6_XTPABON=%exp:cXTpAbon%
           AND SPK.PK_DATA=%exp:cDate%
    endSQL
    nTimes:=0
    while (cAlias)->(!eof())
        nTimes:=__TimeSum(nTimes,(cAlias)->PK_HRSABO)
        (cAlias)->(dbSkip())
    end while
    (cAlias)->(dbCloseArea())
    dbSelectArea("SPK")
    restArea(aArea)
    return(nTimes)

//------------------------------------------------------------------------------------------------
/*
    Programa:uBDExcel.prw
    Funcao:getTBH()
    Autor:Marinaldo de Jesus [ConnectTI]
    Data:06/09/2019
    Descricao:Obtem o Total de BH na Data conforme Tipo
*/
//------------------------------------------------------------------------------------------------
static function getTBH(dDate as date,cTipoCod as character) as numeric
    local aArea     as array
    local cDate     as character
    local cAlias    as character
    local cP9TpCod  as character
    local nTimes    as numeric
    aArea:=getArea()
    cDate:=DToS(dDate)
    cAlias:=getNextAlias()
    cP9TpCod:=cTipoCod
    beginSQL alias cAlias
        SELECT SPI.PI_QUANTV
          FROM %table:SPI% SPI
              ,%table:SP9% SP9
         WHERE SPI.%notDel%
           AND SP9.%notDel%
           AND SPI.PI_FILIAL=%exp:SRA->RA_FILIAL%
           AND SPI.PI_MAT=%exp:SRA->RA_MAT%
           AND SPI.PI_PD=SP9.P9_CODIGO
           AND SP9.P9_TIPOCOD=%exp:cP9TpCod%
           AND SPI.PI_DATA=%exp:cDate%
    endSQL
    nTimes:=0
    while (cAlias)->(!eof())
        nTimes:=__TimeSum(nTimes,(cAlias)->PI_QUANTV)
        (cAlias)->(dbSkip())
    end while
    (cAlias)->(dbCloseArea())
    dbSelectArea("SPI")
    restArea(aArea)
    return(nTimes)

//------------------------------------------------------------------------------------------------
/*
    Programa:uBDExcel.prw
    Funcao:getTAbono()
    Autor:Marinaldo de Jesus [ConnectTI]
    Data:06/09/2019
    Descricao:Obtem o Total de Abonos na Data conforme Tipo
*/
//------------------------------------------------------------------------------------------------
static function getTADNot(dDate as date,cADNList as character,lSPC as logical) as numeric
    local aArea     as array
    local cDate     as character
    local cAlias    as character
    local cEList    as character
    local nTimes    as numeric
    aArea:=getArea()
    cDate:=DToS(dDate)
    cAlias:=getNextAlias()
    cEList:=cADNList
    cEList:="%("+cEList+")%"
    if (lSPC)
        beginSQL alias cAlias
            SELECT SPC.PC_QUANTC QUANTC
                  ,SPC.PC_QUANTI QUANTI
              FROM %table:SPC% SPC
             WHERE SPC.%notDel%
               AND SPC.PC_FILIAL=%exp:SRA->RA_FILIAL%
               AND SPC.PC_MAT=%exp:SRA->RA_MAT%
               AND (SPC.PC_PD IN %exp:cEList% OR SPC.PC_PDI IN %exp:cEList%)
               AND SPC.PC_DATA=%exp:cDate%
        endSQL
    else
        beginSQL alias cAlias
            SELECT SPH.PH_QUANTC QUANTC
                  ,SPH.PH_QUANTI QUANTI
              FROM %table:SPH% SPH
             WHERE SPH.%notDel%
               AND SPH.PH_FILIAL=%exp:SRA->RA_FILIAL%
               AND SPH.PH_MAT=%exp:SRA->RA_MAT%
               AND (SPH.PH_PD IN %exp:cEList% OR SPH.PH_PDI IN %exp:cEList%)
               AND SPH.PH_DATA=%exp:cDate%
        endSQL
    endif
    nTimes:=0
    while (cAlias)->(!eof())
        nTimes:=__TimeSum(nTimes,(cAlias)->(if((cAlias)->QUANTI>0,(cAlias)->QUANTI,(cAlias)->QUANTC)))
        (cAlias)->(dbSkip())
    end while
    (cAlias)->(dbCloseArea())
    dbSelectArea(if(lSPC,"SPC","SPH"))
    restArea(aArea)
    return(nTimes)

//------------------------------------------------------------------------------------------------
/*
    Programa:uBDExcel.prw
    Funcao:ProcRedefine()
    Autor:Marinaldo de Jesus [ConnectTI]
    Data:10/08/2019
    Descricao:Redefine as dimensoes do dialog de processamento
*/
//------------------------------------------------------------------------------------------------
static function ProcRedefine(oProcess as object,oFont as object,nLeft as numeric,nWidth as numeric,nCTLFLeft as numeric,lODlgF as logical,lODlgW as logical) as logical
    local aClassData    as array
    local laMeter       as logical
    local nObj          as numeric
    local nMeter        as numeric
    local nMeters       as numeric
    local lProcRedefine as logical
    lProcRedefine:=.F.
    if (valType(oProcess)=="O")
        aClassData:=ClassDataArr(oProcess,.T.)
        laMeter:=(aScan(aClassData,{|e|e[1]=="AMETER"})>0)
        if (laMeter)
            DEFAULT oFont:=TFont():New("Lucida Console",nil,12,nil,.T.)
            DEFAULT nLeft:=40
            DEFAULT nWidth:=95
            nMeters:=Len(oProcess:aMeter)
            for nMeter:=1 to nMeters
                for nObj:=1 to 2
                    oProcess:aMeter[nMeter][nObj]:oFont:=oFont
                    oProcess:aMeter[nMeter][nObj]:nWidth+=nWidth
                    oProcess:aMeter[nMeter][nObj]:nLeft-=nLeft
                next nObj
            next nMeter
        else
            DEFAULT oFont:=TFont():New("Lucida Console",nil,18,nil,.T.)
            DEFAULT lODlgF:=.T.
            DEFAULT lODlgW:=.F.
            DEFAULT nLeft:=100
            DEFAULT nWidth:=200
            DEFAULT nCTLFLeft:=if(lODlgW,nWidth,nWidth/2)
            if (lODlgF)
                oProcess:oDlg:oFont:=oFont
            endif
            if (lODlgW)
                oProcess:oDlg:nWidth+=nWidth
                oProcess:oDlg:nLeft-=(nWidth/2)
            endif
            oProcess:oMsg1:oFont:=oFont
            oProcess:oMsg2:oFont:=oFont
            oProcess:oMsg1:nLeft-=nLeft
            oProcess:oMsg1:nWidth+=nWidth
            oProcess:oMsg2:nLeft-=nLeft
            oProcess:oMsg2:nWidth+=nWidth
            oProcess:oMeter1:nWidth+=nWidth
            oProcess:oMeter1:nLeft-=nLeft
            oProcess:oMeter2:nWidth+=nWidth
            oProcess:oMeter2:nLeft-=nLeft
            if (valType(oProcess:oDlg:oCTLFocus)=="O")
                oProcess:oDlg:oCTLFocus:nLeft+=nCTLFLeft
            endif
            oProcess:oDlg:Refresh(.T.)
            oProcess:oDlg:SetFocus()
        endif
        lProcRedefine:=.T.
        ProcessMessage()
    endif
    return(lProcRedefine)

static procedure __Dummy()
    if (.F.)
        __Dummy()
        getADNList()
    endif
    return
