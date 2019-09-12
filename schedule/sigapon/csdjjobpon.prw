//------------------------------------------------------------------------------------------------
/*
    Programa:CSDJJobPon.prw
    Autor: Marinaldo de Jesus [CSDJ/ConnectTI]
    Data:10/09/2019
    Descricao:Job para Leitura e Apontamento das Marcacoes
    Sintaxe:CSDJJobPon()
*/
//------------------------------------------------------------------------------------------------
main procedure CSDJJobPon(aParameters)
    local aFiliais       as array
    local cEmp           as character
    local lSetCentury    as logical
    local nParameters    as numeric
    DEFAULT aParameters:={"01","01,02,03,04,05"}
    lSetCentury:=__SetCentury("on")
    begin sequence
        nParameters:=len(aParameters)
        if (!(nParameters>=1))
            break
        endif
        cEmp:=aParameters[1]
        if (nParameters>=2)
            aFiliais:=strTokArr2(aParameters[2],",")
        else
            aFiliais:=strTokArr2("01,02,03,04,05",",")
        endif
        if (!(len(aFiliais)>0))
            break
        endif
        NJobPon(@cEmp,@aFiliais)
    end sequence
    if !(lSetCentury)
        __SetCentury("off")
    endif
    return
//------------------------------------------------------------------------------------------------
/*
    Programa:CSDJJobPon.prw
    Autor: Marinaldo de Jesus [ConnectTI]
    Data:10/09/2019
    Descricao:Job para Leitura e Apontamento das Marcacoes
    Sintaxe:NJobPon(cEmp,aFiliais)
*/
//------------------------------------------------------------------------------------------------
static procedure NJobPon(cEmp as character,aFiliais as array)

    local bExec     as block
    local bMsgOut   as block

    local cMsgOut   as character
    local cInternal as character
    local cFunction as character

    local oSchedule as object

    bMsgOut:={|cMsg,cEmp,cFil|StrTran(StrTran(cMsg,"__EMP__",cEmp),"__FIL__",cFil)}

    cMsgOut:="Empresa [__EMP__][__FIL__]"
    cInternal:=("CSDJJobPon :: "+cMsgOut)

    oSchedule:=NDJLIB011():New()

    bExec:={|cEmp,cFil|NJobPonRun(@cEmp,@cFil)}

    aEval(aFiliais,{|cFil|;
        oSchedule:PutInternal(Eval(bMsgOut,cInternal,cEmp,cFil)),;
        ConOut("","Inicio :: "+Eval(bMsgOut,cInternal,cEmp,cFil)+" :: "+DtoC(Date())+" :: "+Time(),""),;
        oSchedule:Scheduler({cEmp,cFil,bExec,.F.}),;
        ConOut("","Final  :: "+Eval(bMsgOut,cInternal,cEmp,cFil)+" :: "+DtoC(Date())+" :: "+Time(),"");
      };
    )

    return

static procedure NJobPonRun(cEmp,cFil)

    local dDate         as date

    local lPONSCHEDULER as logical

    local lWork         as logical
    local lUserDef      as logical
    local lLimita       as logical
    local cProcFil      as character
    local lProcFil      as logical
    local lApoNLidas    as logical
    local lForceR       as logical
    local xAutoCab
    local xAutoItens
    local nOpcAuto      as numeric
    local cProcessa     as character
    local cTipoRel      as character
    local dDtIni        as date
    local dDtFim        as date

    cProcFil:=cFil

    lWork:=.T.
    lUserDef:=.T.
    lLimita:=.T.
    lProcFil:=.T.
    lApoNLidas:=.F.
    lForceR:=.T.
    cProcessa:="3"
    cTipoRel:="2"

    #ifdef PONSCHEDULER
        lPONSCHEDULER:=.T.
    #else
        lPONSCHEDULER:=.F.
    #endif

    GetPonMesDat(@dDtIni,@dDtFim,cFil)

    dDate:=Date()
    dDtFim:=Max(dDtFim,dDate)

    PNM010Chg(cFil,dDtIni,dDtFim)

    if (lPONSCHEDULER)
        cFunction:="U_PONSCHEDULER"
        &cFunction.({cEmp,cProcFil,lUserDef,lLimita,lProcFil,lApoNLidas,lForceR,lProcFil,cProcessa,cTipoRel,dDtIni,dDtFim})
    else
        cFunction:="PONM010"
        &cFunction.(@lWork,@lUserDef,@lLimita,@cProcFil,@lProcFil,@lApoNLidas,@lForceR,@xAutoCab,@xAutoItens,@nOpcAuto,@cProcessa,@cTipoRel,@dDtIni,@dDtFim)
    endif

    chkMarkDupl()

    return

