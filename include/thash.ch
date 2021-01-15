#IFNDEF _THASH_CH

    #DEFINE _THASH_CH

    /*/
        Arquivo:thash.ch
        Autor:Marinaldo de Jesus
        Data:04/12/2011
        Descricao:Arquivo de Cabecalho utilizado na Classe THASH e derivadas
        Sintaxe:#include "thash.ch"
    /*/

    #DEFINE HASH_SECTION_POSITION  1
    #DEFINE HASH_PROPERTY_POSITION 2

    #DEFINE HASH_PROPERTY_KEY      1
    #DEFINE HASH_PROPERTY_VALUE    2
    #DEFINE HASH_PROPERTY_FILE     3
    #DEFINE HASH_PROPERTY_TYPE     4
    #DEFINE HASH_PROPERTY_CLSNAME  5
    
    #DEFINE HASH_PROPERTY_ELEMENTS 5

    #DEFINE SECTION_POSITION       HASH_SECTION_POSITION
    #DEFINE PROPERTY_POSITION      HASH_PROPERTY_POSITION

    #DEFINE PROPERTY_KEY           HASH_PROPERTY_KEY
    #DEFINE PROPERTY_VALUE         HASH_PROPERTY_VALUE
    #DEFINE PROPERTY_FILE          HASH_PROPERTY_FILE
    #DEFINE PROPERTY_TYPE          HASH_PROPERTY_TYPE
    #DEFINE PROPERTY_CLSNAME       HASH_PROPERTY_CLSNAME
    
    #DEFINE PROPERTY_ELEMENTS      HASH_PROPERTY_ELEMENTS

    #DEFINE HASH_KEY_POS        1
    #DEFINE HASH_KEY_INDEX      2
    #DEFINE HASH_KEY_ELEMENTS   2

    #DEFINE HASH_KEY_SIZE       6

	#ifndef __NToS
		#define __NToS
		#xtranslate NToS([<n,...>])=>LTrim(Str([<n>]))
	#endif

    #ifndef __CLS_NAME_THASH
        #define __CLS_NAME_THASH
        #define CLS_NAME_THASH "|JSONHASH|JSONARRAY|THASH|TFINI|THASH_TFINI|"
    #endif

#ENDIF