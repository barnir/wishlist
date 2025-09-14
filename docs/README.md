# 📚 Documentação - Wishlist App

## 📋 Índice

### 🚀 **Início Rápido**
- [README Principal](../README.md) — visão geral do projeto
- [Guia de Desenvolvimento](DEVELOPMENT_GUIDE.md) — como começar a desenvolver
- [Troubleshooting](TROUBLESHOOTING.md) — resolução de problemas
- [Improvements Overview](IMPROVEMENTS_OVERVIEW.md) — resumo consolidado das melhorias
- [Performance Report](PERFORMANCE_REPORT.md) — detalhamento técnico de performance

### 🔧 **Documentação Técnica**
- [API Documentation](API_DOCUMENTATION.md) — Documentação completa da API

### 📁 **Estrutura da Documentação**

```
docs/
├── README.md                   # Este arquivo (índice)
├── DEVELOPMENT_GUIDE.md        # Guia de desenvolvimento
├── API_DOCUMENTATION.md        # Documentação da API
├── TROUBLESHOOTING.md          # Guia de troubleshooting
├── IMPROVEMENTS_OVERVIEW.md    # Resumo consolidado de melhorias
└── PERFORMANCE_REPORT.md       # Relatório técnico de performance
```

## 🎯 **Por Onde Começar**

### 👨‍💻 **Para Desenvolvedores**
1. **Primeiro**: Ler o [README Principal](../README.md)
2. **Segundo**: Seguir o [Guia de Desenvolvimento](DEVELOPMENT_GUIDE.md)
3. **Terceiro**: Consultar a [API Documentation](API_DOCUMENTATION.md)

### 🆘 **Para Resolver Problemas**
1. **Primeiro**: Verificar o [Troubleshooting](TROUBLESHOOTING.md)
2. **Segundo**: Consultar a [API Documentation](API_DOCUMENTATION.md)
3. **Terceiro**: Abrir um issue no GitHub

### 📖 **Para Entender a Arquitetura**
1. **Primeiro**: Ler a [API Documentation](API_DOCUMENTATION.md)
2. **Segundo**: Seguir o [Guia de Desenvolvimento](DEVELOPMENT_GUIDE.md)

## 🔍 **Busca Rápida**

### 🔐 **Autenticação (Firebase Auth)**
- [AuthService](API_DOCUMENTATION.md#autenticação)
- [Google Sign-In](TROUBLESHOOTING.md#problema-erro-no-google-sign-in)
- [OTP/SMS](TROUBLESHOOTING.md#problema-otp-não-chega-via-sms)

### 📊 **Base de Dados (Cloud Firestore)**
- [Repositórios/Serviços](API_DOCUMENTATION.md#base-de-dados)
- [Regras/Permissões](TROUBLESHOOTING.md#problema-erro-de-permissão)
- [Conexão](TROUBLESHOOTING.md#problema-erro-de-conexão)

### 📸 **Imagens (Cloudinary)**
- [CloudinaryService](API_DOCUMENTATION.md#imagens)
- [Upload de Imagens](TROUBLESHOOTING.md#problema-upload-de-imagem-falha)
- [Lazy Loading / Otimizações](TROUBLESHOOTING.md#problema-imagem-não-carrega)

### 🛍️ **Web Scraping (Cloud Functions)**
- [Secure Scraper (callable)](API_DOCUMENTATION.md#web-scraping)
- [Rate Limiting](TROUBLESHOOTING.md#problema-rate-limiting)
- [Domínios Permitidos](TROUBLESHOOTING.md#problema-scraping-não-funciona)

### 🎨 **UI/UX**
- [Widgets](API_DOCUMENTATION.md#widgets-api)
- [Performance](TROUBLESHOOTING.md#problema-performance-lenta)
- [Crash](TROUBLESHOOTING.md#problema-app-crash-ao-abrir)

### 🔧 **Build e Deploy**
- [Build](TROUBLESHOOTING.md#problema-build-falha)
- [APK Size](TROUBLESHOOTING.md#problema-apk-muito-grande)
- [Google Play](DEVELOPMENT_GUIDE.md#google-play-store)

### 📞 **Suporte**

### 🆘 **Problemas Técnicos**
- **Issues**: https://github.com/barnir/wishlist/issues

### 📊 **Informações do Projeto**
- **Versão**: consulte CHANGELOG.md
- **Flutter**: 3.35.1+
- **Stack**: Firebase (Auth, Firestore, Functions, Messaging, Analytics) + Cloudinary
- **Plataforma**: Android
- **Última atualização**: Setembro 2025

## 🔄 **Contribuição**

### 📝 **Como Contribuir**
1. Fork o projeto
2. Criar branch para feature (`git checkout -b feature/AmazingFeature`)
3. Commit das mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abrir Pull Request

### 📋 **Padrões**
- Seguir as [Convenções de Código](DEVELOPMENT_GUIDE.md#convenções-de-código)
- Adicionar testes para novas funcionalidades
- Documentar código complexo
- Manter cobertura de testes > 80%

## 📈 **Versões**

### 🏷️ **Histórico de Versões**
- **v1.0.0** (Janeiro 2025) - Versão inicial
  - Autenticação completa (email, telefone, Google)
  - Gestão de wishlists e items
  - Web scraping inteligente
  - Upload de imagens
  - Interface Material 3

### 🔮 **Roadmap**
- **v1.1.0** - Notificações push
- **v1.2.0** - Modo offline
- **v1.3.0** - Partilha de wishlists
- **v2.0.0** - Web app

---

**Desenvolvido com ❤️ para a comunidade Flutter**
