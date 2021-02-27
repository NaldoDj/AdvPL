#include "totvs.ch"
#include "parmtype.ch"

procedure u_tPessoaW()

    local oPessoa   as object
    local oHomem    as object

    oPessoa:=tPessoaW():New()
    oHomem:=tHomemW():New()

    return

class tPessoaW 

    private data cNome       as character
    private data cSexo       as character
    private data nQI         as numeric
    private data dNascimento as date

    public method New()         as object
    public method ClassName()   as character

    public method cNome(cNome as character)
    public method cSexo(cSexo as character)
    public method nQI(nQI as numeric)
    public method dNascimento(dNascimento as date)

end class

method New() class tPessoaW
    return(self)

method ClassName() class tPessoaW
    return("tPessoaW")

method cNome(cNome) class tPessoaW
    DEFAULT cNome:=self:cNome
    paramtype cNome as character optional
    self:cNome:=cNome
    return(self:cNome)

method cSexo(cSexo) class tPessoaW
    DEFAULT cSexo:=self:cSexo
    paramtype cSexo as character optional
    self:cSexo:=cSexo
    return(self:cSexo)

method nQI(nQI) class tPessoaW
    DEFAULT nQI:=self:nQI
    paramtype nQI as numeric optional
    self:nQI:=nQI
    return(self:nQI)

method dNascimento(dNascimento) class tPessoaW
    DEFAULT dNascimento:=self:dNascimento
    paramtype dNascimento as date optional
    self:dNascimento:=dNascimento
    return(self:dNascimento)

class tHomemW from tPessoaW
    public method New() as object
    public method ClassName() as character
end class

method New() class tHomemW
    _Super:New()
    return(self)

method ClassName() class tHomemW
    return(_Super:ClassName()+"_"+"tHomemW")
