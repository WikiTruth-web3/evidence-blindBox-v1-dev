import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("Token", (m) => {

  const WROSE_ADDRESS = '0xB759a0fbc1dA517aF257D5Cf039aB4D86dFB3b94'

  const wroseSecret = m.contract("WROSEsecret", [
    WROSE_ADDRESS
  ]);

  // const mockERC20 = ''

  // const ERC20Secret = m.contract("ERC20Secret", [
  //   mockERC20
  // ]);
  
  return { 
    wroseSecret, 
    // ERC20Secret 
  };
});

// 1. 部署命令：npx hardhat ignition deploy ignition/modules/05_ERC20Secret.ts --network sapphire-testnet
// 2. 合约地址: 