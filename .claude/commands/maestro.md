Rode a suíte Maestro E2E local do NR Fácil, corrija o que quebrar e me dê um resumo enxuto.

> **Objetivo:** um comando só que sobe o que faltar (emulador, build, APK), roda os flows de `.maestro/flows/ci/`, e — se algo falhar — investiga, corrige e roda de novo até ficar verde. Funciona com ou sem emulador ligado, com o app fechado ou aberto.

Argumentos opcionais (`$ARGUMENTS`): caminho de um flow (`.maestro/flows/ci/01_leitura.yaml`), `--rebuild` ou `--avd <nome>`. Sem argumentos = smoke completo.

---

## Passos

### 1. Preparar o ambiente (sem perguntar)

- Se já houver device conectado (`adb devices`), siga em frente. Se não houver, o `scripts/maestro_dev.sh` sobe o primeiro AVD sozinho — não peça para o usuário abrir o emulador.
- Se o app estiver aberto (inclusive via `flutter run`), feche antes de rodar: `adb shell am force-stop br.com.solvebetter.nrfacil` (ignore erro se não houver device ainda). Os flows já usam `subflows/launch_fresh.yaml`, então o estado do app não importa.
- Rode `python3 scripts/check_e2e_semantics.py` antes — se os ids Maestro ↔ Dart estiverem dessincronizados, corrija isso primeiro (é a causa mais comum de falha).

### 2. Rodar

- Smoke completo: `bash scripts/maestro_dev.sh $ARGUMENTS` (ou `--flow <yaml>` se o argumento for um flow).
- Rode em background (`run_in_background`) — boot + build + 4 flows passam fácil de 10 min. Aguarde a notificação de término; não fique fazendo polling.

### 3. Se tudo passou

Responda só o resumo (ver "Saída esperada") e pare.

### 4. Se algo falhou — diagnosticar

Classifique a falha antes de mexer em qualquer coisa:

| Tipo | Sinais | O que fazer |
|------|--------|-------------|
| **Infra** | timeout de boot, `adb` offline, Maestro CLI ausente, Gradle/build falhou | Corrija o ambiente (reiniciar adb `adb kill-server && adb start-server`, `--rebuild`, erro de compilação no Dart). Erro de compilação é bug real → corrigir o código. |
| **Emulador CI travado** | no GHA, **todos** os flows falham em `normas_tab` (1ª tela) ou ficam sem `status.json`; o summary mostra "🔁 faça re-run" | Não é o commit: o `scripts/maestro_ci_warmup.sh` já tentou espera + retry + reboot. `gh run rerun <id> --failed` antes de investigar; só tratar como regressão se repetir. |
| **Flaky** | falhou em `assertVisible`/`tapOn` por timing, passa ao rodar de novo | Rode **só esse flow** de novo uma vez (`bash scripts/maestro_dev.sh --no-boot --flow <yaml>`). Se passar, reporte como flaky e, se for claro, ajuste espera (`extendedWaitUntil`) no flow. |
| **Bug no app** | elemento esperado não existe, texto/estado errado, crash | Corrija o código em `app/` — é o caso que o teste existe para pegar. |
| **Flow desatualizado** | a mudança no app foi intencional (spec em `spec/capabilities/` confirma) e o flow ainda espera o comportamento antigo | Atualize o flow/subflow e os ids em `app/lib/core/constants/semantics/` mantendo o que o teste valida. |

Fontes para diagnosticar (leia, não chute):
- `build/maestro-results/<flow>.xml` — mensagem de falha (JUnit).
- `~/.maestro/tests/<pasta mais recente>/` — `maestro.log`, screenshots da falha (abra a imagem com Read para ver a tela no momento do erro).
- `adb logcat -d -t 500 | grep -i -E "flutter|FATAL|AndroidRuntime"` — exceções e crashes do app.
- O YAML do flow e os subflows em `.maestro/subflows/`.

### 5. Corrigir e repetir

- Corrija a **causa raiz**. Nunca apague passos, remova asserções, adicione `optional: true` ou afrouxe o flow só para passar.
- Se a correção exigir decisão de produto (qual é o comportamento certo?) e a spec não responder, pare e pergunte.
- Depois de mexer em `app/`, rode os testes Dart afetados (`cd app && fvm flutter test <arquivo>`), e então reexecute **só os flows que falharam** com `--no-boot --flow <yaml>` (o script já rebuilda o APK).
- Quando todos os que falharam passarem, rode o smoke completo uma última vez (`bash scripts/maestro_dev.sh --no-boot`) para garantir que nada regrediu.
- Limite: 3 rodadas de correção. Se ainda falhar, pare e reporte o diagnóstico com o que tentou.

## Saída esperada

Resposta curta, em português:
- ✅ **Maestro: 4/4 flows passaram** — nada a corrigir. *(se nada falhou)*
- ou: placar final + lista enxuta do que quebrou e o que foi corrigido (arquivo + uma frase da causa), marcando o que foi flaky.

Não cole o log inteiro, não crie documentos, não commite, não peça permissão para rodar o Maestro de novo depois de uma correção.
