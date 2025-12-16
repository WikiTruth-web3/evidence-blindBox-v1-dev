// SPDX-License-Identifier: Apache-2.0

/**
 * 测试工具函数统一导出
 * 提供完整的智能合约测试工具集
 */

// 合约连接工具
export {
    connectContracts,
    connectContract
} from './connectContracts';

// 账户管理工具
export {
    getAccount,
    getAccountByRole,
    getSupportedChainIds,
    isChainIdSupported,
    type TestAccounts
} from './getAccount';

// SIWE认证工具
export {
    siweMsg,
    siweMsgSimple,
    erc191sign,
    verifySiweSignature,
    generateNonce,
    getSupportedChainIds as getSiweSupportedChainIds,
    isChainIdSupported as isSiweChainIdSupported,
    domainList,
    type SiweMessageParams
} from './getSiweAuth';

// EIP712签名工具
export {
    createEIP712Permit_PrivateToken,
    createEIP712Permit_PrivateTokenSimple,
    verifyEIP712Signature,
    createCustomEIP712Domain,
    getSupportedChainIds as getEIP712SupportedChainIds,
    isChainIdSupported as isEIP712ChainIdSupported,
    PermitType,
    type EIP712Domain,
    type EIP712PermitParams,
    type EIP712PermitResult
} from './getEIP712';

// 通用测试工具
export {
    sleep,
    waitForBlocks,
    waitForTransaction,
    // getCurrentNetwork,
    getBalance,
    sendETH,
    deployContract,
    callContractMethod,
    readContractState,
    verifyContractEvent,
    generateRandomAddress,
    generateRandomPrivateKey,
    formatBigNumber,
    parseBigNumber,
    isZeroAddress,
    isValidAddress,
    getCurrentTimestamp,
    timestampToDateString,
    retry,
    withTimeout,
    createTestReport,
    type TestConfig,
    type TransactionConfig,
    type TestResult
} from './common';

/**
 * 工具函数使用示例
 * 
 * ```typescript
 * import { 
 *     getAccount, 
 *     connectContracts, 
 *     siweMsg, 
 *     createEIP712Permit_PrivateToken,
 *     deployContract,
 *     waitForTransaction
 * } from './utils';
 * 
 * // 获取测试账户
 * const accounts = await getAccount(23293);
 * 
 * // 连接合约
 * const connectedContracts = await connectContracts(
 *     () => contractFactory.attach(contractAddress),
 *     [accounts.admin, accounts.buyer]
 * );
 * 
 * // 生成SIWE消息
 * const message = await siweMsg({
 *     domain: 'example.com',
 *     signer: accounts.admin,
 *     chainId: 23293
 * });
 * 
 * // 创建EIP712许可
 * const permit = await createEIP712Permit_PrivateToken({
 *     signer: accounts.admin,
 *     spender: accounts.buyer,
 *     amount: 1000,
 *     mode: PermitType.Transfer,
 *     contractAddress: contractAddress
 * });
 * 
 * // 部署合约
 * const contract = await deployContract(
 *     contractFactory,
 *     accounts.admin,
 *     [constructorArg1, constructorArg2]
 * );
 * 
 * // 等待交易确认
 * const receipt = await waitForTransaction(txHash);
 * ```
 */
