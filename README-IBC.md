I got my relayer to relay an IBC payment from the cosmos testnet to our devnet!

![15.00 Photon in my wallet](https://www.diigo.com/file/image/brpqocpzpbeerecapzepbqeqpq/SwingSet+Solo+REPL+Demo.jpg)


## Starting a hermes relayer between cosmos and agoric testnets

_Grab the Makefile etc. by, for example, cloning this gist. Then:_

 1. `make task/restore-keys` to:
    - build a docker image for the [Hermes IBC Relayer CLI](https://github.com/informalsystems/ibc-rs/tree/master/relayer-cli) (v0.9.0)
    - create a docker volume for the state
    - generate a mnemonic; import ("recover") secrets for accounts on both chains
 2. **Update `ADDR_AG`, `ADDR_COSMOS` in `Makefile`** with the addresses from step 1.
 3. `make task/tap-agoric-faucet`; follow instructions to tap the faucet; then `touch task/tap-agoric-faucet`
 3. `make task/create-channel` to:
    - tap cosmos faucet
    - create an IBC channel
 4. Take note of the channel ids (details below)
 5. `make start` or `docker-compose up -d` to start the relayer.

Creating the IBC channel results in something like this that includes the channel ids:

```
2021-12-06T21:43:16.791053Z DEBUG ThreadId(01) do_chan_open_finalize for src_channel_id: channel-43, dst_channel_id: channel-3
Success: Channel {
    ordering: Unordered,
    a_side: ChannelSide {
        chain: ProdChainHandle {
            chain_id: ChainId {
                id: "cosmoshub-testnet",
                version: 0,
            },
            runtime_sender: Sender { .. },
        },
        client_id: ClientId(
            "07-tendermint-54",
        ),
        connection_id: ConnectionId(
            "connection-46",
        ),
        port_id: PortId(
            "transfer",
        ),
        channel_id: Some(
            ChannelId(
                "channel-43",
            ),
        ),
    },
    b_side: ChannelSide {
        chain: ProdChainHandle {
            chain_id: ChainId {
                id: "agoricdev-6",
                version: 6,
            },
            runtime_sender: Sender { .. },
        },
        client_id: ClientId(
            "07-tendermint-5",
        ),
        connection_id: ConnectionId(
            "connection-5",
        ),
        port_id: PortId(
            "transfer",
        ),
        channel_id: Some(
            ChannelId(
                "channel-3",
            ),
        ),
    },
    connection_delay: 0ns,
    version: Some(
        "ics20-1",
    ),
}
```

## Provision user account on agorictest-6

Normally [Setting up an Agoric Dapp Client with docker compose](https://github.com/Agoric/agoric-sdk/wiki/Setting-up-an-Agoric-Dapp-Client-with-docker-compose) would suffice, but:

**ISSUE**: needs `home.pegasusConnections` special power due to
https://github.com/Agoric/agoric-sdk/issues/4153

I don't have good notes on how I did this... `agoric start --devnet`? Anyway... the address is

`agoric18kzgpc36eacsdhx8wrdjywvdu3s6dsg2ae3t54`


## Create peg and import issuer


Using [contract/src/deploy-peg.js](https://github.com/Agoric/agoric-sdk/blob/ibc-example-scripts/packages/pegasus/scripts/deploy-peg.js) based on `pegasus/demo.md`:


```
$ agoric deploy contract/src/deploy-peg.js
Open CapTP connection to ws://127.0.0.1:8000/private/captp...o
agoric: deploy: running /home/connolly/projects/agoric/ibc-fun/contract/src/deploy-peg.js
agoric: deploy: Deploy script will run with Node.js ESM
awaiting home...
awaiting pegasusConnections...
pegasusConnections: 11
getting instance, publicFacet
creating peg-channel-10-uphoton from /ibc-port/transfer/unordered/ics20-1/ibc-channel/channel-10
await brand, issuer, board...
{ issuerBoardId: '495234043' } {
  cosmos: { keyword: 'Photon', denom: 'uphoton', decimalPlaces: 6 },
  agoric: { channel: 'channel-10' }
}
```

mostly follow pegasus/demo.md (IOU details)

create purse

trick: set auto-deposit in REPL

## Set up keplr

import both chains using wallet.agoric.app

## Send payment with keplr

 - start on cosmos hub testnet
 - ibc transfer
 - create channel to agoricdev-6 (@@src channel from above)
 - payee from agoric wallet

hermes relayer logs say:

```
2021-12-05T00:20:23.118936Z DEBUG ThreadId(30) [agoricdev-6:transfer/channel-2 -> cosmoshub-testnet] confirmed after 5.102978009s: TxHashes: count=1; 410AD46232C10FB7062B778F94C587238CA45B51EA8BA1A78DD47AC742EF4237
...
2021-12-05T00:20:23.194817Z TRACE ThreadId(24) extracted ibc_client event UpdateClient(UpdateClient { common: Attributes { height: Height { revision: 6, height: 28785 }, client_id: ClientId("07-tendermint-3"), client_type: Tendermint, consensus_height: Height { revision: 0, height: 502622 } }, header: Some(Tendermint( Header {...})) })
```

We can look at the transaction and see the details:

`ag-cosmos-helper --node http://139.59.8.130:26657 query tx 410AD46232C10FB7062B778F94C587238CA45B51EA8BA1A78DD47AC742EF4237` shows:

```
    - key: packet_data
      value: '{"amount":"16000000","denom":"uphoton","receiver":"agoric18kzgpc36eacsdhx8wrdjywvdu3s6dsg2ae3t54","sender":"cosmos18hcdewnyhl6hj6wkz2dwq8slfh8vrnetzxy33p"}'
```

## Payment shows up in agoric wallet

See screenshot above.

## IBC Send using Zoe Offers

```
$ agoric deploy contract/src/deploy-ibc-send.js
Open CapTP connection to ws://127.0.0.1:8000/private/captp...o
agoric: deploy: running /home/connolly/projects/agoric/ibc-fun/contract/src/deploy-ibc-send.js
agoric: deploy: Deploy script will run with Node.js ESM
awaiting home...
await peg, instance...
await transferInvitation, brand, balance...
await payment... {
  gross: { brand: Object [Alleged: Local10 brand] {}, value: 75000000n },
  amount: { brand: Object [Alleged: Local10 brand] {}, value: 250000n }
}
await result...
{
  result: undefined,
  net: { brand: Object [Alleged: Local10 brand] {}, value: 74750000n }
}
```

## Outbound dIBC

In a terminal command line, do:

```
$ gaiad query bank balances --node=https://rpc.testnet.cosmos.network:443 cosmos1dlua5s27mjvt0tedlfq03m3rc30asvt5wxt5s8
balances:
- amount: "100000000"
  denom: uphoton
pagination:
  next_key: null
  total: "0"
$
```

Run `make task/create-connection` (instead of `task/create-channel`), then start Hermes.

In Agoric JS REPL, do:

```
command[0] c = E(home.ibcport[0]).connect('/ibc-hop/connection-0/ibc-port/transfer/unordered/ics20-1')
history[0] [Object Alleged: Connection]{}
command[1] E(c).send(JSON.stringify({ receiver: 'cosmos1dlua5s27mjvt0tedlfq03m3rc30asvt5wxt5s8', sender: 'pegasus', denom: 'hellocoin', amount: '100' }))
history[1] "{\"result\":\"AQ==\"}"
```

And again in a terminal:
```console
$ gaiad query bank balances --node=https://rpc.testnet.cosmos.network:443 cosmos1dlua5s27mjvt0tedlfq03m3rc30asvt5wxt5s8
balances:
- amount: "100"
  denom: ibc/035F742F3A88371DFBF29C451275DD82CF20986F8F13BF9F8FEE3BFD59F7601D
- amount: "99993767"
  denom: uphoton
pagination:
  next_key: null
  total: "0"
$
```

## Acknowledgements

most clues are from
 - [agoric-sdk pegasus/demo.md](https://github.com/Agoric/agoric-sdk/blob/master/packages/pegasus/demo.md)
 - [Agoric ↔ Pooltoy IBC Testnet [WIP]](https://hackmd.io/YYf5lsJXSSuatstpRDSs8g?view)

