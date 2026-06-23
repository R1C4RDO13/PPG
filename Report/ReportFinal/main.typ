#import "Template/lib.typ" : lncs, institute, author, theorem, proof

#set page("a4")
#set text(lang: "pt", region: "PT")

#let UMinho = institute("Universidade do Minho",
  addr: "Escola de Engenharia",
  email: "Mestrado em Engenharia Informática",
  url: "Projeto em Computação Gráfica e Visão por Computador",
)
#set text(lang: "pt", region: "PT")


#show: lncs.with(
  title: "Geração de Dados Sintéticos para Deteção de Objetos Reais",
  authors: (
    author("Pedro Martins [PG57894]",
      insts: (UMinho),
    ),
    author("Ricardo Araújo [PG56002]",
      insts: (UMinho),
    ),

    author("Rui Gonçalves [PG61545]",
      insts: (UMinho),
    )
  ),
 abstract: [
#set text(lang: "pt", region: "PT")
    Este trabalho investiga a viabilidade da utilização de dados puramente sintéticos no treino de modelos de deteção de objetos aplicáveis a contexto real. A partir de um modelo 3D de uma sapatilha desportiva, reconstruído por fotogrametria a partir do objeto real, foram desenvolvidos cenários virtuais em Unreal Engine e construído um _pipeline_ de geração e anotação automática de imagens sintéticas. Dois detetores YOLO26n independentes foram treinados, um exclusivamente com dados sintéticos e outro com fotografias reais, e avaliados sobre um conjunto de teste real comum. O modelo treinado apenas com dados sintéticos igualou ou superou o modelo treinado com dados reais em três das quatro métricas consideradas, demonstrando que a geração de dados sintéticos constitui uma alternativa viável e económica à recolha e anotação manual de imagens reais.
   ],

  keywords: ("dados sintéticos", "deteção de objetos", "YOLO", "Unreal Engine", "fotogrametria"),
  appendix: include "attachments.typ",
)

#set text(lang: "pt", region: "PT")
#set heading(supplement: [Secção])

= Introdução

Este projeto foi desenvolvido no âmbito da unidade curricular de Projeto em Computação Gráfica e Visão por Computador, inserida no Mestrado em Engenharia Informática da Escola de Engenharia da Universidade do Minho.

Com este projeto pretende-se validar a utilização de imagens sintéticas, produzidas a partir da modelação 3D de um objeto real, posteriormente inserido num conjunto de cenários virtuais, para o treino de modelos de deteção desses mesmos objetos em contexto real.

O treino (ou _fine-tuning_) de um modelo de deteção como o YOLO requer um número elevado de imagens reais. Ao esforço associado à aquisição destas imagens acresce ainda o trabalho da sua anotação, o que torna este processo moroso e dispendioso. Em contrapartida, o processo de geração de modelos virtuais a partir de objetos reais tem-se tornado cada vez mais simples, fruto de um conjunto crescente de tecnologias desenvolvidas precisamente com esse objetivo. Entre estas destaca-se o _software_ Kiri Engine, utilizado neste projeto.

A segunda componente necessária à produção das imagens sintéticas são os cenários virtuais 3D. Também aqui o processo de criação é facilitado pelo recurso a ferramentas como o Unreal Engine, uma plataforma orientada para o desenvolvimento de jogos, dotada de capacidades de simulação física complexa e de criação de mundos virtuais. Neste projeto foi utilizada apenas uma fração das suas capacidades. O Unreal Engine possui ainda uma extensa biblioteca de objetos 3D, disponibilizada gratuitamente pela comunidade, que pode ser utilizada no desenvolvimento dos nossos próprios ambientes.

O projeto focou-se na utilização de um modelo 3D gerado a partir de um objeto real, em conjunto com o Unreal Engine para a construção de cenários sintéticos, necessários para a produção de um _dataset_ composto por imagens sintéticas, destinadas ao treino do modelo de deteção escolhido, o YOLO26n.

Com isto, pretende-se validar dois pontos fundamentais:

+ a possibilidade de utilizar imagens sintéticas no treino de modelos de deteção de objetos reais;
+ a possibilidade de o fazer de forma automatizada e rápida, a uma fração do custo necessário para a recolha e anotação de imagens reais equivalentes.

O presente relatório encontra-se organizado da seguinte forma: após a presente introdução e a apresentação das tecnologias utilizadas, descreve-se a modelação 3D do objeto (@sec_modelacao); segue-se a geração dos cenários sintéticos (@sec_cenarios) e as duas rotinas de recolha e anotação automática de imagens (@sec_recolha_sintetica); descreve-se depois a recolha das imagens reais (@sec_recolha_real) e o treino dos dois modelos de deteção (@sec_treino); por fim, apresentam-se a comparação dos resultados e as limitações identificadas (@sec_comparacao), as conclusões (@sec_conclusoes) e o trabalho futuro (@sec_futuro).

=== Tecnologias utilizadas

==== Kiri Engine

O Kiri Engine é uma aplicação móvel e _web_ de digitalização 3D desenvolvida pela KIRI Innovation, disponível para iPhone, Android e _browser_, que utiliza fotogrametria avançada para gerar modelos 3D detalhados e texturizados a partir de conjuntos de fotografias ou vídeos captados de múltiplos ângulos, eliminando a necessidade de _hardware_ dedicado e dispendioso. Os modelos gerados podem ser exportados em múltiplos formatos, nomeadamente OBJ, FBX, STL, GLB, GLTF, USDZ, PLY e XYZ, sendo compatíveis com ferramentas como Blender, Unreal Engine e Autodesk Maya.

==== Unreal Engine

O Unreal Engine é um motor de jogo desenvolvido pela Epic Games, amplamente utilizado na indústria de videojogos e em áreas como a produção virtual e a visualização arquitetónica, graças às suas capacidades de renderização em tempo real, simulação física e criação procedimental de mundos. Neste projeto, foi utilizado para a composição de cenários virtuais e para a renderização automatizada das imagens sintéticas do _dataset_, recorrendo apenas a uma fração reduzida das suas funcionalidades.

A opção por esta plataforma justifica-se pela sua grande popularidade, que se traduz numa abundância de documentação e de informação de suporte disponível, pela sua acessibilidade a utilizadores sem experiência prévia (_beginner-friendly_), e pela extensa biblioteca de _assets_ gratuitos disponibilizada pela comunidade, fator essencial para a produção dos cenários utilizados.

==== Roboflow

O Roboflow é uma plataforma _online_ de gestão, anotação e conversão de _datasets_ de visão por computador, com suporte para anotação assistida e exportação em diversos formatos, incluindo o formato YOLO. Foi utilizado para a organização, anotação e exportação dos conjuntos de dados deste projeto, recorrendo-se ao seu nível gratuito (_free tier_).

Os mecanismos de anotação automática disponibilizados pela plataforma revelaram-se bastante robustos, permitindo automatizar quase por completo a anotação das imagens reais; foi necessário anotar manualmente menos de um terço do total de imagens produzidas.

==== YOLO26

O YOLO26 é a geração mais recente da família de modelos de deteção de objetos da Ultralytics, sucedendo ao YOLO11 e disponível em cinco variantes de tamanho crescente, _nano_ (n), _small_ (s), _medium_ (m), _large_ (l) e _extra-large_ (x), que permitem equilibrar velocidade, precisão e exigência computacional.

