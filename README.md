# financeControl - Mobile

App mobile do financeControl, sistema de controle de finanças pessoais desenvolvido na disciplina de Programação Web e Mobile (UPF). Consome a [API financeControl](https://github.com/Henry-FTres/financeControl-backend) e complementa o [front-end web](https://github.com/Manuela-LStivanin/financeControl-frontend).

A versão web é a mais completa, para organizar as finanças com calma. O app é a versão de bolso: serve para conferir rapidamente como estão as contas e para lançar uma entrada ou saída na hora, por exemplo logo depois de uma compra no mercado.

## Tecnologias

- **Flutter** (Dart 3.14)
- **http** para as chamadas à API
- **shared_preferences** para guardar o token de login no aparelho
- **intl** para formatar valores em reais e datas
- **google_fonts** com a fonte **Manrope**, a mesma da web
- Tema claro e escuro automático, com as cores do design system da web

## Como rodar

A **API precisa estar rodando** antes, em `http://localhost:3000` (veja o README do backend).

```bash
# 1. instalar as dependências
flutter pub get

# 2a. rodar no navegador (Chrome)
flutter run -d chrome

# 2b. ou rodar no emulador Android (com o emulador já aberto)
flutter run
```

O endereço da API fica em `lib/services/api.dart`, na constante `apiUrl`:

| Onde o app roda | Endereço usado |
|---|---|
| Chrome | `http://localhost:3000/api` |
| Emulador Android | `http://10.0.2.2:3000/api` |

No emulador, `localhost` aponta para o próprio emulador; `10.0.2.2` é o endereço do computador visto de dentro dele. Para testar em um celular de verdade, troque pelo IP do computador na rede Wi-Fi.

## Telas

| Tela | O que faz |
|---|---|
| Login | Entrar com e-mail e senha |
| Início | Saldo total, entradas e saídas do mês e as últimas movimentações; puxar a tela para baixo atualiza os dados |
| Nova movimentação | Lançar uma entrada ou saída, com valor, data, conta, categoria, descrição e se é fixa |

O cadastro de usuário, contas, categorias e metas é feito pela versão web.

## Estrutura

```
lib/
  main.dart                     início do app: tema e primeira tela
  screens/
    login_screen.dart           tela de login
    home_screen.dart            tela inicial com o resumo
    nova_movimentacao_screen.dart  formulário de nova movimentação
  services/
    api.dart                    chamadas à API (envia o token e trata erros)
    auth_storage.dart           guarda, lê e apaga o token no aparelho
  theme/
    app_theme.dart              cores e temas claro e escuro
```

## Autenticação

Ao entrar, o token recebido da API é guardado no aparelho (`shared_preferences`) e enviado em todas as requisições no cabeçalho `Authorization: Bearer <token>`. Se a API responder que o token é inválido ou expirou, o token é apagado e o app volta para o login.

## Android

O `android/app/src/main/AndroidManifest.xml` libera o acesso à internet e o uso de HTTP sem criptografia, necessário porque a API roda localmente em `http://`. Em produção, com a API em `https://`, essa liberação deixaria de ser necessária.

## Autores

- Manuela Larissa Stivanin - 210542
- Henry Afonso Fiorentin Tres - 208487
