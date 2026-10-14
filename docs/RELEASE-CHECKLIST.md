# RELEASE-CHECKLIST v1.0-mvp1

- [x] Actions `ios-build` verde (Swift Package: 46 testes, 0 falhas; app target aguarda `.xcodeproj`)
- [x] Actions `assets-validate` verde (0 ERROR blend + catalog 495 itens)
- [ ] 3 shells trocáveis sem reload (BED/KIT/LIV)
- [ ] 495 itens no catálogo/pack; USDZ convertido e carregado no app; 15 categorias com ≥4 opções por sala
- [ ] Save/load após kill (`polyroom_save_v1.json`, <100ms)
- [ ] Modo avião 100% funcional, sem `URLSession`
- [ ] FPS: 60 iPhone 12 / 30 SE2, cena <50k tris
- [ ] Snapshot PNG + share local
- [ ] Onboarding 3 passos + Sobre com "Baseado em Low-poly rooms por javiloz1604 (BlendSwap 24957), CC-BY"
- [ ] Ícone 1024, splash, version 1.0(1), portrait, iOS 17+
- [ ] Sem crash em 15min monkey + save corrupto recupera com save vazio
