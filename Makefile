CHAIN_AG=agoricdev-6
CHAIN_COSMOS=cosmoshub-testnet
IMAGE_AGORIC=agoric/agoric-sdk:agoricdev-6

HERMES=docker run --rm -vhermes-home:/home/hermes:z -v$$PWD:/config hermes -c /config/hermes.config

KEYFILE=ibc-relay-mnemonic
task/restore-keys: $(KEYFILE) task/hermes-image task/hermes-volume hermes.config
	MNEMONIC="$$(cat $(KEYFILE))"; \
	echo $$MNEMONIC | sha1sum ; \
	$(HERMES) keys restore $(CHAIN_AG) -p "m/44'/564'/0'/0/0" -m "$$MNEMONIC"; \
	$(HERMES) keys restore $(CHAIN_COSMOS) -m "$$MNEMONIC"
	mkdir -p task && touch $@

# ISSUE: these are the results of task/restore-keys
ADDR_AG=agoric16qj02xh6rag5wscgdc4fd9e8j3cmcren47guwe
ADDR_COSMOS=cosmos1ct7n80pahm0y9tneuhx40vh45yfdcshkwahcfy

start: task/create-channel
	docker-compose up -d

task/create-channel: hermes.config task/hermes-image task/hermes-volume \
		task/restore-keys task/tap-cosmos-faucet task/tap-agoric-faucet
	$(HERMES) create channel $(CHAIN_COSMOS) $(CHAIN_AG) --port-a transfer --port-b transfer -o unordered
	mkdir -p task && touch $@

task/hermes-image: docker-compose.yml hermes.Dockerfile
	docker-compose build
	mkdir -p task && touch $@

$(KEYFILE): task/agoric-image
	docker run --rm $(IMAGE_AGORIC) keys mnemonic >$@
	chmod -w $@

task/agoric-image:
	docker pull $(IMAGE_AGORIC)
	mkdir -p task && touch $@

hermes.Dockerfile:
	wget https://raw.githubusercontent.com/informalsystems/ibc-rs/master/ci/hermes.Dockerfile

task/hermes-volume:
	docker volume create hermes-home
	mkdir -p task && touch $@

task/tap-cosmos-faucet: hermes.config
	@echo tapping faucet
	@echo per https://tutorials.cosmos.network/connecting-to-testnet/using-cli.html#requesting-tokens-from-the-faucet
	curl -X POST -d '{"address": "$(ADDR_COSMOS)"}' https://faucet.testnet.cosmos.network
	mkdir -p task && touch $@

RPC_AG=http://139.59.8.130:26657

task/tap-agoric-faucet: hermes.config
	@echo if the balance below is empty,
	@echo visit https://agoric.com/discord
	@echo go to the "#faucet" channel
	@echo enter: !faucet client $(ADDR_AG)
	docker run --rm $(IMAGE_AGORIC) --node $(RPC_AG) query bank balances $(ADDR_AG)
	@echo otherwise, touch $@
	exit 1
