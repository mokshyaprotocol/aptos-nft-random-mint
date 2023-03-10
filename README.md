Random NFT mint smart contract for Aptos Blockchain. The smart contract is available in mainnet and testnet. For detail information please go to our [docs](https://docs.mokshya.io)

Mainnet contract : 0x8035a63a18798115679466eef240aca66364707044f0ac7484e4c462c8310ae9

Testnet contract : 0x8035a63a18798115679466eef240aca66364707044f0ac7484e4c462c8310ae9

# Quick Installation 

```shell
yarn & cd packages/CLI & yarn & cd ../Candymachine-UI & yarn & ../../
```
# Set up candy machine 

```shell
ts-node packages/CLI/src/index.ts --create_candy 
```

# Add whitelist Users

```shell
ts-node packages/CLI/src/index.ts --create_whitelist 
```

# Mint NFT UI

* copy the resource_account from config.json file.

```shell
cd package/Candymachine-UI & yarn
```

* Add config.json resource_account to the env file in resource_account .

```shell 
npm run dev  
```