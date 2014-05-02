typedef struct sIndividuo{
	char* nome;
	char* sexo;
	char* profissao;
	char* morada;
	char* datanasc;
	char* lugarnasc;
	char* datafalc;
	char* lugarfalc;
	int idfamfil; //filho dessa familia
	int idfamconj; //conjuge dessa familia
}*Individuo,NodoInd;

typedef struct sAVL{
	int idindividuo;
	Individuo individuo;
	struct sAVL * esq, *dir;
}*AVL, NodoAVL;

typedef struct sLFilhos{
	int idfilho;
	struct sLFilhos* seg;
}*LFilhos, NodoLF;

typedef struct sAgregado{
	int idagregado;
	int idmar;
	int idmul;
	char* datacasm; //data casamento
	char* lugarcasm; // local casamento
	LFilhos listaF;
}*Agregado, NodoAgr;

typedef struct sLAgregados{
	Agregado agregado;
	struct sLAgregados * seg;
}*LAgregados, NodoLAgr;


void insereAgregadoNaLista(Agregado agr);
void remchar(char *strin, char chr);
void criaHtmlAgregados();
char* concat(char *s1, char *s2);
void inserirFilho(LFilhos lf, int idf);
LFilhos inicializaLFilhos();
void escreveFilhos(FILE * file, LFilhos lf);
void criaHtmlAgregados(FILE* index);
Individuo encontraIndividuo(AVL raiz, int idf);
AVL adicionarAVL(AVL *raiz, int idind);
AVL balancearAVL(AVL *nodo);
int factorbalanceamento(AVL nodo);
int alturaAVL(AVL nodo);
AVL rotacaoLR(AVL pai);
AVL rotacaoRL(AVL pai);
AVL rotacaoRR(AVL pai);
AVL rotacaoLL(AVL pai);
void criaHtmlIndividuos(AVL nodo, FILE* index);
char* encontraNomeIndividuo(int id);
char* filtraApelido(char* nome);
void apagarListaFilhos(LFilhos lista);
void apagarAVL(AVL raiz);
void apagarListaAgregados(LAgregados lista);
void criaHtmlIndex();

