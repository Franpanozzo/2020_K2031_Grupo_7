%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#define YYDEBUG 1

extern int lineno;
extern FILE * yyin;

//NODOS

typedef struct tNodoParametro
{
	char* tipo;
	struct tNodoParametro* sgte;
} tNodoParametro;

typedef tNodoParametro* tColaParametro;

typedef struct tNodoTablaDeSimb
{	
	char* tipo;
	char* identificador;
	int validar;
	tColaParametro principioParametros;
	tColaParametro finalParametros;
	struct tNodoTablaDeSimb* sgte;
} tNodoTablaDeSimb;
tNodoTablaDeSimb* inicializarNodo();
void inicializarNodoConTipo(char* tipo,tNodoTablaDeSimb** nodo);
tNodoTablaDeSimb* encontrarEnTablaDeSimb(char*);
void compararConParametro(char* tipoParametroEncontrado, tColaParametro* indice);
void encolarParametro(char* tipoParametro, char* identificador, tColaParametro* colaParametroInicio, tColaParametro* colaParametroFinal);
void agregarATS(tNodoTablaDeSimb** nodo);
void imprimirListaVariables();
void imprimirListaParametros(tNodoParametro** principio, tNodoParametro** final);

tNodoTablaDeSimb* tablaDeSimb = NULL;
tNodoTablaDeSimb* nodo;
tNodoTablaDeSimb* nodo2;
tNodoTablaDeSimb* nodoActual;
tNodoTablaDeSimb* nodoActual2;
tColaParametro indice;
void validarExistenciaYTipo(int a,tNodoTablaDeSimb* nodoActual, char* identificador);
int flag_error=0;
int contador=0;

int yylex();
int yywrap(){
	return(1);
}

void yyerror (char const *s);

%}

%union {
	 char* cadena;
}

%token <cadena> CCHAR
%token <cadena> NUM
%token <cadena> LITERALCADENA
%token <cadecna> ID
%token <cadena> TIPO_DATO
%token <cadena> REAL
%token <cadena> TOKEN_VOID
%token <cadena> error
%token FOR
%token IF
%token WHILE
%token DO
%token CASE
%token DEFAULT
%token SWITCH
%token ELSE
%token RETURN
%token BREAK
%token CONTINUE

%type <cadena> expresion
%type <cadena> numero
%type <cadena> constante
%type <cadena> declaraId

%left OP_INCREMENTO OP_DECREMENTO
%left '+' '-'
%left '*' '/'
%left '^'
%left '<' '>' MENORIGUAL MAYORIGUAL
%left IGUALIGUAL NOIGUAL
%left YLOGICO
%left OLOGICO
%right '=' MASIGUAL MENOSIGUAL PORIGUAL DIVIDIDOIGUAL
%left ','


%start input

%% /* A continuacion las reglas gramaticales y las acciones */

// Cambiar el axioma por una lista de sentencias
input:    /* vacio */
        | sentencia input
		|  error puntoYComaOBarraN input
;

numero: NUM {$<cadena>$ = strdup($<cadena>1);}
		| REAL {$<cadena>$ = strdup($<cadena>1);}
;

sentencia:  sentenciaDeclaracion
			| sentenciaCompuesta
			| sentenciaExpresion
			| sentenciaIteracion
			| sentenciaEtiquetada
			| sentenciaSeleccion
			| sentenciaRetorno
			| sentenciaSalto
			| /* vacio */  ';'
;


puntoYComaOBarraN: ';'
			     | '\n'

sentenciaSalto: BREAK ';'
				| CONTINUE ';'
;

sentenciaDeclaracion: TIPO_DATO {inicializarNodoConTipo($<cadena>1, &nodo);} parteFinalDeclaracion 
					  | TOKEN_VOID {inicializarNodoConTipo($<cadena>1, &nodo);} sentenciaFuncion
					  | error
;

sentenciaSeleccion: IF '(' expresion ')' sentencia {}
					| IF '(' expresion ')' sentencia ELSE sentencia {}
					| SWITCH '(' expresion ')' sentencia {}
					| error 
