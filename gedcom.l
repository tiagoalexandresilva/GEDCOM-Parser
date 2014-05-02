%{
#include "estruturas.h"
#include <sys/wait.h>
#include <unistd.h>
#define max(x,y)    (((x) > (y)) ? (x) : (y))

Individuo ind = NULL;
AVL linds = NULL;
LAgregados lagregados = NULL;
Agregado agr = NULL;

%}
%option noyywrap
%x INDIVIDUO NASCIMENTO MORTE AGREGADO CASAMENTO
%%
<*>0[ ]@I[0-9]+/@[ ]INDI				{ adicionarAVL(&linds, atoi(yytext+4));
										ind = encontraIndividuo(linds, atoi(yytext+4));
										BEGIN INDIVIDUO; }
<INDIVIDUO>1[ ]NAME[ ][^\n]+			{ remchar((yytext+7), '/');
										ind->nome = strdup(yytext+7); }
<INDIVIDUO>1[ ]SEX[ ][^\n]+				ind->sexo = strdup(yytext+6);
<INDIVIDUO>1[ ]BIRT						BEGIN NASCIMENTO;
<INDIVIDUO>1[ ]DEAT						BEGIN MORTE;
<INDIVIDUO>1[ ]OCCU[ ][^\n]+			ind->profissao = strdup(yytext+7);
<NASCIMENTO>2[ ]DATE[ ][^\n]+			ind->datanasc = strdup(yytext+7);
<NASCIMENTO>2[ ]PLAC[ ][^\n]+			{ ind->lugarnasc = strdup(yytext+7);
										BEGIN INDIVIDUO; }		
<MORTE>2[ ]DATE[ ][^\n]+				ind->datafalc = strdup(yytext+7);
<MORTE>2[ ]PLAC[ ][^\n]+				{ ind->lugarfalc = strdup(yytext+7);
										BEGIN INDIVIDUO; }
<INDIVIDUO>1[ ]FAMS[ ]@F[0-9]+/@	    ind->idfamconj = atoi(yytext+9);
<INDIVIDUO>1[ ]FAMC[ ]@F[0-9]+/@		ind->idfamfil = atoi(yytext+9);
<*>0[ ]@F[0-9]+/@[ ]FAM					{ agr = (Agregado)malloc(sizeof(NodoAgr)); 
										agr->idagregado = atoi(yytext+4);
										agr->listaF = inicializaLFilhos();
										insereAgregadoNaLista(agr);
										BEGIN AGREGADO; }
<AGREGADO>1[ ]HUSB[ ]@I[0-9]+/@			agr->idmar = atoi(yytext+9);
<AGREGADO>1[ ]WIFE[ ]@I[0-9]+/@			agr->idmul = atoi(yytext+9);
<AGREGADO>1[ ]CHIL[ ]@I[0-9]+/@			inserirFilho(agr->listaF, atoi(yytext+9));
<AGREGADO>1[ ]MARR						BEGIN CASAMENTO;
<CASAMENTO>2[ ]DATE[ ][^\n]+			agr->datacasm = strdup(yytext+7);
<CASAMENTO>2[ ]PLAC[ ][^\n]+			{ agr->lugarcasm = strdup(yytext+7);
										BEGIN AGREGADO; }
										
<*>.|\n									;				
%%


int main(int argc, char *argv[])
{
	system("cp /usr/local/share/ged2html/styles.css .");
	system("cp /usr/local/share/ged2html/paper005.gif .");
	
	if(argc==1){
		yyin=stdin;
		yylex();
	}
	else{
		yyin=fopen(argv[1], "r");
		yylex();
		criaHtmlIndex();
		apagarAVL(linds);
		apagarListaAgregados(lagregados);
		fclose(yyin);
	}
    
    return 0;
}

