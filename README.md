# ChatPrototipo

Chat prototype app built with SwiftUI for iOS/iPadOS.

## Requirements

- Xcode 15+
- iOS 17+ / iPadOS 17+
- Swift 5.9+

## Project structure

```
ChatPrototipe/
├── App/
│   ├── AppState.swift
│   └── RootView.swift
├── Models/
│   ├── Conversation.swift
│   ├── Message.swift
│   ├── User.swift
│   └── LLMProvider.swift
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── ChatViewModel.swift
│   ├── ConversationListViewModel.swift
│   └── SettingsViewModel.swift
├── Views/
│   ├── Chat/...
│   ├── Conversations/...
│   ├── Settings/...
│   ├── Auth/...
│   └── Components/...
├── Services/
│   ├── BotResponseService.swift
│   ├── LLMService.swift
│   ├── OpenAIService.swift
│   ├── AnthropicService.swift
│   ├── NetworkManager.swift
│   ├── KeychainService.swift
│   └── StreamingParser.swift
├── Persistence/
│   └── DataContainer.swift
├── Utilities/
│   └── AppLog.swift
├── ChatPrototipoApp.swift
├── ContentView.swift
└── Assets.xcassets/
```

## Implemented features

- Layered MVVM architecture
- SwiftData persistence for conversations and messages
- Conversation list with search, pin, and delete
- Local bot replies with motivational messages and keyword-based reactions
- Local authentication with biometrics
- App settings for theme and chat behavior
- Structured logs with `OSLog`

## Notes

AI provider services are kept in the codebase for future use, but the current chat flow uses a local rule-based bot so it can be fully tested without external APIs.
