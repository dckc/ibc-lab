I got my relayer to relay an IBC payment from the cosmos testnet to our devnet!

![15.00 Photon in my wallet](https://www.diigo.com/file/image/brpqocpzpbeerecapzepbqeqpq/SwingSet+Solo+REPL+Demo.jpg)


## Starting a hermes relayer between cosmos and agoric testnets

[Hermes: IBC Relayer CLI](https://github.com/informalsystems/ibc-rs/tree/master/relayer-cli)

As detailed in `Makefile`, `hermes.Dockerfile`, `hermes.config`, and `docker-compose.yml`:
 1. build a hermes-image (v0.9.0)
 2. create a docker volume for the state
 3. generate a mnemonic; import ("recover") secrets for accounts on both chains
    - **Update `ADDR_AG`, `ADDR_COSMOS` in `Makefile`**
 4. tap cosmos, agoric faucets
 5. create an IBC channel
    - Take note of the channel ids
 6. start the relayer


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

## Provision and Fund Relayer Account on agorictest-6

I don't have good notes on how I did this... `agoric start --devnet`? Anyway... the address is

`agoric1c227ytfhksuen7graauu4nq7htwgtr72ujelfg`

I do see where I funded it using the normal devnet faucet in discord:
https://discord.com/channels/585576150827532298/767231925646524446/916205759753228289

## Create peg and import issuer

 - started wallet client with REPL using [Setting up an Agoric Dapp Client with docker compose · Agoric/agoric\-sdk Wiki](https://github.com/Agoric/agoric-sdk/wiki/Setting-up-an-Agoric-Dapp-Client-with-docker-compose)

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

## Acknowledgements

most clues are from
 - [agoric-sdk pegasus/demo.md](https://github.com/Agoric/agoric-sdk/blob/master/packages/pegasus/demo.md)
 - [Agoric ↔ Pooltoy IBC Testnet [WIP]](https://hackmd.io/YYf5lsJXSSuatstpRDSs8g?view)

