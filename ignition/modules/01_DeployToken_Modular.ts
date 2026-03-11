import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
/**
 * 
 * npx hardhat ignition deploy ignition/modules/01_DeployToken_Modular.ts --network sapphire-testnet
 * 
 * import { ERC20Module } from './01_DeployToken_Modular';
 * npx hardhat ignition deploy ... --module-id ERC20Module
 * 
 * import { ERC20SecretModule } from './01_DeployToken_Modular';
 * 
 * # Remove deployments
Remove-Item -Recurse -Force ignition\deployments\chain-23295
 */

// // ==================== 模块1：MockERC20 ====================
// export const ERC20Module = buildModule("ERC20Module", (m) => {
//   const mockERC20 = m.contract("MockERC20", [
//     'Wikitruth Coin',
//     'WTRC'
//   ], {
//     id: "MockERC20_20251009"
//   });

//   return { mockERC20};
// });

// // ==================== 模块2：ERC20Secret ====================
// export const ERC20SecretModule = buildModule("ERC20SecretModule", (m) => {
//   const { mockERC20 } = m.useModule(ERC20Module);

//   const erc20Secret = m.contract("ERC20Secret", [mockERC20], {
//     id: "ERC20Secret_20251009"
//   });


//   return { erc20Secret };
// });

// ==================== 模块3：WROSESecret ====================
export const WROSESecretModule = buildModule("WROSESecretModule", (m) => {
  const WROSE_ADDRESS = "0xB759a0fbc1dA517aF257D5Cf039aB4D86dFB3b94"

  const wroseSecret = m.contract("WROSEsecret", [WROSE_ADDRESS], {
    id: "WROSESecret_20251208"
  });


  return { wroseSecret };
});


// ==================== 主模块：组合所有模块 ====================
export default buildModule("AllTokenContracts", (m) => {
  // const mockERC20 = m.useModule(ERC20Module);
  // const erc20Secret = m.useModule(ERC20SecretModule);
  const wroseSecret = m.useModule(WROSESecretModule);


  return {
    // mockERC20: mockERC20.mockERC20,
    // erc20Secret: erc20Secret.erc20Secret,
    wroseSecret: wroseSecret.wroseSecret
  };
});


