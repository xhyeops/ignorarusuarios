# Ignore Plus - Atualizado para Discourse 2026+

Um componente de tema para Discourse que oculta tópicos e conteúdo de usuários ignorados.

## ✨ Funcionalidades

- **Oculta tópicos** criados por usuários ignorados nas listas de tópicos
- **Esmaece avatares** de usuários ignorados nas listas
- **Oculta citações (quotes)** de usuários ignorados dentro de posts
- Funciona em todas as visualizações: Latest, Categories, Suggested Topics, Mobile

## 🔧 Por que esta atualização?

O plugin original usava a API `api.modifyClass("component:topic-list-item")` que foi **descontinuada** no Discourse 2025+. 

Esta versão usa as novas APIs:
- `registerValueTransformer("topic-list-item-class")` - para adicionar classes CSS aos itens
- `registerValueTransformer("topic-list-class")` - para classes na lista
- `decorateCookedElement` - para manipular citações e avatares em posts

## 📦 Instalação

1. Acesse o painel de administração do Discourse
2. Vá em **Customize → Themes**
3. Clique em **Install** → **From a git repository**
4. Cole a URL do repositório
5. Adicione o componente ao seu tema ativo

## ⚙️ Configurações

| Configuração | Descrição | Padrão |
|-------------|-----------|--------|
| `hide_ignored_users_avatar` | Esmaece avatares de usuários ignorados | `true` |
| `hide_ignored_user_topics` | Oculta tópicos de usuários ignorados | `true` |
| `hide_ignored_user_quotes` | Oculta citações de usuários ignorados | `true` |

## 📁 Estrutura do Projeto

```
discourse-ignore-plus-updated/
├── about.json                     # Metadados do componente
├── settings.yml                   # Configurações do tema
├── common/
│   └── common.scss               # Estilos CSS
└── javascripts/
    └── discourse/
        └── api-initializers/
            ├── ignore-plus.gjs        # Lógica principal (topic lists)
            └── ignore-plus-quotes.gjs # Lógica de citações
```

## 🔄 Mudanças da versão original

### Antes (API antiga - não funciona em 2026+)
```javascript
api.modifyClass("component:topic-list-item", {
  pluginId: PLUGIN_ID,
  @discourseComputed()
  unboundClassNames() {
    // ...
  }
});
```

### Depois (API nova - compatível com 2026+)
```javascript
api.registerValueTransformer("topic-list-item-class", ({ value, context }) => {
  const { topic } = context;
  if (isIgnoredTopicCreator(topic)) {
    value.push("ignored-op-topic");
  }
  return value;
});
```

## 📝 Notas

- O componente requer que o usuário esteja logado para funcionar
- Usuários ignorados são obtidos via `api.getCurrentUser().ignored_users`
- As citações ocultas mostram um placeholder com opção de "Mostrar mesmo assim"

## 📄 Licença

GPL-3.0 (mesmo que o projeto original)
