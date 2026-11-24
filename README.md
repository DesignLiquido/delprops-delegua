# delprops-delegua

<p align="center">
  <img src="./recursos/delprops-logo.png" alt="delprops" width="auto" height="130px">
</p>

Pacote Pacoteca, escrito em Delégua, com a especificação, a análise e a validação do formato de arquivo `.delprops`, o arquivo de propriedades e configuração do ecossistema [Delégua](https://github.com/DesignLiquido/delegua).

É o porte do [delprops](https://github.com/DesignLiquido/delprops) (TypeScript, publicado no npm como `@designliquido/delprops`).

## Instalação

```sh
pacote instalar delprops
```

O pacote fica em `pacotes/node/delprops`. A realização suportada é `node` (`delegua-node`).

## Uso como biblioteca

O ponto de entrada é `fontes/delprops.delegua`:

```delegua
importar tudo como delprops de "delprops"

var conteudo = "liquido.roteador.porta = 8080\nliquido.roteador.cors = 'sim'"

var compreendido = delprops.analisar(conteudo)
// compreendido.propriedades: vetor de PropriedadeCompreendida { chave, valor, linha }
// compreendido.erros: vetor de ErroCompreensao { mensagem, linha }

var resultado = delprops.validar(compreendido.propriedades, delprops.obterEsquemasEmbutidos())
// resultado.avisos / resultado.erros: { chave, linha, mensagem }

escreva(delprops.formatarValidacao(resultado))
```

`validarConteudo(conteudo, esquemas)` faz as duas etapas de uma vez e inclui os erros de compreensão (sintaxe, chaves duplicadas) entre os erros de validação, com chave vazia.

### Esquemas

Um esquema é um dicionário `espaço de nomes → vetor de DefinicaoPropriedade`:

```delegua
var modo = delprops.definicaoPropriedade("modo", "texto", "Modo de execução.", "'rapido'", ["rapido", "lento"])
var esquemas = delprops.obterEsquemasEmbutidos()
var meuProjeto = [modo]
esquemas["meuProjeto"] = meuProjeto
```

Os campos de `DefinicaoPropriedade` são `nome`, `tipoValor` (`"logico"`, `"texto"` ou `"numero"`), `detalhe`, `valorPadrao` (na sintaxe do `.delprops`, ou `nulo`) e `valoresPermitidos` (vetor de textos, ou `nulo`). Em Delégua, `tipo` e `padrao` são palavras reservadas e não podem ser nomes de campo; nos arquivos JSON de esquema, as chaves continuam sendo `tipo` e `padrao`, como no pacote original.

`esquemasDeTexto(conteudo)` lê esquemas de um texto JSON (comentários `//` e `/* */` são aceitos) no formato:

```jsonc
{
    "meuProjeto": [
        { "nome": "modo", "tipo": "texto", "detalhe": "Modo de execução.", "valoresPermitidos": ["rapido", "lento"], "padrao": "'rapido'" }
    ]
}
```

e devolve `{ "esquemas": ..., "erro": "" }`. `mesclarEsquemas(base, adicionais)` acrescenta definições a um esquema existente.

## Esquemas contribuídos por pacotes

Pacotes instalados pela Pacoteca podem contribuir com esquemas para um espaço de nomes. O pacote declara a contribuição no seu `pacoteca.jsonc`:

```jsonc
"delprops": {
    "espacoNomes": "liquido.dados",
    "esquema": "delprops/dados.json"
}
```

ou um vetor de objetos assim. `esquema` é o caminho, relativo à raiz do pacote, de um arquivo JSON (ou JSONC) com um vetor de definições:

```json
[
    { "nome": "tecnologia", "tipo": "texto", "detalhe": "Tecnologia de banco de dados.", "valoresPermitidos": ["duckdb"] }
]
```

No pacote original, o esquema é um módulo JavaScript carregado com `require`. Aqui ele é um arquivo de dados, o que não depende da realização.

### Descoberta e registro

```delegua
importar tudo como arquivos de "arquivos"
importar tudo como delprops de "delprops"

var registro = delprops.criarRegistro()
var diretorioPacotes = arquivos.juntarCaminhos(arquivos.diretorioAtual(), "pacotes")
delprops.descobrir(diretorioPacotes, delprops.sistemaArquivosNode(), registro)

var esquemas = delprops.obterEsquemasEmbutidos()
delprops.mesclarEsquemas(esquemas, registro.obterEsquemas())
```

`descobrir` aceita tanto `pacotes/` quanto `pacotes/<realizacao>`. Um pacote instalado em várias realizações é registrado uma vez. A função devolve a quantidade de contribuições registradas. Manifestos inválidos, esquemas ausentes e definições incompletas são ignorados.

O registro também pode ser preenchido à mão: `registro.registrar(espacoNomes, pacote, definicoes)`. Os outros métodos são `obter(espacoNomes)`, `temRegistro(espacoNomes)`, `obterTodos()`, `obterEsquemas()` e `limpar()`.

O registro é um objeto, e não estado do módulo como no pacote original, porque na realização node cada `importar` cria uma instância nova do módulo importado.

Qualquer objeto com os métodos `existe(caminho)`, `listarDiretorio(caminho)` (que devolve um vetor de `EntradaDiretorio { nome, ehDiretorio }`), `lerTexto(caminho)` e `juntarCaminhos(base, parte)` pode ser usado no lugar de `sistemaArquivosNode()`.

Quando a mesma propriedade é definida mais de uma vez em um espaço de nomes (por exemplo, `tecnologia` em `liquido.dados`, nos esquemas embutidos e em um pacote), os valores permitidos das duas definições são somados. Se uma delas não restringir os valores, vale a mais recente.

## Linha de comando

```sh
bin/delprops <comando> [argumentos]          # Linux e macOS
bin\delprops.cmd <comando> [argumentos]      # Windows
delegua fontes/ilc.delegua -- <comando> [argumentos]
```

| Comando | Descrição |
| --- | --- |
| `validar <caminho> [--esquemas <arquivo.json>]` | Compreende e valida um arquivo `.delprops` |
| `compreender <caminho>` | Mostra as propriedades e os erros de sintaxe do arquivo |
| `info <propriedade>` | Mostra os detalhes de uma propriedade, em todos os espaços de nomes |
| `esquemas` | Lista os espaços de nomes e as propriedades disponíveis |
| `--ajuda`, `-h` | Mostra a ajuda |
| `--versao`, `-v` | Mostra a versão |

O código de saída é 1 quando há erros (avisos não contam). Se o diretório atual tiver `pacotes/`, os esquemas declarados pelos pacotes instalados entram na validação, no `info` e no `esquemas`. A variável `DELPROPS_DELEGUA` escolhe o interpretador usado pelos scripts de `bin/` (padrão: `delegua`).

A lógica fica em `executarCli(sistema, esquemasAdicionais)`, que não depende da realização: toda leitura de arquivo e escrita no terminal passa pelo objeto `sistema` (veja o comentário no início de `fontes/cli.delegua`). `sistemaCliNode()` é a implementação para a realização node.

## O formato `.delprops`

Inspirado no formato `.properties` do Java. Cada linha não vazia e não comentada define uma propriedade:

```
<espaço de nomes>.<subespaço>[.<subespaço>...] = <valor>
```

Comentários de linha começam com `//`.

| Tipo | Exemplos |
| --- | --- |
| Lógico | `verdadeiro`, `falso` |
| Texto | `'publico'`, `'sqlite'`, `':memory:'` |
| Número | `3000`, `5432`, `-1`, `0.5` |

### Regras

1. Linhas em branco e comentários (`//`) são ignorados.
2. Toda linha não vazia segue `<chave> = <valor>`. Linhas sem `=` são inválidas.
3. Chave e valor não podem estar vazios.
4. Uma chave não pode ser definida mais de uma vez.
5. Em um espaço de nomes conhecido, propriedades fora do esquema geram aviso.
6. O tipo do valor deve corresponder ao tipo da propriedade; divergências geram erro.
7. Propriedades com valores enumerados só aceitam os valores listados.
8. Espaços de nomes desconhecidos são aceitos sem validação, para uso por outros projetos do ecossistema.
9. Quando a chave é o próprio espaço de nomes (`liquido.arquetipo = 'mvc'`), ela é validada contra a propriedade de mesmo nome do último segmento (`arquetipo`). Se não houver essa propriedade, gera aviso. O pacote original sempre gerava aviso nesse caso, inclusive para `liquido.arquetipo` e `liquido.linguagem`.

## Espaço de nomes `liquido`

Reservado para a configuração do [Líquido](https://github.com/DesignLiquido/liquido). Os esquemas estão em `fontes/liquido/`.

### `liquido.arquetipo`

| Propriedade | Tipo | Descrição | Valores permitidos |
| --- | --- | --- | --- |
| `arquetipo` | texto | Arquétipo do projeto Líquido. | `rest`, `mvc` |

### `liquido.linguagem`

| Propriedade | Tipo | Descrição | Valores permitidos |
| --- | --- | --- | --- |
| `linguagem` | texto | Linguagem de programação de back-end do projeto. | `delégua`, `pituguês` |

### `liquido.aplicacao`

| Propriedade | Tipo | Descrição |
| --- | --- | --- |
| `nome` | texto | Nome da aplicação. |
| `versao` | texto | Versão da aplicação. |
| `descricao` | texto | Descrição da aplicação. |
| `licenca.nome` | texto | Nome da licença da aplicação. |
| `licenca.url` | texto | URL da licença da aplicação. |

### `liquido.roteador`

| Propriedade | Tipo | Descrição | Padrão |
| --- | --- | --- | --- |
| `diretorioEstatico` | texto | Caminho do diretório de arquivos estáticos. | `'publico'` |
| `cors` | lógico | Habilita CORS. | `falso` |
| `bodyParser` | lógico | Habilita o body-parser. | `verdadeiro` |
| `morgan` | lógico | Habilita o log de requisições com morgan. | `falso` |
| `cookieParser` | lógico | Habilita o cookie-parser. | `verdadeiro` |
| `passport` | lógico | Habilita o passport para autenticação. | `falso` |
| `json` | lógico | Habilita o suporte a JSON no body. | `verdadeiro` |
| `helmet` | lógico | Habilita o helmet para segurança de cabeçalhos HTTP. | `verdadeiro` |
| `porta` | número | Porta na qual o servidor irá subir. | `3000` |

### `liquido.dados.<nome>`

Fonte de dados nomeada. `<nome>` é um identificador livre escolhido pelo projeto (ex.: `lincones`, `principal`).

| Propriedade | Tipo | Descrição |
| --- | --- | --- |
| `tecnologia` | texto | Tecnologia de banco de dados: `sqlite`, `mysql`, `postgres`, `mongodb`, `mssql`. |
| `caminho` | texto | Caminho do arquivo de banco de dados (ex.: `':memory:'` para SQLite em memória). |
| `host` | texto | Endereço do servidor de banco de dados. |
| `porta` | número | Porta do servidor de banco de dados. |
| `usuario` | texto | Nome de usuário para conexão. |
| `senha` | texto | Senha para conexão. |
| `banco` | texto | Nome do banco de dados. |
| `autoInicializar` | lógico | Inicializa o banco automaticamente ao iniciar o servidor. |
| `arquivoInicializacao` | texto | Arquivo de inicialização do banco (padrão: `'inicializacao.lincones'`). |

### `liquido.autenticacao`

| Propriedade | Tipo | Descrição |
| --- | --- | --- |
| `tecnologia` | texto | Tecnologia de autenticação: `jwt`. |

### `liquido.estilos`

| Propriedade | Tipo | Descrição | Padrão |
| --- | --- | --- | --- |
| `diretorioBase` | texto | Caminho do diretório onde o CSS gerado a partir de FolEs é salvo e servido. | `'publico/css'` |

### Exemplo completo

```
// Metadados do projeto
liquido.arquetipo = 'rest'
liquido.linguagem = 'delégua'
liquido.aplicacao.nome = 'meu-projeto'
liquido.aplicacao.versao = '1.0.0'

// Roteador
liquido.roteador.diretorioEstatico = 'publico'
liquido.roteador.cors = verdadeiro
liquido.roteador.porta = 3000

// Bases de dados
liquido.dados.lincones.tecnologia = 'sqlite'
liquido.dados.lincones.caminho = ':memory:'

// Autenticação e estilos
liquido.autenticacao.tecnologia = 'jwt'
liquido.estilos.diretorioBase = 'publico/css'
```

## Organização do código

| Arquivo | Conteúdo |
| --- | --- |
| `fontes/delprops.delegua` | Ponto de entrada do pacote |
| `fontes/modelos.delegua` | Estruturas de dados (classes) e leitura de definições a partir de dicionários |
| `fontes/tipos.delegua` | Tipos de valor |
| `fontes/analisador.delegua` | `analisar()` |
| `fontes/validador.delegua` | `validar()`, `inferirTipo()`, `valorSemAspas()` |
| `fontes/registro.delegua` | `RegistroEsquemas` |
| `fontes/descobridor.delegua` | `descobrir()` |
| `fontes/esquemas.delegua` | Esquemas embutidos, leitura de JSON e mescla |
| `fontes/formatadores.delegua` | Formatação da saída da linha de comando |
| `fontes/cli.delegua` | `executarCli()` |
| `fontes/ilc.delegua` | Programa da linha de comando (realização node) |
| `fontes/sistema_arquivos_node.delegua`, `fontes/sistema_cli_node.delegua` | Implementações node dos sistemas injetados |
| `fontes/liquido.delegua`, `fontes/liquido/` | Esquemas do Líquido |
| `fontes/utilidades/` | JSON/JSONC e utilidades de texto |

## Testes

```sh
delegua testar
```

Executa todos os `testes/*.teste.delegua` a partir da raiz do repositório. `testes/exemplos/` tem arquivos `.delprops`, um arquivo de esquemas e um diretório `pacotes/` de exemplo para a descoberta.
