# Wake-On-LAN Utility (`wol.sh`)

![License](https://img.shields.io/badge/license-MIT-blue.svg)

**wol.sh** é uma ferramenta simples e eficiente para enviar pacotes "magic packet" (pacotes mágicos) usando a funcionalidade **Wake-on-LAN (WoL)**. Ele permite acordar computadores que estão configurados para ouvir solicitações WoL/WLAN.

## Índice
1. [Visão Geral](#visão-geral)
2. [Requisitos](#requisitos)
3. [Instalação](#instalação)
4. [Uso](#uso)
   - [Modo Direto](#modo-direto)
   - [Modo Arquivo](#modo-arquivo)
   - [Modo Interativo](#modo-interativo)
5. [Formato do Arquivo de Entrada](#formato-do-arquivo-de-entrada)
6. [Exemplos](#exemplos)
7. [Logs](#logs)
8. [Licença](#licença)

---

## Visão Geral

O **wol.sh** é um script Bash que envia pacotes "magic packet" para acordar máquinas configuradas para receber esses pacotes. Ele suporta múltiplos modos de operação, incluindo entrada direta, arquivo de entrada e modo interativo.

---

## Requisitos

- **Sistema Operacional:** Linux ou macOS.
- **Ferramentas Necessárias:**
  - `nc` (netcat) ou `socat` instalado no sistema.
- **Configuração do Computador Alvo:**
  - O recurso **Wake-on-LAN** deve estar habilitado na BIOS/UEFI e no sistema operacional.
  - A placa de rede deve estar configurada para aceitar pacotes WoL.

---

## Instalação

1. Baixe o script:
   ```bash
   wget https://raw.githubusercontent.com/matheuseduardo/wol-utility/refs/heads/main/wol.sh
   ```
2. Torne o script executável:
   ```bash
   chmod +x wol.sh
   ```
3. Verifique se as dependências estão instaladas:
   ```bash
   nc --version || socat --version
   ```

---

## Uso

### Modo Direto

Envie um pacote mágico diretamente via linha de comando:

```bash
./wol.sh <MAC> [IP] [Port]
```

- `<MAC>`: Endereço MAC da máquina alvo (obrigatório).
- `[IP]`: IP para o qual o pacote será enviado (opcional, padrão: `255.255.255.255`).
- `[Port]`: Porta para o envio do pacote (opcional, padrão: `9`).

#### Exemplo:
```bash
./wol.sh AA:BB:CC:DD:EE:FF 192.168.1.255 9
```

---

### Modo Arquivo

Use um arquivo de entrada contendo múltiplos registros para enviar pacotes mágicos:

```bash
./wol.sh --file|-f <input_file>
```

O script lerá o arquivo e permitirá que você selecione qual registro deseja usar.

---

### Modo Interativo

Se nenhum argumento for fornecido ou se o parâmetro `--interactive` for usado, o script entrará no modo interativo:

```bash
./wol.sh --interactive|-i
```

O script solicitará os valores de MAC, IP e porta.

---

## Formato do Arquivo de Entrada

Cada linha do arquivo de entrada deve conter um registro no seguinte formato:

```
MAC|IP|Port|Description
```

- `MAC`: Endereço MAC da máquina alvo (obrigatório).
- `IP`: IP para o qual o pacote será enviado (opcional, padrão: `255.255.255.255`).
- `Port`: Porta para o envio do pacote (opcional, padrão: `9`).
- `Description`: Descrição opcional para identificar o dispositivo.

#### Exemplo de Arquivo de Entrada (`input.txt`):
```
AA:BB:CC:DD:EE:FF|192.168.1.255|9|Desktop Office
BB:CC:DD:EE:FF:AA|||Laptop Personal
CC:DD:EE:FF:AA:BB|192.168.1.2||Server Backup
```

---

## Exemplos

### Enviar Pacote Diretamente
```bash
./wol.sh AA:BB:CC:DD:EE:FF
```

### Usar Arquivo de Entrada
```bash
./wol.sh --file input.txt
```

### Modo Interativo
```bash
./wol.sh --interactive
```

---

## Logs

Todas as tentativas de envio de pacotes são registradas no arquivo `wol.log`. Cada entrada inclui:
- Data e hora.
- Endereço MAC, IP e porta usados.
- Status da operação (sucesso ou falha).

Exemplo de entrada no log:
```
2023-10-10 14:30:00: Sending magic packet to MAC: AA:BB:CC:DD:EE:FF, IP: 192.168.1.255, Port: 9
2023-10-10 14:30:00: Successfully sent magic packet to MAC: AA:BB:CC:DD:EE:FF, IP: 192.168.1.255, Port: 9
```

## Licença

Este projeto está licenciado sob a **MIT License**. Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.