;

sentenciaEtiquetada: CASE constante ':' sentencia 
					| DEFAULT ':' sentencia
					| error
;

sentenciaRetorno: RETURN expresion ';'
;

constante: numero {$<cadena>$ = strdup($<cadena>1);}
		   | CCHAR	{$<cadena>$ = strdup($<cadena>1);}
;

sentenciaIteracion: FOR '(' primeraExpresionFor ';' expresionOpcional ';' expresionOpcional ')' sentencia {}
					| WHILE '(' expresion ')' sentencia {}
					| DO sentencia WHILE '(' expresion ')'';' {}
					| error
;


primeraExpresionFor: expresion 
					 | TIPO_DATO ID {nodo-> validar = 0;nodo->identificador = strdup($<cadena>2); agregarATS(&nodo);} '=' expresion 
					 | /*vacio*/
;

expresionOpcional: expresion | /*vacio*/
;

parteFinalDeclaracion: declaraId ';'
				| declaraId ',' {inicializarNodoConTipo(nodo->tipo, &nodo);} listaIdentificadores
				| sentenciaFuncion
				| error
;

sentenciaFuncion: ID {inicializarNodoConTipo(nodo->tipo, &nodo2);nodo2->validar = 1; nodo2->identificador = strdup($<cadena>1);} '(' listaDeParametros ')' declaracionODefFuncion {agregarATS(&nodo2);}
				  | error
;

declaracionODefFuncion:  ';'
						| sentenciaCompuesta
						| error
;

listaIdentificadores: declaraId ',' {inicializarNodoConTipo(nodo->tipo, &nodo);} listaIdentificadores
                    | declaraId ';'
					| error
;

listaDeParametros: /* vacio */ 
					|TIPO_DATO ID {encolarParametro($<cadena>1, $<cadena>2, &(nodo2->principioParametros), &(nodo2->finalParametros));} ',' listaDeParametros 
					| TIPO_DATO ID {encolarParametro($<cadena>1, $<cadena>2, &(nodo2->principioParametros), &(nodo2->finalParametros));}
					| error
;

sentenciaCompuesta: '{'listaDeSentencias'}'
					| error
;

listaDeSentencias: sentencia listaDeSentencias
					| sentencia
					| /*vacio*/
					| error
;

opAsignacion:	MENOSIGUAL
			   | MASIGUAL
			   | PORIGUAL
			   | DIVIDIDOIGUAL
;

sentenciaExpresion: listaDeExpresiones';'
					| error
;

invocacionFuncion: ID {nodoActual = encontrarEnTablaDeSimb($<cadena>1); validarExistenciaYTipo(1,nodoActual,$<cadena>1);} segundaParteInvocacion
				   | error
;

segundaParteInvocacion: {if(nodoActual) indice = nodoActual->principioParametros;} '(' conOSinParametros ')'

conOSinParametros: listaDeExpresionesInvocacion
				   | /* blank */

//int sumar(int a, int b){}; sumar(2,3);

expresionDeAsignacion: ID opAsignacionGeneral listaDeExpresiones {}
						| error
;

opAsignacionGeneral: '='
    				| opAsignacion
;

declaraId: 	ID {nodo->identificador = strdup($<cadena>1);agregarATS(&nodo);}
			| ID '=' expresion {nodo->identificador = strdup($<cadena>1);agregarATS(&nodo);}
			| error
;

listaDeExpresionesInvocacion: expresion {if(nodoActual && indice){if(indice->sgte == NULL) compararConParametro($<cadena>1, &indice); else{printf ("(Linea %i) Error de parametros - La invocacion no cumple con la cantidad de parametros de %s\n", lineno, nodoActual->identificador);indice = NULL;}}}
			 	    | expresion {if(nodoActual && indice){if(indice->sgte != NULL) compararConParametro($<cadena>1, &indice); else{printf("(Linea %i) Error de parametros - La invocacion no cumple con la cantidad de parametros de %s\n", lineno, nodoActual->identificador);indice = NULL;}}} ',' listaDeExpresionesInvocacion
					| error 
