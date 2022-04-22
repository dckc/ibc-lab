CHAIN_AG=agoricdev-10
CHAIN_COSMOS=cosmoshub-testnet
IMAGE_AGORIC=agoric/agoric-sdk:agoricdev-10

HERMES=docker run --rm -vhermes-home:/home/hermes:z -v$$PWD:/config hermes -c /config/hermes.config

KEYFILE=ibc-relay-mnemonic
task/restore-keys: $(KEYFILE) task/hermes-image task/hermes-volume hermes.config
	mkdir -p keys ; \
	MNEMONIC="$$(cat $(KEYFILE))"; \
	echo $$MNEMONIC | sha1sum ; \
	$(HERMES) keys restore $(CHAIN_AG) -p "m/44'/564'/0'/0/0" -m "$$MNEMONIC" | awk '{print $$5}' | tr -d '()' > $(ADDR_AG_KEY); \
	$(HERMES) keys restore $(CHAIN_COSMOS) -m "$$MNEMONIC" | awk '{print $$5}' | tr -d '()' > $(ADDR_COSMOS_KEY); \
	mkdir -p task && touch $@

# ISSUE: use matching key names in hermes.config for consistency
ADDR_AG_KEY=keys/agdevkey
ADDR_AG := $(shell cat $(ADDR_AG_KEY))

# ISSUE: use matching key names in hermes.config for consistency
ADDR_COSMOS_KEY=keys/hubkey
ADDR_COSMOS := $(shell cat ${ADDR_COSMOS_KEY})


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

RPC_AG=http://46.101.220.43:26657

task/tap-agoric-faucet: hermes.config
	@echo if the balance below is empty,
	@echo visit https://agoric.com/discord
	@echo go to the "#faucet" channel
	@echo enter: !faucet client $(ADDR_AG)
	docker run --rm $(IMAGE_AGORIC) --node $(RPC_AG) query bank balances $(ADDR_AG)
	@echo otherwise, touch $@
	exit 1
