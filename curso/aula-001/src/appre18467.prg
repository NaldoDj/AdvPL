#include "totvs.ch"
//#include "defines.ch"

#xtranslate MinVal(<x>,<y>) => if(<x>\<<y>,<x>,<y>);
#xtranslate MaxVal(<x>,<y>) => if(<x>\><y>,<x>,<y>);

#ifndef __DEFINES_CH__

    #define __DEFINES_CH__

    #define DEF_NOME 1
    #define DEF_SORENOME 2 
    #define DEF_SEXO 3
    #define DEF_IDADE 4

    #define DEF_SIZE 4

#endif

user function vaiDarErro() 
return


procedure u_tDefine1

    /*
        Notação Humgara Modificada

        aArray
        bBlock
        cCharacter
        dDate
        lLogical
        nNumeric

    */
    local aArray as  array

    local nD	as numeric
    local nJ	as numeric

    DEFAULT nD:=1,nJ:=2

    aArray:=array(0)
    
    aAdd(aArray,Array(DEF_SIZE))
    nD:=Len(aArray)
    aArray[nD][DEF_NOME]:="Escrevo o Nome Aqui"
    aArray[nD][DEF_SORENOME]:="Escrevo o Sobre Nome Aqui"
    aArray[nD][DEF_SEXO]:="Escrevo o Sexi Aqui"
    aArray[nD][DEF_IDADE]:="Escrevo a Idade Aqui"

    nJ:=len(aArray) 
    for nD:=1 to nJ
        conOut(aArray[nD][DEF_NOME])
        conOut(aArray[nD][DEF_SORENOME])
        conOut(aArray[nD][DEF_SEXO])
        conOut(aArray[nD][DEF_IDADE])
    next nD

    aAdd(aArray,Array(4))
    nD:=Len(aArray)
    ConOut(aArray[nD][1]:="Escrevo o Nome Aqui")
    ConOut(aArray[nD][2]:="Escrevo o Sobre Nome Aqui")
    ConOut(aArray[nD][3]:="Escrevo o Sexi Aqui")
    ConOut(aArray[nD][4]:="Escrevo a Idade Aqui")

    nJ:=len(aArray) 
    for nD:=1 to nJ
        ConOut(aArray[nD][1])
        ConOut(aArray[nD][2])
        ConOut(aArray[nD][3])
        ConOut(aArray[nD][4])
    next nD

    MsgInfo(MinVal(1,2))
    MsgInfo(MaxVal(1,2))

    return