static procedure PNM010Chg(cFil as character,dDtIni as date,dDtFim as date)

    local aArea as array

    local cOrd  as character
    local cPerg as character
    local cSeek as character

    local nD    as numeric
    local nJ    as numeric

    aArea:=getArea()
    SX1->(dbSetOrder(1))

    cPerg:=PadR("PNM010",len(SX1->X1_GRUPO))

    nJ:=22
    for nD:=1 to nJ
        cOrd:=StrZero(nD,2)
        cSeek:=cPerg
        cSeek+=cSeek
        if SX1->(dbSeek(cSeek,.F.))
            if SX1->(recLock("SX1",.F.))
                do case
                case (cOrd$"|01|02|")
                       SX1->X1_CNT01:=cFil
                case (cOrd$"|03|05|07|09|11|15")
                    SX1->X1_CNT01:=""
                case (cOrd$"|04|06|08|10|12|16")
                    SX1->X1_CNT01:="z"
                case (cOrd$"|13|")
                    SX1->X1_CNT01:=DToS(dDtIni)
                case (cOrd$"|14|")
                    SX1->X1_CNT01:=DToS(dDtFim)
                case (cOrd$"|17|")
                    SX1->X1_PRESEL:=3
                case (cOrd$"|18|")
                    SX1->X1_PRESEL:=1
                case (cOrd$"|19|")
                    SX1->X1_PRESEL:=1
                case (cOrd$"|20|")
                    SX1->X1_PRESEL:=1
                case (cOrd$"|21|")
                    SX1->X1_CNT01:="M**************"
                case (cOrd$"|22|")
                    SX1->X1_CNT01:=" A*F*"
                endcase
                SX1->(MsUnLock())
            endif
        endif
    next nD
    restArea(aArea)
    return

static procedure chkMarkDupl()

    local aArea     as array

    local cAlias    as character
    local cQuery    as character
    local cTable    as character

    local nDupl     as numeric

    aArea:=getArea()

    cAlias:=getNextAlias()
    beginSQL alias cAlias
        SELECT SUM(t.DUPL) AS DUPL
          FROM (
            SELECT SP8.P8_FILIAL
                  ,SP8.P8_MAT
                  ,SP8.P8_DATA
                  ,SP8.P8_HORA
                  ,COUNT(*) AS DUPL
             FROM %table:SP8% SP8
            WHERE SP8.%notDel%
            GROUP BY SP8.P8_FILIAL
                    ,SP8.P8_MAT
                    ,SP8.P8_DATA
                    ,SP8.P8_HORA
            HAVING COUNT(*)>1
          ) t
    endSQL

    nDupl:=(cAlias)->DUPL
    (cAlias)->(dbCloseArea())
    dbSelectArea("SP8")

    if (nDupl>0)
        cTable:=retSQLName("SP8")
        cQuery:="DELETE FROM"
        cQuery+="   "+cTable+" SP8_A"
        cQuery+="WHERE"
        cQuery+="  SP8_A.R_E_C_N_O_ >"
        cQuery+="   ANY ("
        cQuery+="     SELECT"
        cQuery+="        MIN(SP8_B.R_E_C_N_O_)"
        cQuery+="     FROM "
        cQuery+="        "+cTable+" SP8_B"
        cQuery+="     WHERE"
        cQuery+="        SP8_A.P8_FILIAL=SP8_B.P8_FILIAL"
        cQuery+="     AND"
        cQuery+="        SP8_A.P8_MAT=SP8_B.P8_MAT"
        cQuery+="     AND"
        cQuery+="        SP8_A.P8_DATA=SP8_B.P8_DATA"
        cQuery+="     AND"
        cQuery+="        SP8_A.P8_HORA=SP8_B.P8_HORA"
        cQuery+="    )"
        TCSQLExec(cQuery)
    endif

    restArea(aArea)

    return

procedure u_PNM010INI()
    local lChange    as logical
    lChange:=IsInCallStack("NJOBPONRUN")
    lChange:=(lChange.or.IsInCallStack("U_PONSCHEDULER"))
    if (lChange)
        if (type("lWorkFlow")=="L")
            &("lWorkFlow"):=.T.
        endif
        if (type("lSchedDef")=="L")
            &("lSchedDef"):=.F.
        endif
    endif
    return