Neste projeto optámos pela variante _nano_ (*YOLO26n*), a mais leve da família, por implicar menor tempo necessário para treino e menor exigência computacional, sendo também, em teoria, a que apresenta maior facilidade em aprender o objeto em causa, tratando-se da deteção de uma única categoria. Não sendo o foco deste trabalho a avaliação comparativa do modelo de deteção, não se considerou necessário validar outras variantes. Os modelos YOLO da Ultralytics são, de resto, amplamente reconhecidos no domínio da deteção de objetos e estão disponíveis gratuitamente para utilização em contexto académico.

= Modelação e escolha do objeto <sec_modelacao>

== Escolha do objeto e contexto

Para o desenvolvimento deste projeto foi selecionado como objeto de estudo uma sapatilha desportiva. A escolha deste objeto justifica-se pela sua complexidade geométrica, pela diversidade de texturas e pelas variações cromáticas fortes em branco e vermelho, características que constituem um desafio representativo para um modelo de deteção.

== Modelação 3D através do Kiri Engine

Em vez de se modelar o objeto do zero através de _software_ de escultura 3D, optou-se por uma abordagem de fotogrametria, com recurso à aplicação Kiri Engine.

A fotogrametria consiste na reconstrução de um modelo tridimensional a partir de um conjunto de fotografias do objeto captadas de múltiplos ângulos. Para o efeito, foram captadas 61 fotografias da sapatilha, cobrindo as várias faces e perspetivas do objeto e garantindo sobreposição suficiente entre imagens consecutivas para uma reconstrução coerente. A partir destas imagens, o Kiri Engine gera uma malha texturizada que reproduz a geometria e o aspeto visual do objeto real, preservando as variações cromáticas em branco e vermelho que o caracterizam.

A principal vantagem desta abordagem reside na rapidez do processo e no realismo das texturas obtidas, que derivam diretamente de fotografias reais e não de materiais sintetizados manualmente. A reconstrução apresentou, no entanto, limitações na zona da sola: por ser a superfície de contacto com o solo durante a captação, ficou parcialmente oculta e foi reconstruída com menor qualidade, exigindo correção posterior.

#figure(
  grid(
    columns: 4,
    gutter: 4pt,
    ..range(1, 13).map(i =>
      image("Imagens/Sapatilha_modelo/Fotos/" + str(i) + ".jpg", height: 2.4cm, fit: "cover")
    )
  ),
  caption: [Amostra representativa de parte das 61 fotografias captadas para a reconstrução
    fotogramétrica.],
)

#figure(
  pad(x: -2cm,
  [
#grid(
  columns: (auto, auto),
  align: center + horizon,
  figure(
  [
    #image("Imagens/Sapatilha_modelo/KIRI/Captura de ecrã 2026-06-21 173019.png",   fit: "contain", height: 150pt)
  ],
  caption: [Modelo reconstruído em Kiri Engine]),
  figure(
  [
    #image("Imagens/Sapatilha_modelo/KIRI/Captura de ecrã 2026-06-21 173124.png", fit: "contain", height: 150pt)
  ],
  caption: [Modelo final Kiri Engine (recorte do excesso)])
)
]))

== Correção da malha em Blender

A malha resultante da fotogrametria apresentava irregularidades, em particular na sola, decorrentes das limitações já referidas na captação das superfícies inferiores. Para as corrigir, a malha foi importada para o Blender, onde se procedeu à edição da geometria, suavizando e regularizando a sola de modo a eliminar artefactos e a obter uma base limpa e coerente.

#figure(
  [
    #image("Imagens/Sapatilha_modelo/Blender/sola_suave.png",   fit: "contain", height: 200pt)
  ],
  caption: [Sola da sapatilha após retoque em Blender],
)

== Recuperação do relevo da sola --- _heightmap_ em GIMP

Durante a limpeza da malha perdeu-se parte do detalhe do relevo característico da sola. Para o recuperar de forma controlada, foi criado um _heightmap_ personalizado no GIMP, a partir de uma fotografia direta da base da sapatilha. Este mapa de alturas, em escala de cinzentos, codifica a profundidade do padrão da sola e foi reaplicado ao modelo, reintroduzindo o relevo sem comprometer a integridade da geometria corrigida.

#figure(
  pad(x: -2cm,
  [
#grid(
  columns: (auto, auto),
  align: center + horizon,
  figure(
  [
    #image("Imagens/Sapatilha_modelo/GIMP/sola.jpg",   fit: "contain", height: 150pt)
  ],
  caption: [Fotografia da sola]),
  figure(
  [
    #image("Imagens/Sapatilha_modelo/GIMP/SolaPretoBranco.png", fit: "contain", height: 150pt)
  ],
  caption: [_Heightmap_ da sola])
)
]))

#pagebreak()

== Modelo 3D final

O resultado deste fluxo de trabalho foi um modelo 3D texturizado e geometricamente coerente da sapatilha, fiel ao objeto real e pronto a ser instanciado nos cenários virtuais desenvolvidos em Unreal Engine para a geração do _dataset_ sintético.

#figure(
  grid(
    columns: 3,
    gutter: 4pt,
    ..range(1, 7).map(i =>
      image("Imagens/Sapatilha_modelo/Blender/final_" + str(i) + ".png", height: 2.4cm, fit: "cover")
    )
  ),
  caption: [Modelo 3D final.],
) <fig:fotos-modelo>

#pagebreak()

= Geração dos cenários sintéticos <sec_cenarios>

Após a modelação do objeto, seguiu-se a criação dos cenários sintéticos. O principal objetivo desta etapa era perceber como o modelo se comportaria em diferentes contextos, pelo que se optou por desenvolver cenários tanto para ambientes interiores como para ambientes exteriores. Tendo em conta que a construção de cada cenário a partir do zero implicaria um investimento de tempo desproporcionado face aos objetivos principais do trabalho, optou-se por recorrer a _assets_ já existentes, adequados à estratégia definida. Concluída a criação dos cenários, procedeu-se à integração do objeto nos mesmos, dando-se então início à recolha das imagens.

Foram desenvolvidas três famílias de cenários, num total de quatro: Urbano, Natureza (subdividido em Natureza 1 e Natureza 2) e Interior. Entre os diferentes cenários foram introduzidas variações de iluminação, distância, ângulo de câmara e oclusão, com o objetivo de aproximar o _dataset_ da diversidade encontrada em ambiente real.

Os cenários Natureza 2#footnote[#link("https://fab.com/s/7ee8c5704aaa")] e Interior#footnote[#link("https://fab.com/s/0673d885a064")] correspondem a ambientes completos, obtidos junto da comunidade através da plataforma Fab#footnote[Fab é o _marketplace_ de _assets_ da Epic Games, resultante da unificação do Unreal Engine Marketplace, da Sketchfab Store, do Quixel Megascans e da ArtStation Marketplace.]. Os restantes cenários foram construídos a partir de múltiplas fontes de _assets_ individuais, igualmente obtidos através da plataforma Fab e da biblioteca de conteúdos gratuitos do Unreal Engine.

#let cenaimg(path) = image(path, width: 7.5cm, height: 5.625cm, fit: "cover")

#figure(
  pad(x: -2cm,
    grid(
      columns: 2,
      gutter: 6pt,
      cenaimg("Imagens/Cenarios/Urbano.png"),
      cenaimg("Imagens/Cenarios/Natureza1.png"),
    )
  ),
  caption: [Exemplos dos cenários sintéticos desenvolvidos: Urbano (esquerda) e Natureza 1 (direita).],
) <fig_cenarios>


