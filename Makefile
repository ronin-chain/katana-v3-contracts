deploy-testnet:
	op run --env-file="./.env" -- \
	forge script DeployKatanaV3Testnet -f ronin-testnet

deploy-testnet-broadcast:
	op run --env-file="./.env" -- \
	forge script DeployKatanaV3Testnet -f ronin-testnet --verify --verifier sourcify --verifier-url https://sourcify.roninchain.com/server/ --legacy --broadcast

deploy-mainnet:
	op run --env-file="./.env" -- \
	forge script DeployKatanaV3Mainnet -f ronin-mainnet

deploy-mainnet-broadcast:
	op run --env-file="./.env" -- \
	forge script DeployKatanaV3Mainnet -f ronin-mainnet --verify --verifier sourcify --verifier-url https://sourcify.roninchain.com/server/ --legacy --broadcast