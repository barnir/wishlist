# Agents.md — Wishlist Flutter App

Este arquivo guia agentes automáticos e colaboradores rápidos sobre como trabalhar neste repositório com segurança e eficiência.

Objetivo resumido
- Aplicação Flutter (Android only) com Firebase backend e Cloudinary. Agentes devem produzir mudanças pequenas e testáveis, nunca expor segredos, e seguir as convenções do projeto (l10n, theming, serviços).

Prioridade de descoberta (ordem mínima)
1. `pubspec.yaml` — confirmar SDK e dependências.
2. `README.md` — visão geral, comandos essenciais e variáveis de ambiente.
3. `lib/main.dart` — inicialização (dotenv, Firebase, l10n, temas).
4. `lib/config.dart`, `lib/theme.dart`, `lib/theme_extensions.dart` — configuração e semântica de cores.
5. `lib/models/*.dart` — domain models e serialização (`fromMap`/`toMap`).
6. `lib/services/` e `lib/repositories/` — lógica de negócio e integrações (Cloudinary, Auth, Functions wrapper).
7. `lib/widgets/` e `lib/screens/` — UI; mantenha widgets pequenos e delegue I/O a services.
8. `functions/` — backend TS (secureScraper + aggregate triggers).
9. `l10n.yaml` e `lib/l10n/*.arb` — localization sources; `lib/generated/l10n/` é gerado (não editar).

Regras essenciais (resumidas)
- Plataforma: Android somente — NÃO sugerir ou executar builds para web/iOS.
- Secrets: nunca comitar `.env`, `android/key.properties`, `google-services.json`, service account JSON, tokens; use GitHub Secrets/CI for sensitive values.
- L10n: todo texto de UI deve usar `AppLocalizations` (adicionar chaves PT+EN aos ARB ao introduzir strings novas).
- Imagens: use `cloudinary_service.dart` e `FastCloudinaryImage`/`OptimizedCloudinaryImage` — nunca montar URLs manualmente.

Comandos e snippets úteis (Windows / PowerShell)
```powershell
# instalar deps
flutter pub get

# analisar código (requer 0 issues)
flutter analyze --no-fatal-infos

# rodar testes
flutter test

# build release APK
flutter build apk --release

# build AAB (assinado: precisa android/key.properties)
flutter build appbundle --release

# functions
cd functions
npm install
npm run build
firebase deploy --only functions --project <PROJECT_ID>

# distribuir via App Distribution (script usa firebase.json)
cmd.exe /c scripts\deploy_beta.bat
```

Deploy, CI e secrets
- `scripts/deploy_beta.bat` agora lê `firebase.json` para `app` e `groups`; confirme `firebase.json:app` antes de executar.
- GitHub Actions: use secrets listadas em `scripts/README_DEPLOY.md` (`KEYSTORE_BASE64`, `FIREBASE_TOKEN`, etc.).
- Nunca colocar service account JSON em repositório; se preciso para CI armazene como secret e carregue no workflow.

PR / Commit checklist (obrigatório)
1. Código compilável e testado localmente (se aplicável).
2. `flutter analyze` passa com 0 issues.
3. Adição de strings: incluir chaves em `lib/l10n/app_en.arb` e `lib/l10n/app_pt.arb` e documentar regeneração do l10n.
4. Atualizar `session-notes.md` com um resumo curto da sessão/delta.
5. Não adicione segredos; documente se novos secrets/CI variables são necessários.

PR message template sugerida
```
feat(<area>): <curta descrição>

Summary:
- what changed

Validation:
- flutter analyze (0 issues)
- tests: <list>

Notes:
- any CI/secret changes required
```

Checks e validações automáticas que um agente pode executar
- `flutter analyze` — falhar se houver issues.
- `flutter test` — rodar testes rápidos relevantes.
- Verificar alterações de l10n (buscar novas chaves ARB em PT e EN).
- Confirmar que `firebase.json` tem `app` correto antes de rodar deploy script.

Segurança e privacidade (política curta)
- Se encontrar credencial no repo, não a exponha; avise e sugira rotacionar a credential imediatamente.
- Logs contendo secrets devem ser truncados ou removidos antes de anexar a PR.

Operações comuns e notas de troubleshooting
- Se `firebase appdistribution:distribute` falhar com "Precondition check failed", confirmar que o `--app` corresponde a um app existente no projeto (`firebase apps:list`) e que o token de CLI está válido.
- Testes que dependem de `.env` devem usar `dotenv.load(mergeWith:{...})` ou carregar variáveis em memória em vez de depender de arquivos commitados.
- Para builds assinados em CI: use `KEYSTORE_BASE64` secret, decode para `android/app/release.keystore` no workflow e aponte `android/key.properties` com valores seguros.

Adição de novos serviços / features (fluxo recomendado)
1. Procurar por um serviço existente que cubra o problema. Reuse antes de criar novo serviço.
2. Adicionar model + `fromMap`/`toMap` + testes unitários de serialização.
3. Adicionar métodos ao serviço/repository apropriado.
4. Atualizar telas para chamar o serviço (mantendo telas leves).
5. Adicionar l10n keys e atualizar testes/widget tests.

Referências internas
- Guia operacional: `AGENTS.md` (este arquivo)
- Índice de documentação: `docs/README.md`
- Resumo de melhorias: `docs/IMPROVEMENTS_OVERVIEW.md`
- Scripts de deploy: `scripts/deploy_local.ps1`, `scripts/deploy_beta.bat`
- Docs gerais: `docs/`

----
Arquivo adaptado e enriquecido para uso prático por agentes e colaboradores humanos.