#figure(
  pad(x: -2cm,
    grid(
      columns: 2,
      gutter: 6pt,
      cenaimg("Imagens/Cenarios/Natureza2.png"),
      cenaimg("Imagens/Cenarios/IndoorCafe.png"),
    )
  ),
  caption: [Exemplos dos cenários sintéticos desenvolvidos: Natureza 2 (esquerda) e Interior (direita).],
) <fig_cenarios2>


= Recolha de imagens sintéticas <sec_recolha_sintetica>

A recolha das imagens sintéticas foi realizada através do uso de _Blueprints_ no Unreal Engine, em conjunto com materiais emissivos customizados.

As _Blueprints_ constituem o sistema de _scripting_ visual do Unreal Engine, permitindo definir comportamentos, eventos e lógica de jogo através de uma interface gráfica baseada em nós interligados, sem necessidade de escrever código em C++. Cada _Blueprint_ está associada a uma classe ou ator (_actor_) e contém um grafo visual onde se podem definir variáveis, funções e eventos que determinam o seu comportamento dentro do motor. Este sistema reduz significativamente a barreira de entrada para utilizadores sem experiência prévia de programação, mantendo simultaneamente o acesso a uma grande parte das funcionalidades do motor.

Os materiais customizados permitiram estender as capacidades oferecidas pelas _Blueprints_, podendo também eles ser definidos através do mesmo sistema de _scripting_ visual baseado em nós. Recorrendo a este mecanismo, foi possível definir regras que alteravam o aspeto de todos os componentes do ambiente para uma cor uniforme, à exceção do objeto 3D escolhido para deteção, a sapatilha, que permanecia associado a uma cor distinta.

== Rotina 1 --- Posicionamento, rotação e _screenshot_

A primeira abordagem para a captação das imagens do _dataset_ sintético assentou
numa rotina simples de rotação e captura, implementada no _blueprint_
`BP_Sapatilha_Rotator`. Nesta versão inicial, o _blueprint_ limitava-se a *rodar o
objeto e a registar uma captura de ecrã a cada incremento angular*, sem qualquer
geração de máscara.

O funcionamento, por sessão, era o seguinte:

+ posicionamento da sapatilha e da câmara, com enquadramento fixo;
+ rotação local de 10° em torno do eixo Z;
+ captura de ecrã do fotograma (comando `HighResShot 1920x1080`);
+ repetição do processo ao longo de 36 iterações, perfazendo uma volta completa
  de 360°.

Cada sessão produzia assim 36 imagens. Aplicando esta rotina às sete condições
de captura definidas (_eye-level_, _high-angle_, _low-angle_, oclusão com poste,
meia-longa, fim de tarde e _hard negatives_), obteve-se um total de *224 imagens
base* (216 com a sapatilha e 8 _hard negatives_).

=== Processamento no Roboflow

Como esta rotina gerava apenas a imagem RGB, sem qualquer informação sobre a
localização do objeto, a anotação teve de ser feita *manualmente*. Para o efeito
recorreu-se à plataforma Roboflow, onde se desenhou à mão uma _bounding box_ por
imagem, todas associadas à classe única `Sapatilha`, anotando as 224 imagens.

== Evolução da Rotina 1

Na sequência do _checkpoint 3_, foi aconselhada uma reformulação da
estratégia de anotação: em vez de rotular manualmente cada imagem no Roboflow,
passou a recorrer-se ao *próprio Unreal Engine* para automatizar a captura das
imagens e das respetivas máscaras, o que, por sua vez, permitiu, com recurso a
código Python, calcular o ficheiro `.txt` com os limites das _bounding boxes_
correspondentes, eliminando assim o trabalho manual.

Para isso, a `BP_Sapatilha_Rotator` foi estendida: além da rotação e da captura
RGB já existentes, passou a gerar, em cada ângulo, a *máscara* correspondente do
objeto. A máscara é obtida substituindo temporariamente o material da sapatilha
por um material emissivo vermelho (`Vermelho_emissivo_unlit`, com _Shading
Model_ = Unlit e _Emissive Color_ = (1, 0, 0)), que isola por completo o objeto
do fundo. Cada ângulo passa, assim, a produzir um *par de imagens
correspondentes*: a RGB e a respetiva máscara.

O ciclo de captura, agora recursivo, executa por iteração a seguinte sequência:

+ rotação local de 10° em torno do eixo Z;
+ aplicação do material original e captura da imagem *RGB*;
+ substituição pelo material emissivo vermelho e captura da *máscara*;
+ incremento do contador `Fotos Tiradas` e nova chamada ao ciclo, até às 36
  capturas (360°).

#figure(
  pad(x: -2cm,
  image("Imagens/Rotina_1/bp_ciclo_captura.png", width: 100%)),
  caption: [Ciclo de captura da `BP_Sapatilha_Rotator`: rotação, captura RGB e
    captura da máscara com o material emissivo vermelho.],
) <fig:bp-ciclo>

A inicialização do ciclo é desencadeada pela tecla *P*, que repõe o contador a
zero e guarda o material original (para o repor entre capturas), enquanto a
configuração do ponto de vista da câmara é feita no evento `BeginPlay`.

#figure(

  pad(x: -2cm,
  grid(
    columns: 2,
    gutter: 6pt,
    image("Imagens/Rotina_1/bp_beginplay.png"),
    image("Imagens/Rotina_1/bp_tecla_p.png"),
  )),
  caption: [Configuração da câmara em `BeginPlay` (esq.) e arranque do ciclo pela
    tecla P (dir.).],
) <fig:bp-init>

Adicionalmente, a tecla *G* permite capturar um único par RGB + máscara no ângulo
atual, sem acionar a rotação, sendo útil para validar pontualmente um
enquadramento.

#figure(
  pad(x: -2cm,
  image("Imagens/Rotina_1/bp_tecla_g.png", width: 100%)),
  caption: [Captura de um par isolado RGB + máscara (tecla G).],
) <fig:bp-g>

Dois aspetos foram determinantes para o correto funcionamento desta abordagem.
Primeiro, a *sincronização*: a troca de material e o comando de captura são
operações assíncronas, pelo que, sem espera entre elas, a captura podia ser
disparada antes de o material estar aplicado, causando um desfasamento de um
fotograma entre a RGB e a máscara; introduziram-se _Delays_ de 0,2 a 0,5
segundos para garantir o alinhamento. Segundo, a *cor da máscara*: o
_tonemapper_ do Unreal desloca o vermelho emissivo puro para um tom alaranjado na
captura, variação que teve de ser tida em conta na deteção posterior dos píxeis
do objeto.

=== Extração das _bounding boxes_ <pos_process1>

Com os pares RGB + máscara gerados pelo Unreal, a etapa seguinte consistiu em
converter cada máscara numa anotação no formato YOLO. Para o efeito desenvolveu-se
o _script_ `mask_to_yolo.py`, em Python, que processa automaticamente todos os
pares de uma sessão e produz, para cada imagem RGB, o respetivo ficheiro `.txt`
com a _bounding box_ da sapatilha.

O processamento de cada par assenta na deteção dos píxeis correspondentes ao
objeto na máscara. Como referido, o _tonemapper_ do Unreal desloca o vermelho
emissivo puro para um tom alaranjado (aproximadamente $R = 254$, $G = 84$, $B =
24$), pelo que o critério de deteção não procura vermelho puro, mas antes esta
assinatura cromática específica. Um píxel é classificado como pertencente ao
objeto quando satisfaz, em simultâneo, as seguintes condições:

#align(center)[
  #table(
  columns: (auto, auto),
  align: (left, left),
  table.header([*Condição*], [*Justificação*]),
  [$R >= 200$], [Canal vermelho elevado],
  [$G <= 140$], [Canal verde moderado a baixo],
  [$B <= 90$], [Canal azul baixo],
  [$R - G >= 80$], [Garante cor saturada (não acinzentada)],
  [$R - B >= 140$], [Distingue o objeto de tons neutros],
)
]

Estes limiares foram calibrados a partir de medições diretas sobre as máscaras
reais, assegurando que a deteção isola a sapatilha sem capturar elementos do
cenário (pavimento, relva ou sombras), cujos canais cromáticos não satisfazem o
conjunto de condições.

==== Deteção automática do par e robustez a ruído

O _script_ não assume qual dos dois ficheiros de cada par é a RGB e qual é a
máscara. Em vez disso, *deteta automaticamente* a máscara como sendo a imagem do
par com maior número de píxeis alaranjados, tornando o processo independente da
ordem pela qual o Unreal grava os ficheiros. Esta decisão revelou-se importante,
uma vez que a ordem de gravação se mostrou inconsistente entre sessões.

Para evitar falsos positivos, o _script_ recorre a dois limiares de área
complementares. Por um lado, exige-se uma área total mínima de $300$ píxeis
($"MIN"_"PIXELS"$), abaixo da qual se considera não existir objeto; por outro,
cada região contígua de píxeis tem de possuir, no mínimo, $80$ píxeis
($"MIN"_"COMPONENT"$) para ser tida em conta, descartando-se assim pequenos
focos de ruído isolado. Esta dupla verificação assegura que apenas regiões
suficientemente significativas contribuem para a anotação, evitando tanto a
deteção de ruído residual como a omissão de objetos legitimamente pequenos ou
distantes.

==== Tratamento da oclusão

Um caso particular exigiu cuidado adicional. Nas capturas da condição de oclusão,
o poste divide a sapatilha em *dois fragmentos visíveis distintos* na máscara. A
versão inicial do _script_, que retinha apenas a maior região contígua de píxeis,
produzia uma _bounding box_ que cobria somente um dos fragmentos, deixando o
restante de fora.

A versão final corrige este comportamento: em vez de reter apenas a maior região,
o _script_ considera *todos* os fragmentos válidos --- isto é, todas as regiões que
satisfazem o limiar $"MIN"_"COMPONENT"$ atrás referido --- e calcula a _bounding
box_ que os engloba a todos. Desta forma, a caixa abrange a extensão completa do
objeto, mesmo quando parcialmente oculto, em conformidade com a convenção
habitual de anotação para deteção de objetos.

==== Conversão para o formato YOLO

Para cada par processado, o _script_ copia a imagem RGB para a pasta de saída e
escreve o ficheiro de anotação correspondente. As coordenadas da _bounding box_,
inicialmente em píxeis ($x_min$, $y_min$, $x_max$, $y_max$), são convertidas para
o formato YOLO --- centro normalizado e dimensões normalizadas --- através de:

$ x_c = (x_min + x_max) / (2 W), quad y_c = (y_min + y_max) / (2 H) $

$ w = (x_max - x_min) / W, quad h = (y_max - y_min) / H $

onde $W$ e $H$ representam, respetivamente, a largura e a altura da imagem. Cada
ficheiro `.txt` contém uma linha no formato `classe x_c y_c w h`, com a classe
única `0` (sapatilha).

As imagens sem objeto visível --- os _hard negatives_ e os casos de cenário vazio ---
geram automaticamente um ficheiro `.txt` vazio, comportamento que corresponde
exatamente à convenção YOLO para exemplos negativos, sem necessidade de qualquer
tratamento adicional.

==== Acumulação de múltiplos cenários

Dado que o conjunto de dados sintético reúne vários cenários (urbano, natureza e
interior), e que o Unreal reinicia a numeração dos ficheiros em cada sessão, o
_script_ atribui a cada imagem um *prefixo identificador do cenário* (por exemplo,
`urbano_0001`, `natureza_0001`). Este mecanismo permite acumular todos os
cenários numa mesma pasta de _dataset_ sem colisões de nomes, processando um
cenário de cada vez.

== Rotina 2 --- _Blueprint_ com posicionamento aleatório dentro da cena

À semelhança da rotina anterior, este procedimento foi implementado através de uma nova _Blueprint_, `BP_Shoe`, que integra um ator correspondente ao modelo 3D da sapatilha e uma câmara, responsável pela captura do _screenshot_. Nesta rotina, no entanto, são utilizados dois materiais customizados, em vez de apenas um, cada um dotado de lógica própria, destinados à produção da caixa delimitadora (_bounding box_) do objeto.

A principal evolução desta rotina, comparativamente à anterior, reside na automatização do posicionamento do modelo e da câmara dentro de um espaço parametrizável, definido em relação à raiz (_root_) do modelo. Esta alteração permitiu eliminar uma das maiores limitações da rotina anterior, o posicionamento manual da sapatilha, possibilitando que a rotina opere de forma autónoma, em _loop_, durante várias horas e sem supervisão, enquanto são produzidas as imagens sintéticas.

=== Posicionamento do objeto modelo <posicionamento_obj>

Para o posicionamento do objeto modelo em posições aleatórias dentro da cena, recorreu-se ao motor de física do Unreal Engine. O posicionamento da sapatilha numa posição aleatória sem qualquer consideração pela colisão com os restantes objetos da cena não produziria resultados suficientemente realistas. Por outro lado, a implementação de uma _Blueprint_ capaz de calcular, de forma determinística, uma posição válida no espaço para a sapatilha, tendo em consideração a totalidade dos objetos presentes na cena, revelou-se inviável.

A estratégia que se revelou mais eficaz consistiu no seguinte: para cada cena, foi definida uma área delimitada nos eixos X, Y e Z (_Half Size_, @ROTINA2_SHOE_1), situada acima de todos os objetos presentes no espaço e estabelecida em relação à raiz (_Default Scene Root_, @ROTINA2_SHOE_1) da _Blueprint_. A rotina gerava, então, aleatoriamente, uma nova posição para a sapatilha dentro dessa área, suspendendo-a momentaneamente no ar; a simulação de gravidade do motor de física era responsável por posicionar o objeto de forma realista, fazendo-o cair sobre o solo ou sobre outros elementos da cena, como árvores ou rochas.

Esta abordagem exigiu a definição de mapas de colisão para o modelo da sapatilha e para todos os objetos com que esta poderia interagir, incluindo o solo. Não sendo o desempenho computacional uma preocupação relevante neste contexto, optou-se, para muitos dos objetos, por uma solução simples ainda que computacionalmente pouco eficiente, utilizando a própria malha (_mesh_) do modelo como mapa de colisão. Para objetos de geometria mais simples, recorreu-se, em alternativa, a representações de colisão simplificadas.

#figure(
  [
    #image("Imagens/ROTINA2_SHOE_POSITION.png",   fit: "contain", width: 350pt)
  ],
  caption: [Rotina para posicionamento do objeto (_Shoe 1_)],
) <ROTINA2_SHOE_1>