void criaHtmlIndex()
{
	FILE* index = fopen("Index.html","w");
	
	if(index)
	{
		fprintf(index,"<html><head><title>GEDCOM Index</title><link href='http://fonts.googleapis.com/css?family=Open+Sans+Condensed:300,700' rel='stylesheet' type='text/css'><link href='http://fonts.googleapis.com/css?family=Open+Sans:300italic,400italic,400,700,600,300' rel='stylesheet' type='text/css'><link href=\"styles.css\" rel=\"stylesheet\" type=\"text/css\" media=\"screen\"><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"></head><body>");
		fprintf(index,"<div id=\"wrapper\">");
		fprintf(index,"<br><h1>GEDCOM Index</h1><hr>");
		fprintf(index,"<br><h2>Indíviduos</h2>\n");
		fprintf(index,"<ul>\n");
		criaHtmlIndividuos(linds,index);
		fprintf(index,"</ul>\n");
		fprintf(index,"<br><h2>Agregados</h2>\n");
		fprintf(index,"<ul>\n");
		criaHtmlAgregados(index);
		fprintf(index,"</ul>\n");
		fprintf(index,"</div>\n");
		fprintf(index,"</body></html>\n");
		fclose(index);		
	}
	else{ printf("Erro ao criar html de Index!\n"); }
}

void criaHtmlAgregados(FILE* index)
{
	FILE* file;
	char nomehtml[1024];
	char* apelidomar;
	LAgregados aux = lagregados;

	while(aux)
	{
		sprintf(nomehtml, "Agregado %d.html", aux->agregado->idagregado);
		file = fopen(nomehtml,"w");
		if(file)
		{
			apelidomar = filtraApelido(encontraNomeIndividuo(aux->agregado->idmar));
			fprintf(file,"<html><head><title>Agregado %s</title><link href='http://fonts.googleapis.com/css?family=Open+Sans+Condensed:300,700' rel='stylesheet' type='text/css'><link href='http://fonts.googleapis.com/css?family=Open+Sans:300italic,400italic,400,700,600,300' rel='stylesheet' type='text/css'><link href=\"styles.css\" rel=\"stylesheet\" type=\"text/css\" media=\"screen\"><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"></head><body>",apelidomar);
			fprintf(file,"<div id=\"wrapper\">");
			fprintf(index,"<li><a href=\"Agregado %d.html\" target=\"_blank\">(%d) Agregado %s</a></li>",aux->agregado->idagregado,aux->agregado->idagregado,apelidomar);
			fprintf(file,"<br><h1>Agregado %s</h1><hr>",apelidomar);
			if(aux->agregado->idmar){fprintf(file,"<br><b>Marido: </b><a href=\"Individuo %d.html\" target=\"_blank\">%s</a><br>",aux->agregado->idmar,encontraNomeIndividuo(aux->agregado->idmar));}
			if(aux->agregado->idmul){fprintf(file,"<br><b>Mulher: </b><a href=\"Individuo %d.html\" target=\"_blank\">%s</a><br>",aux->agregado->idmul,encontraNomeIndividuo(aux->agregado->idmul));}
			escreveFilhos(file,aux->agregado->listaF);
			if(aux->agregado->datacasm || aux->agregado->lugarcasm)
			{
				fprintf(file,"<br><b>Casamento:</b>");
				if(aux->agregado->datacasm){fprintf(file,"<ul><li>Data: %s</li></ul>",aux->agregado->datacasm);}
				if(aux->agregado->lugarcasm){fprintf(file,"<ul><li>Local: %s</li></ul>",aux->agregado->lugarcasm);}
			}
			fprintf(file,"</div>\n");
			fprintf(file,"</body></html>\n");
			fclose(file);
		}else{ printf("Erro ao criar html do Agregado %d!\n",aux->agregado->idagregado); }
		
		aux = aux->seg;
	}
}


void escreveFilhos(FILE * file, LFilhos lf)
{
	LFilhos aux = lf->seg;

	if(lf->seg){fprintf(file,"<br><b>Filho(s):</b>");}
	while(aux!= NULL){
		fprintf(file,"<ul><li><a href=\"Individuo %d.html\" target=\"_blank\">%s</a></li></ul>",aux->idfilho,encontraNomeIndividuo(aux->idfilho));
		aux=aux->seg;
		
	}
}

//remove todas as ocurrencias de um certo char
void remchar(char *str, char chr)
{
	char *src, *dest;

	src = dest = str;
	while(*src != '\0')
	{
		if (*src != chr)
		{
			*dest = *src; 
			dest++;   
		}
		src++;
	}
	*dest = '\0'; 
}

void insereAgregadoNaLista(Agregado agr){
	LAgregados new = (LAgregados)malloc(sizeof(NodoLAgr));
	new->agregado = agr;
	new->seg = NULL;
	
	if(lagregados == NULL){
        lagregados = new;
    }else{
        LAgregados aux = lagregados;
        while(aux->seg != NULL){
            aux = aux->seg;
        }
        aux->seg = new;
    }
}

char* concat(char *s1, char *s2)
{
    char *result = (char*)malloc(strlen(s1)+strlen(s2)+1);
    strcpy(result, s1);
    strcat(result, s2);
    return result;
}

LFilhos inicializaLFilhos(){

	LFilhos novo;
	novo = (LFilhos)malloc(sizeof(NodoLF));
	novo->seg = NULL;
	return novo;
}

void inserirFilho(LFilhos lf, int idf){
	LFilhos new = (LFilhos)malloc(sizeof(NodoLF));
	new->idfilho = idf;
	new->seg = NULL;

	if(lf == NULL){
        lf = new;
    }else{
        LFilhos aux = lf;
        while(aux->seg != NULL){
            aux = aux->seg;
        }
        aux->seg = new;
    }
}

AVL rotacaoLL(AVL pai)
{ 
    AVL filho = pai->esq; 
    pai->esq = filho->dir; 
    filho->dir = pai; 
    return filho; 
} 


AVL rotacaoRR(AVL pai) 
{ 
    AVL filho = pai->dir; 
    pai->dir = filho->esq; 
    filho->esq = pai; 
    return filho; 
} 


AVL rotacaoRL(AVL pai) 
{ 
    AVL filho = pai->dir; 
    pai->dir = rotacaoLL(filho); 
    return rotacaoRR(pai); 
} 


AVL rotacaoLR(AVL pai) 
{ 
    AVL filho = pai->esq; 
    pai->esq = rotacaoRR(filho); 
    return rotacaoLL(pai);
} 

int alturaAVL(AVL nodo)
{ 
    int altura=0; 
    if(nodo != NULL) 
        altura = 1+max(alturaAVL(nodo->esq),alturaAVL(nodo->dir)); 
    return altura;
} 

 
int factorbalanceamento(AVL nodo)
{ 
    if(nodo == NULL) return 0; 
    return alturaAVL(nodo->esq) - alturaAVL(nodo->dir); 
} 

 
AVL balancearAVL(AVL *nodo)
{ 
    int dif_altura = factorbalanceamento(*nodo); 
     
    if(dif_altura > 1) 
	{ 
        if(factorbalanceamento((*nodo)->esq) > 0) 
            *nodo = rotacaoLL(*nodo); 
        else  
            *nodo = rotacaoLR(*nodo); 
    } 
    else if(dif_altura < -1)
{ 
        if(factorbalanceamento((*nodo)->dir) < 0) 
            *nodo = rotacaoRR(*nodo); 
        else 
            *nodo = rotacaoRL(*nodo); 
    } 
    return *nodo; 
} 


AVL adicionarAVL(AVL *raiz, int idind)
{
    if(*raiz == NULL) 
    { 
        *raiz = (AVL)malloc(sizeof(NodoAVL));
        (*raiz)->idindividuo = idind;
        (*raiz)->individuo = (Individuo)malloc(sizeof(NodoInd));
        (*raiz)->esq = (*raiz)->dir = NULL;       
    } 
    else if(idind < (*raiz)->idindividuo) 
    { 
        (*raiz)->esq = adicionarAVL(&((*raiz)->esq), idind); 
        (*raiz) = balancearAVL(raiz);  
    } 
    else if(idind > (*raiz)->idindividuo) 
    { 
        (*raiz)->dir = adicionarAVL(&((*raiz)->dir), idind); 
        (*raiz) = balancearAVL(raiz); 
    } 
    return *raiz; 
}

Individuo encontraIndividuo(AVL raiz, int idf)
{ 
	AVL aux = raiz;
	
	while(aux != NULL && aux->idindividuo != idf)
	{
		if(idf < aux->idindividuo)
			aux = aux -> esq;
		else
			aux = aux -> dir;
    }
    if(aux)
		return aux->individuo;
	else
		return NULL;
}

void criaHtmlIndividuos(AVL nodo, FILE* index)
{
	char nomehtml[1024];
	AVL aux = nodo;
	FILE* file;
	
	if(aux == NULL){
		return;
	}
	else{
			
		criaHtmlIndividuos(aux -> esq, index);
		sprintf(nomehtml, "Individuo %d.html", aux->idindividuo);
		file = fopen(nomehtml,"w");
		if(file)
		{
			fprintf(file,"<html><head><title>%s</title><link href='http://fonts.googleapis.com/css?family=Open+Sans+Condensed:300,700' rel='stylesheet' type='text/css'><link href='http://fonts.googleapis.com/css?family=Open+Sans:300italic,400italic,400,700,600,300' rel='stylesheet' type='text/css'><link href=\"styles.css\" rel=\"stylesheet\" type=\"text/css\" media=\"screen\"><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"></head><body>",aux->individuo->nome);
			fprintf(file,"<div id=\"wrapper\">");
			fprintf(index,"<li><a href=\"Individuo %d.html\" target=\"_blank\">%s</a></li>",aux->idindividuo,aux->individuo->nome);
			fprintf(file,"<br><h1>%s</h1><hr>",aux->individuo->nome);
			fprintf(file,"<br><b>ID: </b> %d<br>",aux->idindividuo);
			if(aux->individuo->profissao){fprintf(file,"<br><b>Profissão: </b> %s<br>",aux->individuo->profissao);}
			if(aux->individuo->morada){fprintf(file,"<br><b>Morada: </b> %s<br>",aux->individuo->morada);}
			if(aux->individuo->sexo){if(strstr(aux->individuo->sexo,"M")){fprintf(file,"<br><b>Sexo: </b>Masculino<br>");}else{fprintf(file,"<br><b>Sexo: </b>Feminino<br>");}}
			if(aux->individuo->datanasc || aux->individuo->lugarnasc)
			{
				fprintf(file,"<br><b>Nascimento:</b>");
				if(aux->individuo->datanasc){fprintf(file,"<ul><li>Data: %s</li></ul>\n",aux->individuo->datanasc);}
				if(aux->individuo->lugarnasc){fprintf(file,"<ul><li>Local: %s</li></ul>\n",aux->individuo->lugarnasc);}
			}
			if(aux->individuo->datafalc || aux->individuo->lugarfalc)
			{
				fprintf(file,"<br><b>Morte:</b>");
				if(aux->individuo->datafalc){fprintf(file,"<ul><li>Data: %s</li></ul>\n",aux->individuo->datafalc);}
				if(aux->individuo->lugarfalc){fprintf(file,"<ul><li>Data: %s</li></ul>\n",aux->individuo->lugarfalc);}
			}
			if(aux->individuo->idfamconj){fprintf(file,"<br><b>Agregado onde é cônjuge: </b><a href=\"Agregado %d.html\" target=\"_blank\">%d</a><br>",aux->individuo->idfamconj,aux->individuo->idfamconj);}
			if(aux->individuo->idfamfil){fprintf(file,"<br><b>Agregado onde é filho: </b><a href=\"Agregado %d.html\" target=\"_blank\">%d</a>",aux->individuo->idfamfil,aux->individuo->idfamfil);}
			fprintf(file,"</div>\n");
			fprintf(file,"</body></html>\n");
			fclose(file);
		}else{ printf("Erro ao criar html de Individuo %d!\n",aux->idindividuo); }
		criaHtmlIndividuos(aux -> dir, index);
	}
}

char* encontraNomeIndividuo(int id)
{ 
	AVL aux = linds;
	
	while(aux != NULL && aux->idindividuo != id)
	{
		if(id < aux->idindividuo)
			aux = aux -> esq;
		else
			aux = aux -> dir;
    }
    if(aux)
		return aux->individuo->nome;
	else
		return NULL;
} 

char* filtraApelido(char* nome)
{
	if(nome){
		char *p = strrchr(nome, ' ');
		if (p && *(p + 1)){
			return p + 1;}
		else
			return NULL;
	}else{ return NULL; }
}


void apagarListaFilhos(LFilhos lista)
{
	if(lista){
		apagarListaFilhos(lista->seg);
		free(lista);
	}
}

void apagarListaAgregados(LAgregados lista)
{
	if(lista){
		apagarListaAgregados(lista->seg);
		if(lista->agregado->datacasm){free(lista->agregado->datacasm);}
		if(lista->agregado->lugarcasm){free(lista->agregado->lugarcasm);}
		if(lista->agregado->listaF){apagarListaFilhos(lista->agregado->listaF);}
		free(lista);
	}
}

 
void apagarAVL(AVL raiz)
{
	if(raiz)
	{
		apagarAVL(raiz->esq);
		apagarAVL(raiz->dir);
		if(raiz->individuo->nome){free(raiz->individuo->nome);}
		if(raiz->individuo->sexo){free(raiz->individuo->sexo);}
		if(raiz->individuo->profissao){free(raiz->individuo->profissao);}
		if(raiz->individuo->datanasc){free(raiz->individuo->datanasc);}
		if(raiz->individuo->lugarnasc){free(raiz->individuo->lugarnasc);}
		if(raiz->individuo->datafalc){free(raiz->individuo->datafalc);}
		if(raiz->individuo->lugarfalc){free(raiz->individuo->lugarfalc);}
		free(raiz->individuo);
		free(raiz);
	}
}	
	
