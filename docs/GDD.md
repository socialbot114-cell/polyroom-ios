# GDD 1-página — Polyroom MVP

## Pilares
Cozy, sem fail-state, sem timer, sem ads. Tocar e decorar é o prêmio.

## Loop (30-120s)
Escolher quarto (Bed/Kit/Liv) -> aba categoria -> tap item -> aparece no centro -> arrastar mover / handle girar / paleta recolorir / lixeira excluir -> autosave -> botão câmera snapshot PNG local.

## Câmera
Isométrica fofa: ortho ~35°, orbit 1-dedo yaw ±60° + pitch 30-60°, pinch zoom 0.7-1.8x, double-tap reset. Sombra suave baked + 1 directional realtime.

## Conteúdo MVP-1 (3 quartos x 6 categorias)
Categorias: `moveis`, `acessorios`, `sub_itens`, `iluminacao`, `texteis`, `plantas`
- quarto: cama, criado, guarda-roupa, tapete, quadro, abajur, livros, almofada, vaso, planta
- cozinha: bancada, armário, geladeira, fogão, mesa, 2 cadeiras, panela, pratos, frutas, pendente
- sala: sofá, rack, TV, estante, mesa centro, tapete redondo, quadro, luminária chão, almofada, planta grande
Total alvo: 45 SKUs compartilháveis. Cada item: footprint (S/M/L), tintable bool, snap grid 0.25m.

## Progressão cozy (sem servidor)
- Moedas locais `cozyCoins` ganhas por: completar checklist quarto (ex "colocar 5 moveis"), tirar 3 fotos, abrir app 3 dias. Tudo `UserDefaults`, anti-cheat irrelevante.
- Desbloqueio: 2º e 3º quarto liberados com 20 e 50 coins iniciais para testar variedade rápido no MVP.

## UX
- Catálogo bottom-sheet com busca + filtro categoria, cards com thumb 64px
- Inspector flutuante: mover / girar 45° / cor (6 swatches) / duplicar / excluir
- Onboarding 3 cards, tela Sobre com créditos CC-BY, modo avião 100% funcional

## Aceite MVP-1
- 3 shells trocáveis sem reload, 45 itens colocáveis, save/load após kill, 60fps iPhone 12 / 30fps SE2, build Actions verde, validação blend verde.