=== Posicionamento da câmara <AutoCamara>

Foi também necessário tornar a posição da câmara dinâmica em relação ao objeto, sem que esta lhe estivesse fixamente associada (_attached_). Para tal, foi adicionado um processo na sequência do posicionamento do objeto (@posicionamento_obj), destinado a calcular uma nova posição para a câmara.

A partir da posição inicial do objeto, ainda antes da atuação da gravidade, é aplicado um deslocamento (_offset_) de 100 unidades no eixo Z. O restante processo de posicionamento segue uma lógica semelhante à descrita anteriormente: é definida uma área (_half size_ da câmara) dentro da qual esta pode ser posicionada aleatoriamente, em relação à posição da sapatilha somada do referido deslocamento.

#figure(
  [
    #image("Imagens/ROTINA2_CAMERA_POSITION.png",   fit: "contain", width: 350pt)
  ],
  caption: [Rotina para posicionamento da câmara (_Camera_)],
) <ROTINA2_CAMERA_1>

Por fim, é necessário garantir que a câmara mantém o foco na direção em que a sapatilha irá cair. Para tal, foi implementado um evento (_Event Tick_) que orienta continuamente a câmara na direção do objeto. Este evento é espoletado no momento do primeiro posicionamento do objeto, mantendo-se ativo de forma contínua, sem qualquer condição de término.

#figure(
  [
    #image("Imagens/ROTINA2_CAMERA_TICK.png",   fit: "contain", width: 350pt)
  ],
  caption: [Rotina para orientação da câmara (_Camera_)],
) <ROTINA2_ORIENTATION>


=== Deteção de oclusão <oclusao>

Esta abordagem revelou, numa fase inicial, um problema relevante: era necessário determinar a posição da sapatilha no espaço e se esta se encontrava visível na imagem e, em caso afirmativo, qual a percentagem da sua área visível em relação à área total que ocuparia no espaço. Isto para não introduzir dados ruidosos no _dataset_, com imagens anotadas com apenas uma fração da sapatilha visível.

Para resolver este problema, e à semelhança da solução adotada na rotina 1, foram desenvolvidos dois materiais customizados, aplicados ao modelo da sapatilha: um material azul e um material vermelho. O material azul (@BLUE_RED_MAT) funciona como uma espécie de raio-X, tornando todos os restantes elementos da cena pretos e representando unicamente a sapatilha a azul, independentemente de esta se encontrar ou não oculta por outros objetos. O material vermelho (@BLUE_RED_MAT), por sua vez, segue uma lógica semelhante, mas tendo em consideração a oclusão provocada pelos objetos posicionados entre a câmara e a sapatilha.

A distinção entre o objeto e o restante da cena é controlada através da propriedade _Custom Depth Stencil Value_, definida como 255 no modelo da sapatilha. Esta propriedade permite identificar, de forma isolada, os píxeis correspondentes ao objeto, possibilitando que os materiais customizados apenas pintem a sapatilha com a cor associada (azul ou vermelha), mantendo todos os restantes elementos da cena a preto.

#figure(
  pad(x: -2cm,
  [
#grid(
  columns: (auto, auto),
  align: center + horizon,
  figure(
  [
    #image("Imagens/Material_AZUL.png",   fit: "contain", height: 150pt)
  ],
  caption: [Material azul --- raio-X]
)

,
  figure(
  [
    #image("Imagens/Material_VERMELHO.png", fit: "contain", height: auto)
  ],
  caption: [Material vermelho --- identificação do objeto])
)
])) <BLUE_RED_MAT>

A partir de cada captura são assim gerados três ficheiros:

- a imagem original (_OG_), utilizada para o treino do modelo YOLO;
- a máscara azul, que identifica a área total ocupada pela sapatilha no espaço da imagem, ignorando qualquer oclusão;
- a máscara vermelha, que identifica apenas a área da sapatilha efetivamente visível na imagem, considerando a oclusão por outros objetos.

#figure(
  pad(x: -2cm,
  [
#grid(
  columns: (auto, auto, auto),
  align: center + horizon,
  figure(
  [
    #image("Imagens/image_0CE3ADA94EC4E001DF1744A11387B4D0_BLUE_crop640.png", fit: "stretch", height: auto)
  ],
  caption: [Máscara azul --- área total]),
  figure(
  [
    #image("Imagens/image_0CE3ADA94EC4E001DF1744A11387B4D0_OG_crop640.png", fit: "stretch", height: auto)
  ],
  caption: [Imagem original (_OG_)]),
  figure(
  [
    #image("Imagens/image_0CE3ADA94EC4E001DF1744A11387B4D0_RED_crop640.png", fit: "stretch", height: auto)
  ],
  caption: [Máscara vermelha --- área visível])
)

]))

A comparação entre as áreas das duas máscaras permite calcular uma pontuação de visibilidade (_visibility score_), utilizada numa fase de pós-processamento para identificar e descartar imagens em que esta pontuação seja demasiado baixa. A máscara vermelha é ainda utilizada para calcular a caixa delimitadora (_bounding box_) do objeto, necessária à geração das anotações utilizadas no treino supervisionado do modelo.

Relativamente ao processo seguido na rotina 1, em que apenas o fundo da cena era uniformizado numa cor de contraste face à sapatilha, nesta rotina optou-se por que todas as áreas que não pertencem ao modelo do objeto fiquem a preto. Esta alteração simplifica o pós-processamento.

=== _Loop_ automático --- automatização da rotina de extração de imagens sintéticas

Após as alterações introduzidas no posicionamento do objeto (@posicionamento_obj) e da câmara (@AutoCamara), em conjunto com a robustez adicional introduzida pelo mecanismo de deteção de oclusão (@oclusao), tornou-se possível que o mecanismo de captura de imagens operasse sem necessidade de supervisão, de forma totalmente autónoma.

Foi assim desenvolvida, dentro da _Blueprint_, uma rotina destinada a automatizar a sequência completa de passos necessários: posicionamento do objeto e da câmara, captura de ecrã da imagem original, aplicação do material azul e respetiva captura de ecrã, e aplicação do material vermelho com a correspondente captura de ecrã. Esta rotina opera de forma recursiva, repetindo continuamente este ciclo até que o utilizador a interrompa manualmente, através de uma tecla dedicada (tecla *L*, utilizada tanto para iniciar como para terminar a execução). Com este mecanismo, tornou-se possível recolher centenas de imagens sintéticas por hora, já acompanhadas das respetivas máscaras para anotação, sem qualquer necessidade de intervenção manual.

#figure(
    pad(x: -2cm,

  [
    #image("Imagens/LOOP.png",   fit: "contain")
  ]),
  caption: [Ciclo autónomo de captura da `BP_Shoe`.],
) <LOOP>

=== Pós-processamento da Rotina 2

Tal como na rotina anterior (@pos_process1), as imagens e máscaras extraídas exigiram uma fase de processamento, implementada no _notebook_ `MaskPreparation.ipynb`. Esta segue a mesma lógica geral --- deteção dos píxeis correspondentes ao objeto, cálculo de uma _bounding box_ e produção da anotação no formato YOLO ---, introduzindo, no entanto, alterações relevantes na forma como a deteção de oclusão (@oclusao) é tratada.

==== Deteção das máscaras

