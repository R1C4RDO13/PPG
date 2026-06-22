# PPG — Deteção de Sapatilhas com YOLO

Projeto de visão computacional para deteção de sapatilhas em imagens sintéticas (Unreal Engine) e reais, utilizando modelos YOLO treinados com dados gerados por renderização 3D e fotografias reais.

---

## Índice

- [Visão Geral](#visão-geral)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Pipeline de Trabalho](#pipeline-de-trabalho)
- [Scripts Python](#scripts-python)
- [Notebooks Jupyter](#notebooks-jupyter)
- [Datasets](#datasets)
- [Modelos 3D (Unreal Engine)](#modelos-3d-unreal-engine)
- [Treino e Resultados](#treino-e-resultados)
- [Configuração do Ambiente](#configuração-do-ambiente)
- [Utilização](#utilização)

---

## Visão Geral

Este projeto explora a criação de um pipeline completo de deteção de objetos usando dados sintéticos gerados no Unreal Engine combinados com imagens reais. O objeto de deteção são sapatilhas, e o modelo treinado é o **YOLO26n** (variante nano do YOLO).

**Principais características:**
- Geração de dados sintéticos com Unreal Engine usando masks RGB duplas (RED/BLUE) para lidar com oclusão
- Filtragem inteligente de amostras com base em visibilidade (rácio entre a área visível e a área total do objeto)
- Treino com dados sintéticos e reais combinados
- Avaliação com métricas completas (PR curves, confusion matrix, mAP)

---

## Estrutura do Projeto

```
PPG/
├── ImagesIngest.py            # Preparação do dataset para formato YOLO
├── mask_to_yolo.py            # Conversão de masks do Unreal para labels YOLO
├── prepare_dataset.py         # Filtragem por visibilidade e geração de labels
│
├── DataPreparation.ipynb      # Notebook de exploração e preparação de dados
├── MaskPrepararion.ipynb      # Notebook de processamento de masks
├── YOLO.ipynb                 # Notebook de treino, validação e inferência YOLO
│
├── yolo26n.pt                 # Pesos pré-treinados do modelo YOLO26n
│
├── Datasets/
│   ├── Original/              # Dados brutos (imagens + labels por cenário)
│   │   ├── Cafe_1/
│   │   ├── Outside_1/
│   │   ├── Outside_2/
│   │   ├── Scenario_1/
│   │   └── Real/
│   └── YOLO_Datasets/         # Datasets processados prontos para treino
│       ├── Final/             # Dataset aumentado (sintético)
│       │   ├── train/
│       │   ├── val/
│       │   └── test/
│       └── Real/              # Dataset de imagens reais
│           ├── train/
│           ├── val/
│           ├── test/
│           └── dataset.yaml
│
├── Models/
│   └── Sapatilha/             # Assets 3D do Unreal Engine (.uasset, .fbx)
│
├── runs/
│   └── detect/SHOE/           # Resultados dos treinos YOLO
│       ├── REAL/
│       ├── Synth/
│       └── val/
│
├── validacao/                 # Imagens de validação com predições sobrepostas
├── Report/                    # Relatório final do projeto (PDF + imagens)
└── .gitignore
```

---

## Pipeline de Trabalho

```
1. Aquisição de Imagens
   ├── Renderização 3D no Unreal Engine (dados sintéticos)
   └── Fotografias reais de sapatilhas

2. Geração de Masks (Unreal Engine)
   ├── Mask AZUL  → extensão total do objeto (incluindo partes ocultas)
   ├── Mask VERMELHA → porção visível do objeto
   └── Mask LARANJA → uso interno de labeling

3. Processamento de Masks
   ├── mask_to_yolo.py     → converte masks RGB para labels YOLO (.txt)
   └── prepare_dataset.py  → filtra amostras por visibilidade

4. Organização do Dataset
   ├── ImagesIngest.py     → divide em Train/Val/Test e gera dataset.yaml
   └── Datasets/YOLO_Datasets/{Final|Real}/

5. Treino do Modelo (YOLO.ipynb)
   ├── Carrega yolo26n.pt (pesos pré-treinados)
   ├── Treina nos datasets Final e Real
   ├── Valida nos splits de teste
   └── Gera métricas de avaliação

6. Validação e Resultados
   ├── Curvas Precision/Recall
   ├── Matrizes de confusão
   ├── Visualizações de predições
   └── Relatório final
```

---

## Scripts Python

### `mask_to_yolo.py`

Converte pares de imagens (imagem original + mask) gerados pelo Unreal Engine em labels no formato YOLO.

- Deteta pixels laranja (cor de mask padrão do Unreal)
- Lida com objetos fragmentados por oclusão (análise de componentes conexas)
- Filtra ruído abaixo de um tamanho mínimo de componente
- Gera bounding boxes a partir da extensão da mask

```bash
python mask_to_yolo.py
```

---

### `prepare_dataset.py`

Processa tríplices de imagens (original / mask RED / mask BLUE) com base num critério de visibilidade.

**Lógica de filtragem:**
| Visibilidade (red_area / blue_area) | Ação |
|---|---|
| < 20% | Label vazia (negativo difícil) |
| 20% – 60% | Amostra ignorada (ambígua) |
| > 60% | Label YOLO gerada a partir da mask RED |

```bash
python prepare_dataset.py
```

---

### `ImagesIngest.py`

Prepara imagens e labels brutos num dataset estruturado para YOLO.

- Redimensiona imagens para o tamanho alvo (padrão: 640×640)
- Divide em Train/Val/Test (padrão: 80/20/0)
- Gera o ficheiro `dataset.yaml`

```bash
python ImagesIngest.py \
  --ingest_dir Datasets/Original/Scenario_1 \
  --output_dir Datasets/YOLO_Datasets/Scenario_1 \
  --target_size 640 \
  --weights 80 20 0
```

---

## Notebooks Jupyter

| Notebook | Descrição |
|---|---|
| `DataPreparation.ipynb` | Exploração, estatísticas e validação do dataset |
| `MaskPrepararion.ipynb` | Processamento de masks RED/BLUE, cálculo de visibilidade e geração de labels |
| `YOLO.ipynb` | Treino, validação, inferência e visualização de resultados do modelo YOLO |

---

## Datasets

Os datasets principais encontram-se em `Datasets/` (~5.6 GB no total) e **não estão incluídos no repositório** (excluídos pelo `.gitignore`).

### Cenários sintéticos (Unreal Engine)
- `Cafe_1` — interior de café
- `Outside_1`, `Outside_2` — exteriores urbanos
- `Scenario_1` — cenário inicial de testes

### Dataset real
- `Real/` — fotografias reais de sapatilhas

### Datasets YOLO prontos para treino
- `YOLO_Datasets/Final/` — dataset sintético aumentado (HSV jitter, flip, erasing)
- `YOLO_Datasets/Real/` — dataset de imagens reais com `dataset.yaml`

---

## Modelos 3D (Unreal Engine)

A pasta `Models/Sapatilha/` contém os assets do Unreal Engine usados na renderização sintética:

| Asset | Descrição |
|---|---|
| `shoe1.uasset` | Mesh principal da sapatilha (~51 MB) |
| `3DModel_002.uasset` | Modelo 3D alternativo |
| `3DModel_002_BaseColor_0.uasset` | Textura base |
| `m_visaovermelha.uasset` | Material para mask vermelha (visão visível) |
| `m_visaoazul.uasset` | Material para mask azul (extensão total) |
| `BP_SHOE.uasset` | Blueprint do actor de sapatilha |
| `shoe.fbx` | Modelo exportado em FBX |

---

## Treino e Resultados

### Configuração de treino

| Parâmetro | Valor |
|---|---|
| Modelo | YOLO26n (nano) |
| Imagem de entrada | 640×640 |
| Épocas | 100 (early stopping: patience=20) |
| Batch size | 16 |
| Dispositivo | GPU (CUDA) |
| Otimizador | Auto (momentum: 0.937) |
| Learning rate inicial | 0.01 |
| Weight decay | 0.0005 |
| Augmentação | HSV jitter, scale=0.5, flip=0.5, erasing=0.4 |

### Resultados

Os resultados dos treinos encontram-se em `runs/detect/SHOE/`:
- `REAL/` — treino com imagens reais
- `Synth/` — treino com dados sintéticos
- `val/` — outputs de validação

Cada run inclui: `results.csv`, curvas PR, matrizes de confusão e pesos do melhor modelo (`best.pt`).

---

## Configuração do Ambiente

### Requisitos

- Python 3.10+
- GPU com suporte CUDA (recomendado)
- Unreal Engine 4/5 (para geração de dados sintéticos)

### Instalação

```bash
# Clonar o repositório
git clone <url-do-repositorio>
cd PPG

# Criar e ativar ambiente virtual
python -m venv .venv
.venv\Scripts\activate   # Windows
# source .venv/bin/activate  # Linux/Mac

# Instalar dependências
pip install ultralytics opencv-python numpy scipy pillow jupyter
```

### Dependências principais

| Biblioteca | Uso |
|---|---|
| `ultralytics` | Framework YOLO (treino, validação, inferência) |
| `opencv-python` | Processamento de imagens e masks |
| `numpy` / `scipy` | Operações numéricas e análise de componentes |
| `Pillow` | Leitura e escrita de imagens |
| `jupyter` | Execução dos notebooks |

---

## Utilização

### 1. Processar masks do Unreal Engine

```bash
python mask_to_yolo.py
```

### 2. Filtrar dataset por visibilidade

```bash
python prepare_dataset.py
```

### 3. Preparar splits de treino/validação

```bash
python ImagesIngest.py --ingest_dir Datasets/Original/Real --output_dir Datasets/YOLO_Datasets/Real
```

### 4. Treinar o modelo

Abrir e executar o notebook `YOLO.ipynb` ou usar a CLI do Ultralytics:

```bash
yolo train model=yolo26n.pt data=Datasets/YOLO_Datasets/Real/dataset.yaml epochs=100 imgsz=640 batch=16 device=0
```

### 5. Inferência

```bash
yolo detect predict model=runs/detect/SHOE/REAL/weights/best.pt source=<pasta-de-imagens> imgsz=640
```

---

## Relatório

O relatório final do projeto encontra-se em `Report/CG-Projeto_final.pdf` e inclui:
- Descrição da metodologia de geração de dados sintéticos
- Exemplos dos cenários (café, exterior urbano, natureza)
- Visualizações das masks RED/BLUE
- Análise dos resultados de treino e validação
- Referências bibliográficas
