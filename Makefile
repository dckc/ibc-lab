task/docker-image: task hermes.Dockerfile
	docker build -t hermes . -f hermes.Dockerfile | tail -n 2 >$@
	touch $@

hermes.Dockerfile:
	wget https://raw.githubusercontent.com/informalsystems/ibc-rs/master/ci/hermes.Dockerfile

./bin/stoml:
	mkdir -p bin
	wget -O $@ https://github.com/freshautomations/stoml/releases/download/v0.7.0/stoml_linux_amd64
	chmod +x $@

ADDR_AG=agoric1c227ytfhksuen7graauu4nq7htwgtr72ujelfg
ADDR_COSMOS=cosmos18hcdewnyhl6hj6wkz2dwq8slfh8vrnetzxy33p
CHAIN_AG=agoricdev-6
CHAIN_COSMOS=cosmoshub-testnet
KEYFILE=/keybase/private/kc_colo29,dckc/ibc-fun-key
HERMES=docker run --rm -vhermes-home:/home/hermes:z -v$$PWD:/config hermes -c /config/hermes.config

task:
	mkdir -p task

task/create-channel: hermes.config task/docker-image task/restore-keys task/tap-faucet
	$(HERMES) create channel $(CHAIN_COSMOS) $(CHAIN_AG) --port-a transfer --port-b transfer -o unordered
	touch $@

task/restore-keys: task task/docker-image hermes.config
	docker volume create hermes-state
	MNEMONIC="$$(cat $(KEYFILE))"; \
	echo $$MNEMONIC | sha1sum ; \
	$(HERMES) keys restore $(CHAIN_AG) -p "m/44'/564'/0'/0/0" -m "$$MNEMONIC"; \
	$(HERMES) keys restore $(CHAIN_COSMOS) -m "$$MNEMONIC"
	touch $@

task/tap-faucet: task hermes.config
	@echo tapping faucet
	@echo per https://tutorials.cosmos.network/connecting-to-testnet/using-cli.html#requesting-tokens-from-the-faucet
	curl -X POST -d '{"address": "$(ADDR_COSMOS)"}' https://faucet.testnet.cosmos.network
	touch $@