Para cada uma das duas máscaras, a identificação dos píxeis pertencentes ao objeto segue um critério de cor análogo ao utilizado em @pos_process1, com uma diferença importante: nesta rotina não é necessária qualquer compensação relativa ao _tonemapper_ do Unreal. Como a distinção entre o objeto e o restante da cena é garantida pela propriedade _Custom Depth Stencil Value_ (@oclusao), apenas a sapatilha é pintada pelos materiais customizados, mantendo-se a cor resultante fiel à cor pura definida em cada material.

Um píxel é classificado como pertencente ao objeto na máscara azul quando satisfaz, em simultâneo:

#align(center)[
  #table(
  columns: (auto, auto),
  align: (left, left),
  table.header([*Condição*], [*Justificação*]),
  [$B > 127$], [Canal azul elevado],
  [$R < 80$], [Exclui tons que não sejam azul puro],
  [$G < 80$], [Exclui tons que não sejam azul puro],
)
]

De forma análoga, na máscara vermelha:

#align(center)[
  #table(
  columns: (auto, auto),
  align: (left, left),
  table.header([*Condição*], [*Justificação*]),
  [$R > 127$], [Canal vermelho elevado],
  [$G < 80$], [Exclui tons que não sejam vermelho puro],
  [$B < 80$], [Exclui tons que não sejam vermelho puro],
)
]

==== Classificação por visibilidade

A área ocupada pelos píxeis de cada máscara permite calcular a pontuação de visibilidade do objeto na imagem:

$ "visibility" = "área"_"vermelha" / "área"_"azul" $

A partir desta pontuação, é aplicada a seguinte regra de classificação:

#align(center)[
  #table(
  columns: (auto, auto),
  align: (left, left),
  table.header([*Visibilidade*], [*Classificação*]),
  [$< 20%$], [Objeto não visível --- anotação vazia (_hard negative_)],
  [$20% - 60%$], [Caso ambíguo --- imagem descartada],
  [$> 60%$], [Objeto visível --- anotação com _bounding box_],
)
]

Esta regra permite excluir do _dataset_ tanto as imagens em que a sapatilha não está, na prática, presente, como aquelas em que a sua visibilidade é demasiado reduzida para constituir um exemplo de treino fiável, evitando a introdução de ruído na anotação.

==== Extração da _bounding box_ e evolução face à Rotina 1

Nas imagens classificadas como contendo o objeto, a _bounding box_ é calculada diretamente a partir das coordenadas mínima e máxima dos píxeis pertencentes à máscara vermelha, nos eixos horizontal e vertical, sendo o resultado normalizado de acordo com o formato YOLO.

Ao contrário do processo descrito em @pos_process1, não foi necessária qualquer filtragem de componentes de ruído, equivalente aos limiares $"MIN"_"PIXELS"$ e $"MIN"_"COMPONENT"$ ali definidos. Esta simplificação decorre diretamente da forma como a máscara é gerada: ao isolar o objeto através do _Custom Depth Stencil Value_, em vez de uma assinatura de cor que poderia, em teoria, ocorrer aleatoriamente noutros elementos da cena, a máscara vermelha não está sujeita a falsos positivos provenientes do restante cenário, eliminando a necessidade de um limiar mínimo de área total.

Por outro lado, o problema da fragmentação do objeto por oclusão, que em @pos_process1 exigiu uma análise explícita de componentes conexos para reunir os diferentes fragmentos numa única caixa, é aqui resolvido sem necessidade de qualquer lógica adicional. Como a _bounding box_ resulta diretamente do envolvente mínimo e máximo de todos os píxeis vermelhos, sem qualquer filtragem por componente, os fragmentos resultantes de uma oclusão parcial são automaticamente englobados na mesma caixa. Esta simplificação não decorre de um algoritmo mais sofisticado, mas sim da limpeza da máscara subjacente: não estando esta sujeita a ruído proveniente do restante cenário, deixa de ser necessário distinguir entre fragmentos válidos do objeto e focos de ruído isolado, tornando dispensável a própria análise de componentes conexos.

#pagebreak()

= Recolha das imagens reais <sec_recolha_real>

Para constituir o conjunto de dados real, destinado tanto ao treino do modelo de referência (Modelo B) como à avaliação final de ambos os modelos, foram captadas fotografias da sapatilha em ambientes reais, procurando reproduzir a diversidade de contextos representada nos cenários sintéticos. No total, foram recolhidas 129 fotografias do objeto, abrangendo variações de iluminação, fundo, distância, ângulo de captura e situações de oclusão parcial, de modo a aproximar o conjunto das condições que um detetor enfrentaria numa aplicação real.

== Processamento com Roboflow

A anotação das imagens reais foi realizada na plataforma Roboflow. Ao contrário das imagens sintéticas, cuja anotação foi gerada automaticamente a partir das máscaras, as fotografias reais não dispõem de qualquer informação prévia sobre a localização do objeto, exigindo anotação supervisionada. Para reduzir o esforço associado a esta tarefa, recorreu-se aos mecanismos de anotação assistida da plataforma, que sugerem automaticamente caixas delimitadoras com base em modelos pré-treinados. Estes mecanismos revelaram-se suficientemente robustos para automatizar grande parte do processo, tendo sido necessária a anotação manual de menos de um terço do total de imagens; nos restantes casos, bastou validar ou ajustar pontualmente as sugestões automáticas.

Todas as anotações foram associadas à classe única `Sapatilha` e exportadas no formato YOLO, em coerência com os conjuntos de dados sintéticos, garantindo a uniformidade necessária ao treino e à comparação dos modelos.

= Modelos YOLO e treino dos modelos <sec_treino>

O sistema de treino desenvolvido está organizado em duas fases principais e sequenciais. Na primeira fase, o _notebook_ `DataPreparation.ipynb` é responsável por toda a preparação dos dados: leitura das imagens e respetivas anotações, conversão de formatos, redimensionamento, augmentação e organização final em conjuntos de treino, validação e teste. Na segunda fase, o _notebook_ `YOLO.ipynb` realiza o treino do modelo de deteção, a validação durante o processo e a comparação final de desempenho.

== Preparação de dados

A preparação dos dados parte dos conjuntos já anotados no formato YOLO, as imagens sintéticas, anotadas automaticamente pelos _scripts_ descritos em @pos_process1 e na Rotina 2, e as imagens reais, anotadas no Roboflow. Sobre estes conjuntos, o _notebook_ `DataPreparation.ipynb` aplica o redimensionamento, a augmentação e a divisão dos dados descritos nas secções seguintes.

== Redimensionamento das imagens

Todas as imagens foram redimensionadas para a resolução de 640 × 640 píxeis, tamanho de entrada padrão dos modelos YOLO. Para o efeito, implementou-se a função `safe_crop_to_fill()`, que aplica uma estratégia de _crop-to-fill_. Em vez de adicionar barras pretas (_padding_), distorcer a imagem (_stretching_) ou reduzir a área útil (_letterboxing_), esta função garante que a imagem resultante é totalmente preenchida com conteúdo real.

Primeiro, a imagem é escalada para que o seu lado mais curto meça exatamente 640 píxeis, garantindo a cobertura total da área. Em seguida, calcula-se a região que engloba todas as _bounding boxes_ presentes, com uma margem de segurança de 10 píxeis, e determina-se o recorte centrado nessa mesma região (na horizontal, para imagens mais largas, ou na vertical, para imagens mais altas). O recorte final é então aplicado em simultâneo à imagem e às _bounding boxes_, sendo estas recalculadas para o novo referencial de 640 × 640 píxeis. Deste modo, os objetos anotados permanecem sempre dentro do enquadramento, sem sofrerem distorções e evitando o uso de preenchimentos não representativos.

