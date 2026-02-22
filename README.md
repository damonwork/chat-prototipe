# ChatPrototipo

Prototipo de aplicación de chat construida con **SwiftUI** para iOS/iPadOS.

## Requisitos

- Xcode 15+
- iOS 17+ / iPadOS 17+
- Swift 5.9+

## Estructura del proyecto

```
ChatPrototipe/
├── ChatPrototipoApp.swift   # Punto de entrada (@main)
├── ContentView.swift        # UI principal: lista de mensajes + barra de entrada
├── Assets.xcassets/         # Recursos (icono, colores)
└── Preview Content/         # Assets solo para previews de Xcode
```

## Características base

- Lista de mensajes con burbujas estilo chat (usuario / bot)
- Barra de entrada de texto con botón de envío
- Respuesta simulada automática
- Soporte para modo claro/oscuro

## Próximos pasos

- [ ] Integrar API de LLM (OpenAI, Anthropic, etc.)
- [ ] Persistencia de conversaciones (SwiftData / Core Data)
- [ ] Historial de chats
- [ ] Autenticación de usuario
- [ ] Streaming de respuestas
