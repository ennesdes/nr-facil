# Exemplo de uso — NRReaderPage

## Como integrar o leitor de NRs no seu app

### 1. Adicionar rota no main.dart

```dart
import 'package:nrfacil/features/reader/views/nr_reader_page.dart';
import 'package:nrfacil/features/reader/bindings/reader_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'NR Fácil',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialBinding: AppBinding(),
      getPages: [
        // Rota do leitor — dinâmica por NR
        GetPage(
          name: '/reader/:nrId',
          page: () {
            final nrId = Get.parameters['nrId'] ?? 'nr-06';
            return NRReaderPage(nrId: nrId);
          },
          binding: ReaderBinding(nrId: Get.parameters['nrId'] ?? 'nr-06'),
        ),
      ],
      home: const MyHomePage(),
    );
  }
}
```

### 2. Navegar para o leitor

```dart
// De qualquer lugar no app:
Get.toNamed('/reader/nr-06');
// ou
Get.to(() => const NRReaderPage(nrId: 'nr-06'));
```

### 3. Recursos disponíveis

- **flutter_markdown**: renderiza Markdown com suporte a links, código, etc
- **url_launcher**: abre links externos (PDF original do MTE)
- **Índice lateral (drawer)**: navigate para headings dentro da NR
- **Ajuste de fonte**: botões + e - na app bar
- **Modo escuro**: toggle na app bar
- **Aviso legal**: footer fixo exibindo disclaimer e link do PDF oficial
- **Seleção de texto**: copiar trechos via seleção nativa

### 4. Personalizações futuras

- Anotações (Fase 6)
- Destaque de mudanças (Fase 6)
- Compartilhamento de trechos (Fase 5)
- Busca dentro do documento (Fase 2)

## Estrutura do código

```
features/reader/
├── controllers/
│   └── nr_reader_controller.dart     # GetX Controller — estado do leitor
├── views/
│   ├── nr_reader_page.dart           # Tela principal
│   └── widgets/
│       ├── reader_app_bar.dart       # App bar customizada
│       ├── reader_drawer.dart        # Drawer com índice
│       ├── reader_footer.dart        # Footer com aviso legal + link PDF
│       └── markdown_image_builder.dart # Builder para imagens locais
├── bindings/
│   └── reader_binding.dart           # Injeção de dependências (GetX)
└── EXAMPLE.md                        # Este arquivo
```

## Dependências do leitor

- `flutter_markdown` — renderização de Markdown
- `url_launcher` — abrir URLs externas
- `get` — injeção de dependência e estado (já no projeto)
- `path_provider` — acesso ao cache local (já no projeto)

## Fluxo de dados

1. Controller carrega conteúdo Markdown via `ContentService.readNrContent(nrId)`
2. Controller carrega índice via `ContentService.readNrIndex(nrId)` 
3. Page renderiza Markdown com `MarkdownBody`
4. Imagens locais são renderizadas via `NrMarkdownImageBuilder`
5. Links externos abrem via `url_launcher`
6. Drawer exibe headings do índice para navegação rápida

## Notas de design

- **Modo offline**: tudo funciona offline — Markdown e assets estão em cache local após sync
- **Seleção de texto**: nativa do Flutter — usuário copia trechos normalmente
- **Responsividade**: `SingleChildScrollView` adapta a qualquer tamanho de tela
- **Dark mode**: estilos customizados para ambos os temas (recomendado usar tokens de design quando implementados)
- **Acessibilidade**: labels em tooltips para botões, textos descritivos em placeholders

## Testes

Rode `fvm flutter analyze --fatal-infos` e `fvm flutter test` para validar integração.