;

listaDeExpresiones: expresion
			 	    | expresion ',' listaDeExpresiones
					| error 
;

expresion:	 constante {$<cadena>$ = strdup($<cadena>1);}
			| LITERALCADENA {$<cadena>$ = strdup($<cadena>1);}
			| ID {nodoActual2 = encontrarEnTablaDeSimb($<cadena>1); validarExistenciaYTipo(0,nodoActual2, $<cadena>1); if(nodoActual2 && nodoActual2->validar == 0) $<cadena>$ = nodoActual2->tipo; else  $<cadena>$ = "nodeclarada"}
			| expresionDeAsignacion
			| expresion '+' expresion	{
											if(strcmp($<cadena>1, "nodeclarada") != 0 && strcmp($<cadena>3, "nodeclarada") != 0)
											{
												if(strcmp($<cadena>1, $<cadena>3)){
													printf("(Linea %i) Error de tipos - no se puede hacer la suma entre %s y %s\n", lineno, $<cadena>1, $<cadena>3);
												}
												else
												{
													strcpy($<cadena>$, $<cadena>1);
												}
											}
										}
			| expresion '-' expresion	
			| expresion '*' expresion
			| expresion '/' expresion	
			| expresionUnaria
			| expresion '^' expresion
			| '(' expresion ')'
			| opPreDecremento
			| opPreIncremento
			| opPostDecremento
			| opPostIncremento 
			| expresion YLOGICO expresion
			| expresion OLOGICO expresion
			| expresion '<' expresion
			| expresion '>' expresion
			| expresion MENORIGUAL expresion
			| expresion MAYORIGUAL expresion
			| expresion IGUALIGUAL expresion
			| expresion NOIGUAL expresion
			| invocacionFuncion
			| error 
;

opPostDecremento: expresion OP_DECREMENTO
;
opPreDecremento: OP_DECREMENTO ID
;
opPostIncremento: ID OP_INCREMENTO
;
opPreIncremento: OP_INCREMENTO ID
;
expresionUnaria: '-' expresion
;

%%

void validarExistenciaYTipo(int a,tNodoTablaDeSimb* nodoActual, char* identificador){
	if(nodoActual){
		if(a != nodoActual->validar){
			printf("(Linea %i) Error - El identificador %s no corresponde con su uso %i\n",lineno, identificador, nodoActual->validar); //que rompa y no siga analizando
		}
	}
	else if(a)
	{
		printf("(Linea %i) Error - No se encuentra la funcion declarada con el indentificador %s\n", lineno, identificador);
	}
	else printf("(Linea %i) Error - No existe una variable declarada con ese identificador %s\n",lineno, identificador);
}

tNodoTablaDeSimb* encontrarEnTablaDeSimb(char* identificador)
{
	//printf("SE INICIA LA BUSQUEDA DE %s\n", identificador);
	tNodoTablaDeSimb* pAct = tablaDeSimb;

	while(pAct && strcmp(pAct->identificador, identificador))
	{
		//printf("Leyendo TS: %s\n", pAct->identificador);
		pAct = pAct->sgte;
	}
	return pAct;
}

void encolarParametro(char* tipoParametro, char* identificador, tColaParametro* colaParametroInicio, tColaParametro* colaParametroFinal)
{
	tColaParametro p = (tColaParametro) malloc(sizeof(tNodoParametro));
	p->tipo = strdup(tipoParametro);
	p->sgte = NULL;

	tNodoTablaDeSimb* nodo = (tNodoTablaDeSimb*) malloc(sizeof(tNodoTablaDeSimb));
	nodo->identificador = strdup(identificador);
	inicializarNodoConTipo(p->tipo, &nodo);
	agregarATS(&nodo);

	if(*colaParametroInicio == NULL){
		*colaParametroInicio = p;
		*colaParametroFinal = p;
	}
	else {
		(*colaParametroFinal)->sgte = p;
		*colaParametroFinal = p;
	}
	//printf("Se encolo el parametro %s\n",(*colaParametroFinal)->tipo);
}

