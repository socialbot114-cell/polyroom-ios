# GDD 1-página — Polyroom MVP

## Pilares
Cozy, sem fail-state, sem timer, sem ads. Tocar e decorar é o prêmio.

## Loop (30-120s)
Escolher quarto (quarto/cozinha/sala) -> buscar/filtrar categoria -> tocar item -> aparece no centro -> arrastar no grid / mover por controle / girar 45° / paleta recolorir / duplicar / excluir -> autosave -> snapshot PNG local. Missões e sons leves reforçam ações sem pressão ou timer.

## Câmera
Isométrica fofa: ortho ~35°, orbit 1-dedo yaw ±60° + pitch 30-60°, pinch zoom 0.7-1.8x, double-tap reset. Sombra suave baked + 1 directional realtime.

## Conteúdo
Baseline MVP-1 congelado: 45 SKUs em 3 quartos × 6 categorias. Catálogo atual de conteúdo: 495 itens, 15 categorias (`moveis`, `acessorios`, `sub_itens`, `iluminacao`, `texteis`, `plantas`, `eletronicos`, `arte`, `kids`, `piso`, `cama_mesa`, `pets`, `office`, `eletrodomesticos`, `parede`). Cada sala tem pelo menos 4 opções em cada categoria.
- quarto: cama, criado, guarda-roupa, tapete, quadro, abajur, livros, almofada, vaso, planta
- cozinha: bancada, armário, geladeira, fogão, mesa, 2 cadeiras, panela, pratos, frutas, pendente
- sala: sofá, rack, TV, estante, mesa centro, tapete redondo, quadro, luminária chão, almofada, planta grande
Todos os itens do catálogo têm GLB + USDZ + thumbnail real 256px e footprint (S/M/L), tintable bool, tags e snap grid 0.25m. O carregamento e a escala no app ainda precisam de verificação em runtime.

## Progressão cozy (sem servidor)
- Moedas locais `cozyCoins` ganhas ao colocar itens, salvar fotos e completar 12 missões (`docs/MISSOES.md`). Claims de missão são 1x; progresso e recompensas ficam em `UserDefaults`, offline.
- Desbloqueio: 2º e 3º quarto liberados com 20 e 50 coins iniciais para testar variedade rápido no MVP.

## UX
- Catálogo bottom-sheet com busca (nome/id/tags, sem acento), filtro de sala/categoria e thumb 64px
- Inspector flutuante: mover / girar 45° / cor (6 swatches) / duplicar / excluir
- Folha de missões com progresso/recompensa; sons offline com toggle
- Onboarding 3 cards, tela Sobre com créditos CC-BY, modo avião 100% funcional

## Aceite de release
- 3 shells trocáveis sem reload, 495 itens no catálogo, save/load após kill, 60fps iPhone 12 / 30fps SE2, Swift Package tests + Actions verde, validação de assets verde.
- Bloqueios antes do ship: verificar modelos USDZ em runtime, Archive/versionamento, teste de device/FPS e TestFlight.
