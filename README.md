
---

# UT-RAT
## Simulação de Condicionamento Operante: Agente Adaptativo em Caixa de Skinner 3D

Este projeto apresenta um simulador 3D de uma **Caixa de Skinner**, desenvolvido na **Godot Engine**, onde um agente autônomo (rato virtual) aprende e extingue comportamentos através de um algoritmo de **Aprendizagem por Reforço (Q-Learning)**. O objetivo é oferecer uma alternativa pedagógica moderna para o ensino de Análise Experimental do Comportamento (AEC), alinhando-se às restrições legais de uso de animais em atividades didáticas (Lei Arouca).

---

## 📺 Demonstração do Projeto


> **![ExecuçãoGIF](https://github.com/user-attachments/assets/44ebb40f-0d0c-4033-b76f-c95dc9ee8872)**


---

## 🚀 Funcionalidades Principais

* **Cérebro Evolutivo:** Diferente de simuladores legados, o comportamento do agente não é pré-programado; ele emerge dinamicamente através de interações com o ambiente.


* **Protocolo Experimental Completo:** Implementação de quatro fases fundamentais da AEC: Linha de Base, Treino ao Comedouro, Modelagem e Extinção.


* **Visualização de Dados em Tempo Real:** Gráficos e indicadores de interface que permitem observar os valores da **Tabela-Q** e a probabilidade de exploração/explotação do agente.


* **Persistência de Aprendizado:** O conhecimento adquirido pelo agente é salvo e carregado em formato JSON, permitindo a continuidade do experimento entre sessões.



---

## 🛠️ Arquitetura Técnica

O sistema foi projetado de forma modular para separar a lógica de decisão da execução física:

### 1. O Cérebro (`RLAgent.gd`)

Implementa o algoritmo **Q-Learning** puro.

* **Equação de Bellman:** Utilizada para atualizar o valor de utilidade de cada ação baseada na recompensa e expectativa futura.


* **Política ε-greedy:** Equilibra a curiosidade (exploração) e o uso do que já foi aprendido (explotação).



### 2. O Controlador (`personagem.gd`)

Responsável pela ponte entre o cérebro e o ambiente.

* **Percepção:** Traduz estímulos (proximidade da barra, presença de comida) em estados discretos.


* **Navegação e Animação:** Gerencia o sistema de `NavigationAgent3D` e a `AnimationTree` para uma movimentação fluida e natural.



---

## 🧪 O Experimento

O aprendizado é guiado por um protocolo de quatro fases:

1. **Linha de Base:** Observação e registro da frequência natural de comportamentos do agente sem intervenção.


2. **Treino ao Comedouro:** O usuário ensina ao agente que o som do comedouro indica disponibilidade de alimento.


3. **Modelagem (Shaping):** Reforçamento de aproximações sucessivas (olhar, aproximar, tocar) até que a pressão na barra seja aprendida de forma autônoma.


4. **Extinção:** Suspensão do reforço para observar a diminuição gradual da resposta aprendida.





## 📸 Capturas de Tela

<div align="center">
<img width="612" height="226" alt="image" src="https://github.com/user-attachments/assets/67f31df4-841f-4b21-bf4c-8c2b879e4224" />
<p><em>Legenda: Visualização do modelo 3D  do rato.</em></p>
<img width="785" height="774" alt="image" src="https://github.com/user-attachments/assets/c96deae9-e1ff-40f0-ba5a-f387c7f91cb5" />
<p><em>Legenda: Visualização do ambiente 3D</em></p>
<img width="840" height="624" alt="image" src="https://github.com/user-attachments/assets/84b7800f-92c9-4d9e-b3fe-0aa92d959bca" />
<p><em>Legenda: Visualização do interface de explicação da teoria</em></p>
<img width="1330" height="480" alt="image" src="https://github.com/user-attachments/assets/479dea84-df82-4dc3-8883-d3d0b619fe80" />
<p><em>Legenda: Visualização do interface da fase de *Linha de Base*</em></p>
<img width="1323" height="549" alt="image" src="https://github.com/user-attachments/assets/38bfb94f-166c-492b-8ac2-7d65fc667866" />
<p><em>Legenda: Visualização do interface da fase de *Treino ao Comedouro*</em></p>
<img width="1344" height="542" alt="image" src="https://github.com/user-attachments/assets/b6bf24e1-29bb-446a-bb73-5676e1f6ed5f" />
<p><em>Legenda: Visualização do interface da fase de *Modelagem (Shaping)*</em></p>
<img width="1336" height="539" alt="image" src="https://github.com/user-attachments/assets/b41f63a3-8dcb-4229-b7ce-e502dba8f461" />
<p><em>Legenda: Visualização do interface da fase de *Extinção*</em></p>

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

* **Osni Junior dos Santos** - *Mestrado em Ensino de Ciência e Tecnologia & Ciência da Computação - UTFPR/PG*.


* **Luiz Guilherme Monteiro Padilha** - *Mestrando em Ciencia da Computação - PPGCC/UTFPR/PG*.


* **Simone Bello Kaminski Aires** - *UTFPR/PG*.


* **Eloiza Aparecida Silva Avila de Matos** - *UTFPR/PG*.
 


---

## 📚 Referências Principais

* SKINNER, B. F. **Sobre o behaviorismo**. São Paulo: Cultrix, 1974.


* BRASIL. **Lei nº 11.794 (Lei Arouca)**, 8 de out. 2008.


* SANTOS, O. J. et al. **O Desenvolvimento de Simuladores Virtuais para o Ensino de AEC**, 2024.



---