void compararConParametro(char* tipoParametroEncontrado, tColaParametro* indice)
{
	if(tipoParametroEncontrado)
	{
		if(strcmp((*indice)->tipo, tipoParametroEncontrado)){
			//printf("TS: %s - PARAMETRO LEIDO: %s\n", (*indice)->tipo, tipoParametroEncontrado);
			printf("(Linea %i) Error de parametros - La invocacion no corresponde con los tipos de parametros que hay en la declaracion de la funcion\n", lineno);
		}
	}
	*indice = (*indice)->sgte;	
}


void agregarATS(tNodoTablaDeSimb** nodo)
{
	//printf("Se va a agregar un identificador a la tabla en la linea %i", lineno);
	//printf(" - Indentificador : %s\n", (*nodo)->identificador);
	tNodoTablaDeSimb* nodoCopia = (tNodoTablaDeSimb*) malloc(sizeof(tNodoTablaDeSimb));
	//printf("Se va a hacer la copia\n");
	(*nodoCopia) = (**nodo); 
	//printf("Copiado exitosamente\n");

	if(encontrarEnTablaDeSimb(nodoCopia->identificador))
	{
		printf("(Linea %i) Error de doble declaracion - El identificador %s ya fue declarado anteriormente\n", lineno, nodoCopia->identificador);
		//llamar a yyerror();
		free(nodo);
		return;
	}
	//printf("AGREGANDO---\n");
	nodoCopia->sgte = tablaDeSimb;
	tablaDeSimb = nodoCopia;
	//printf("Se agrego a la tabla: %s\n", nodoCopia->identificador)// TP FINALIZADO
}


void imprimirListaVariables()
{
	printf("\n---------------------------\n");
	printf("IDENTIFICADOR	TIPO");
	printf("\n---------------------------\n");
	
	tNodoTablaDeSimb* pActivo = tablaDeSimb;
	while(pActivo)
	{
		if(pActivo->validar == 0)
		{
			printf(pActivo->identificador);
			printf("	");
			printf(strcat(pActivo->tipo,"\n"));
		}
		
		pActivo = pActivo -> sgte;
	}
}

void imprimirListaFunciones()
{
	printf("\n-------------------------------------------\n");
	printf("IDENTIFICADOR	RETORNO	  PARAMETROS");
	printf("\n-------------------------------------------\n");
	
	tNodoTablaDeSimb* pActivo = tablaDeSimb;
	while(pActivo)
	{
		if(pActivo->validar == 1)
		{
			printf(pActivo->identificador);
			printf("	");
			printf(pActivo->tipo);
			printf("	");
			imprimirListaParametros(&(pActivo->principioParametros), &(pActivo->finalParametros));
			printf("\n");
		}
		pActivo = pActivo -> sgte;
	}
}

void imprimirListaParametros(tNodoParametro** principio, tNodoParametro** final)
{
	tNodoParametro* pAct = *principio;
	while(pAct){
		printf(pAct->tipo);
		*principio = (*principio)->sgte;

		if((*principio) == NULL)
			*final = NULL;
		else
			printf(", ");

		free(pAct);
		pAct = *principio;
	}
}

void inicializarNodoConTipo(char* tipo, tNodoTablaDeSimb** nodo)
{
	(*nodo)->principioParametros = NULL;
	(*nodo)->finalParametros = NULL;
	(*nodo)->validar = 0;
	(*nodo)->sgte = NULL;
	(*nodo)->tipo = strdup(tipo);
	free(nodo);
}

void yyerror (char const *s)
{
  fprintf(stderr, "(Linea %i) Error Sintactico\n", lineno);
}

int main ()
{
#ifdef BISON_DEBUG
        yydebug = 1;
# endif
  nodo = (tNodoTablaDeSimb*) malloc(sizeof(tNodoTablaDeSimb));
  nodo2 = (tNodoTablaDeSimb*) malloc(sizeof(tNodoTablaDeSimb));
  yyin=fopen("entrada.txt","r");
  yyparse ();

  imprimirListaVariables();
  imprimirListaFunciones();
}