== Augmentação e normalização

A augmentação de dados é aplicada exclusivamente às imagens do conjunto de treino. Por cada imagem original são geradas três cópias augmentadas que, em conjunto com a versão base inalterada, resultam num fator de expansão de 4× sobre os dados de treino. Este processo recorre à _API_ `torchvision.transforms.v2`, que é _bbox-aware_: ao submeter a imagem e as respetivas _bounding boxes_ à transformação, ambas são ajustadas de forma automática e consistente, dispensando o recálculo manual de coordenadas.

A _pipeline_ de augmentação inclui as seguintes transformações, todas com uma probabilidade de aplicação de 0,5:

- _RandomHorizontalFlip_: espelhamento horizontal, garantindo que o modelo aprende a detetar a sapatilha independentemente da sua orientação lateral.

- _RandomAffine_: rotação aleatória até ±10°, combinada com um _zoom_ fixo de 1,2×. Este _zoom_ é essencial para eliminar os cantos pretos resultantes da rotação, assegurando que o espaço de saída permanece preenchido.

- _ColorJitter_: variação de brilho, contraste e saturação, com o objetivo de simular diversas condições de iluminação e temperaturas de cor.

- _GaussianBlur_: desfocagem suave utilizando um _kernel_ de 3 × 3, simulando desfocagem por movimento ou imprecisão na focagem da câmara.

- _GaussianNoise_: adição de ruído gaussiano com um desvio padrão de 0,04, reproduzindo o grão característico dos sensores fotográficos.

No que diz respeito à normalização, optou-se por não alterar os valores dos píxeis durante a preparação dos dados, mantendo-os no intervalo original de [0, 255]. Esta é uma decisão intencional, uma vez que a _framework_ Ultralytics YOLO realiza a sua própria normalização interna durante o treino, dividindo os valores por 255,0 para os converter para o intervalo [0, 1]. Já as coordenadas das anotações são diretamente convertidas e armazenadas no formato normalizado do YOLO, em que cada valor se situa no intervalo [0, 1], proporcionalmente às dimensões da imagem.

== Divisão do _dataset_

A divisão dos dados em conjuntos de treino, validação e teste é feita com `sklearn.model_selection.train_test_split`, com `random_state=42` para garantir reprodutibilidade.

Os quatro cenários de imagens sintéticas (`Scenario_1`, `Outside_1`, `Outside_2` e `Cafe_1`) são divididos individualmente em 80% para treino e 20% para validação, sem conjunto de teste, sendo depois agregados num único _dataset_ denominado `Final`. O _dataset_ de imagens reais é dividido em 70% para treino, 15% para validação e 15% para teste.

A ausência de conjunto de teste nos dados sintéticos é intencional: o objetivo é que ambos os modelos, o treinado com dados sintéticos e o treinado com dados reais, sejam avaliados contra o mesmo conjunto de teste real, assegurando uma comparação justa e controlada.

== Configuração de treino

Para isolar o efeito da origem dos dados, ambos os modelos foram treinados com uma configuração idêntica, constituindo o conjunto de dados de origem (sintético ou real) a única variável em estudo. A @tab_config resume os principais parâmetros de treino.

#figure(
  table(
    columns: (auto, auto),
    align: (left, left),
    table.hline(),
    table.header([*Parâmetro*], [*Valor*]),
    table.hline(),
    [Arquitetura], [YOLO26n (≈ 2,5 M parâmetros · 5,8 GFLOPs)],
    [Épocas], [100, com _early stopping_ (_patience_ 20)],
    [Otimizador], [AdamW (automático) · _lr_ ≈ 0,002 · _batch_ 16],
    [Tamanho de imagem], [640 × 640],
    [_Hardware_], [GPU NVIDIA RTX 5070 Ti (CUDA)],
    table.hline(),
  ),
  caption: [Configuração de treino, idêntica para ambos os modelos.],
) <tab_config>


#pagebreak()

= Comparação dos resultados <sec_comparacao>

== Síntese dos dados recolhidos e dos resultados

Concluídas as etapas de geração de dados, treino e avaliação, sintetizam-se nesta secção os elementos que sustentam a comparação entre as duas abordagens, antes de proceder à sua discussão.

Foram constituídos dois conjuntos de dados independentes. O _dataset_ sintético, gerado integralmente em Unreal Engine com anotação automática, era composto por 1257 imagens originais. Destas, apenas 224 provieram da Rotina 1 (de posicionamento e rotação manual); as restantes, cerca de 1033, resultaram do _loop_ autónomo da Rotina 2, que permitiu produzir centenas de imagens por hora sem supervisão. O conjunto sintético foi posteriormente expandido para 4016 imagens de treino e 253 de validação após a aplicação de aumentos de dados (_data augmentation_). O _dataset_ real, composto por fotografias do objeto anotadas manualmente, partiu de 129 imagens originais, das quais resultaram 360 imagens de treino, 19 de validação e 20 de teste, igualmente após aumentos. Note-se que o conjunto de teste real, constituído por fotografias reais nunca vistas por nenhum dos modelos durante o treino, é único e comum a ambos, constituindo a base sobre a qual assenta a comparação final.

A partir destes conjuntos foram treinados dois detetores YOLO26n independentes, designados Modelo A (treinado exclusivamente com dados sintéticos) e Modelo B (treinado com dados reais).

== Curvas de treino e convergência

As @fig_curvas_a e @fig_curvas_b apresentam a evolução das funções de perda (_box_, _cls_ e _dfl_, em treino e validação) e das métricas de deteção (_precision_, _recall_, mAP\@50 e mAP\@50-95) ao longo das 100 épocas de treino de cada modelo.

O Modelo A (sintético) exibe uma convergência estável e regular: as curvas de perda decrescem de forma monótona e as métricas de validação sobem suavemente até estabilizarem, refletindo a abundância e a homogeneidade do conjunto de dados sintético. O Modelo B (real), pelo contrário, apresenta curvas visivelmente mais ruidosas, com oscilações acentuadas nas métricas de validação, comportamento consistente com a reduzida dimensão do seu conjunto de validação (19 imagens), em que cada exemplo tem um peso elevado na métrica agregada.

#figure(
  pad(x: -1cm,
  image("Imagens/Resultados/MODELOA_results.png", width: 100%)),
  caption: [Curvas de treino e validação do Modelo A (sintético) ao longo de 100 épocas.],
) <fig_curvas_a>

#figure(
  pad(x: -1cm,
  image("Imagens/Resultados/MODELOB_results.png", width: 100%)),
  caption: [Curvas de treino e validação do Modelo B (real) ao longo de 100 épocas.],
) <fig_curvas_b>

== Resultados qualitativos

A @fig_qualitativo apresenta uma comparação qualitativa das deteções produzidas por ambos os modelos sobre o conjunto de teste real. Em cada par de imagens são visíveis as caixas delimitadoras previstas, acompanhadas do respetivo grau de confiança.

Da análise visual destaca-se que o Modelo A, treinado exclusivamente com imagens sintéticas, produz deteções com graus de confiança globalmente superiores aos do Modelo B em grande parte dos casos, mantendo a deteção correta do objeto em condições variadas de iluminação, fundo e oclusão parcial. O Modelo B, embora detete corretamente o objeto na maioria das imagens, apresenta com maior frequência graus de confiança mais baixos, comportamento consistente com o reduzido volume de dados reais disponível para o seu treino.

