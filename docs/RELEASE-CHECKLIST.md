# RELEASE-CHECKLIST v1.0-mvp1

- [x] Actions `ios-build` verde (47 Swift tests, inclui import USDZ SceneKit + app build para iOS Simulator SDK; runner sem CoreSimulator)
- [x] Actions `assets-validate` verde (0 ERROR blend + catalog 495 itens)
- [ ] 3 shells trocáveis sem reload (BED/KIT/LIV)
- [x] 495 itens no catálogo/pack; 495 USDZ válidos; 15 categorias com ≥4 opções por sala
- [ ] App carrega os USDZ do bundle no runtime de Simulator/device (SceneKit import test já passa no host Mac)
- [ ] Save/load após kill (`polyroom_save_v1.json`, <100ms)
- [ ] Modo avião 100% funcional, sem `URLSession`
- [ ] FPS: 60 iPhone 12 / 30 SE2, cena <50k tris
- [ ] Snapshot PNG + share local
- [ ] Onboarding 3 passos + Sobre com "Baseado em Low-poly rooms por javiloz1604 (BlendSwap 24957), CC-BY"
- [x] Ícone 1024 RGB final, launch color asset, portrait, iOS 17+
- [ ] Ajustar versão/build para 1.0(1) antes de Archive
- [ ] Sem crash em 15min monkey + save corrupto recupera com save vazio
