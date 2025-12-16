import deploymentInfo from "../../deployments/v3_sapphire_testnet.json";

/**
 * This is the uniswapV3 testnet address
 */

export const v3_core_testnet_address = {
    factory: deploymentInfo.coreContracts.UniswapV3Factory,
    weth9: deploymentInfo.coreContracts.WETH9,
};

export const v3_periphery_testnet_address = {
    nftDescriptor: deploymentInfo.peripheryContracts.NFTDescriptor,
    nftTokenPositionDescriptor: deploymentInfo.peripheryContracts.NonfungibleTokenPositionDescriptor,
    nftPositionManager: deploymentInfo.peripheryContracts.NonfungiblePositionManager,
    swapRouter: deploymentInfo.peripheryContracts.SwapRouter,
    quoter: deploymentInfo.peripheryContracts.Quoter,
    quoterV2: deploymentInfo.peripheryContracts.QuoterV2,
    tickLens: deploymentInfo.peripheryContracts.TickLens,
    v3Migrator: deploymentInfo.peripheryContracts.V3Migrator,
};