#figure(

  pad(x: -2cm,
  grid(
    columns: 2,
    gutter: 6pt,
    image("Imagens/Resultados/MODELOA_val_batch0_pred.jpg"),
    image("Imagens/Resultados/MODELOB_val_batch0_pred.jpg"),
  )),
  caption: [Comparação qualitativa das deteções sobre o conjunto de teste real: Modelo A --- sintético (esq.) e Modelo B --- real (dir.).],
)  <fig_qualitativo>

== Tabelas comparativas

A @tab_validacao resume as métricas obtidas na validação de cada modelo sobre o respetivo conjunto de validação. Importa sublinhar que estes valores não são diretamente comparáveis entre si, uma vez que cada modelo é avaliado sobre um domínio distinto (sintético, para o Modelo A; real, para o Modelo B); servem, antes, para aferir a qualidade da aprendizagem de cada modelo no seu próprio domínio.

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, center, center),
    table.hline(),
    table.header(
      [*Métrica*], [*Modelo A (val. sintética)*], [*Modelo B (val. real)*],
    ),
    table.hline(),
    [mAP\@50],    [0,950], [0,934],
    [mAP\@50-95], [0,771], [0,660],
    [_Precision_], [0,970], [1,000],
    [_Recall_],    [0,882], [0,882],
    table.hline(),
  ),
  caption: [Métricas de validação de cada modelo sobre o respetivo conjunto de validação (domínios distintos, não diretamente comparáveis).],
) <tab_validacao>

A @tab_teste apresenta a avaliação de ambos os modelos sobre o conjunto de teste real comum, constituindo esta a comparação central do estudo. A última coluna indica a diferença entre os dois modelos, em pontos percentuais (p.p.).

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, center, center, center),
    table.hline(),
    table.header(
      [*Métrica*], [*Modelo A --- sintético*], [*Modelo B --- real*], [*$Delta$ (p.p.)*],
    ),
    table.hline(),
    [_Precision_],  [86,8], [79,5], [#text(green)[+7,3]],
    [_Recall_],     [78,9], [73,7], [#text(green)[+5,2]],
    [mAP\@50-95],   [56,5], [51,6], [#text(green)[+4,9]],
    [mAP\@50],      [77,9], [83,1], [#text(red)[−5,2]],
    table.hline(),
  ),
  caption: [Avaliação de ambos os modelos sobre o conjunto de teste real comum. $Delta$ = Modelo A − Modelo B.],
) <tab_teste>

== Discussão

Os resultados sobre o conjunto de teste real demonstram a eficácia do Modelo A. Treinado exclusivamente com imagens sintéticas, sem nunca ter observado uma única fotografia real durante o treino, este modelo iguala ou supera o Modelo B em três das quatro métricas avaliadas, registando ganhos de 7,3 p.p. em _precision_, 5,2 p.p. em _recall_ e 4,9 p.p. em mAP\@50-95. O Modelo B apenas supera o Modelo A na métrica mAP\@50, por uma margem de 5,2 p.p.

Este resultado sustenta a hipótese central do trabalho: para o objeto em estudo, é possível treinar um detetor funcional em ambiente real recorrendo exclusivamente a dados sintéticos, sem que a transição do domínio virtual para o domínio real degrade significativamente o desempenho da deteção.

A vantagem do Modelo A nas métricas de _precision_ e _recall_, bem como na métrica mAP\@50-95 sugere que a abordagem sintética beneficiou da maior diversidade e do maior volume de dados de treino que a geração automática permitiu obter. A superioridade do Modelo B na métrica mAP\@50, por seu lado, indica que este mantém uma boa capacidade de localização a limiares de IoU menos exigentes, ainda que com menor consistência nos limiares mais elevados.

== Limitações

Estes resultados devem, ainda assim, ser lidos com algumas reservas. A limitação mais relevante é o desequilíbrio de volume entre os dois conjuntos: o número de imagens reais foi substancialmente inferior ao de imagens sintéticas, o que pode ter limitado o desempenho do Modelo B e introduzido um risco de sobreajuste (_overfitting_), agravado pela reduzida dimensão do seu conjunto de validação (19 imagens). A comparação não mede, assim, a qualidade intrínseca de cada fonte de dados, mas antes a viabilidade da abordagem sintética. A esta limitação soma-se a dimensão reduzida do conjunto de teste real, com apenas 20 imagens, que confere uma variabilidade estatística considerável às métricas reportadas. Há ainda a ter em conta o realismo do processo de renderização, nomeadamente ao nível dos materiais e da iluminação, fator determinante na qualidade da transferência do domínio sintético para o real e que condiciona os resultados obtidos.

= Conclusões <sec_conclusoes>

Este trabalho propôs-se avaliar a viabilidade da utilização de dados puramente sintéticos no treino de modelos de deteção de objetos aplicáveis ao mundo real. Dos resultados obtidos retiram-se três conclusões principais.

Em primeiro lugar, os dados sintéticos demonstraram-se eficazes. Um detetor treinado integralmente com imagens geradas em Unreal Engine alcançou, sobre um conjunto de teste real, um desempenho comparável ao de um detetor treinado com fotografias reais, superando-o em três das quatro métricas avaliadas. Para o objeto em estudo, a transição do domínio virtual para o domínio real não degradou de forma significativa a capacidade de deteção.

Em segundo lugar, a anotação automática revelou-se um fator decisivo. O _pipeline_ de geração de máscaras e de extração de caixas delimitadoras eliminou por completo a necessidade de rotulagem manual das imagens sintéticas, tornando o _dataset_ escalável e permitindo a produção de grandes volumes de dados anotados a um custo reduzido.

Em terceiro lugar, a automatização do posicionamento do objeto e da câmara, em conjunto com o ciclo de captura autónomo, aumentou substancialmente a velocidade de produção das imagens sintéticas, permitindo a recolha de centenas de imagens por hora sem qualquer intervenção manual.

Globalmente, estes resultados confirmam os dois pontos que o trabalho se propôs validar: a possibilidade de treinar modelos de deteção de objetos reais a partir de imagens sintéticas e a possibilidade de o fazer de forma automatizada, rápida e a uma fração do custo associado à recolha e anotação de imagens reais equivalentes.

= Trabalho futuro <sec_futuro>

Os resultados obtidos, embora promissores, abrem caminho a diversos desenvolvimentos futuros que permitiriam consolidar e aprofundar as conclusões deste trabalho.

Uma direção natural seria realizar uma comparação controlada pelo volume de dados, subamostrando o conjunto sintético de modo a igualar a dimensão do conjunto real. Tal permitiria isolar o efeito da origem dos dados do efeito do seu volume, viabilizando uma comparação mais justa entre as duas abordagens. Seria igualmente útil constituir um conjunto de teste real de maior dimensão e diversidade, o que reforçaria a robustez estatística da avaliação e reduziria a variabilidade associada ao reduzido número de imagens atualmente utilizado.

Haveria ainda margem para aplicar técnicas adicionais de _domain randomization_ no Unreal Engine, introduzindo maior variabilidade ao nível das texturas, da iluminação e dos cenários. Tal poderia melhorar a capacidade de generalização dos modelos treinados sinteticamente, aproximando o domínio sintético da diversidade encontrada em ambiente real e potenciando a qualidade da transferência para o mundo real.
