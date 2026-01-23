
---

# Simulação de Condicionamento Operante: Agente Adaptativo em Caixa de Skinner 3D

Este projeto apresenta um simulador 3D de uma **Caixa de Skinner**, desenvolvido na **Godot Engine**, onde um agente autônomo (rato virtual) aprende e extingue comportamentos através de um algoritmo de **Aprendizagem por Reforço (Q-Learning)**. O objetivo é oferecer uma alternativa pedagógica moderna para o ensino de Análise Experimental do Comportamento (AEC), alinhando-se às restrições legais de uso de animais em atividades didáticas (Lei Arouca).

---

## 📺 Demonstração do Projeto

> [!TIP]
> **[ESPAÇO PARA VÍDEO OU GIF DO RATO APRENDENDO]**
> *Sugestão: Coloque um GIF mostrando a fase de Modelagem, onde o rato começa a se aproximar da barra.*

---

## 🚀 Funcionalidades Principais

* 
**Cérebro Evolutivo:** Diferente de simuladores legados, o comportamento do agente não é pré-programado; ele emerge dinamicamente através de interações com o ambiente.


* 
**Protocolo Experimental Completo:** Implementação de quatro fases fundamentais da AEC: Linha de Base, Treino ao Comedouro, Modelagem e Extinção.


* 
**Visualização de Dados em Tempo Real:** Gráficos e indicadores de interface que permitem observar os valores da **Tabela-Q** e a probabilidade de exploração/explotação do agente.


* 
**Persistência de Aprendizado:** O conhecimento adquirido pelo agente é salvo e carregado em formato JSON, permitindo a continuidade do experimento entre sessões.



---

## 🛠️ Arquitetura Técnica

O sistema foi projetado de forma modular para separar a lógica de decisão da execução física:

### 1. O Cérebro (`RLAgent.gd`)

Implementa o algoritmo **Q-Learning** puro.

* 
**Equação de Bellman:** Utilizada para atualizar o valor de utilidade de cada ação baseada na recompensa e expectativa futura.


* 
**Política -greedy:** Equilibra a curiosidade (exploração) e o uso do que já foi aprendido (explotação).



### 2. O Controlador (`personagem.gd`)

Responsável pela ponte entre o cérebro e o ambiente.

* 
**Percepção:** Traduz estímulos (proximidade da barra, presença de comida) em estados discretos.


* 
**Navegação e Animação:** Gerencia o sistema de `NavigationAgent3D` e a `AnimationTree` para uma movimentação fluida e natural.



---

## 🧪 O Experimento

O aprendizado é guiado por um protocolo de quatro fases:

1. 
**Linha de Base:** Observação e registro da frequência natural de comportamentos do agente sem intervenção.


2. 
**Treino ao Comedouro:** O usuário ensina ao agente que o som do comedouro indica disponibilidade de alimento.


3. 
**Modelagem (Shaping):** Reforçamento de aproximações sucessivas (olhar, aproximar, tocar) até que a pressão na barra seja aprendida de forma autônoma.


4. 
**Extinção:** Suspensão do reforço para observar a diminuição gradual da resposta aprendida.



---

## 📸 Capturas de Tela

<div align="center">
<img src="[https://via.placeholder.com/400x225.png?text=Ambiente+3D+da+Caixa](https://www.google.com/search?q=https://via.placeholder.com/400x225.png%3Ftext%3DAmbiente%2B3D%2Bda%2BCaixa)" width="45%" />
<img src="[https://via.placeholder.com/400x225.png?text=Gráficos+de+Aprendizado](https://www.google.com/search?q=https://via.placeholder.com/400x225.png%3Ftext%3DGr%C3%A1ficos%2Bde%2BAprendizado)" width="45%" />
<p><em>Legenda: Visualização do ambiente 3D e interface de acompanhamento estatístico.</em></p>
</div>

---

## 💻 Como Executar

1. Faça o download da **Godot Engine 4.4.1** ou superior.


2. Clone este repositório:
```bash
git clone https://github.com/seu-usuario/projeto-skinner-3d.git

```


3. Abra o arquivo `project.godot` no editor da Godot.
4. Pressione `F5` para iniciar a simulação.

---

## 👥 Autores

* 
**Osni Junior dos Santos** - *Mestrado em Ensino de Ciência e Tecnologia & Ciência da Computação - UTFPR/PG*.


* 
**Luiz Guilherme Monteiro Padilha** - *UTFPR/PG*.


* 
**Simone Bello Kaminski Aires** - *UTFPR/PG*.


* 
**Eloiza Aparecida Silva Avila de Matos** - *UTFPR/PG*.



---

## 📚 Referências Principais

* SKINNER, B. F. **Sobre o behaviorismo**. São Paulo: Cultrix, 1974.


* BRASIL. **Lei nº 11.794 (Lei Arouca)**, 8 de out. 2008.


* SANTOS, O. J. et al. **O Desenvolvimento de Simuladores Virtuais para o Ensino de AEC**, 2024.



---

