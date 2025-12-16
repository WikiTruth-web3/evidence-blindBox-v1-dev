// SPDX-License-Identifier: Apache-2.0

import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Signer } from 'ethers';
import { SiweMessage } from 'siwe';
import '@nomicfoundation/hardhat-chai-matchers';
// import { user_evm_WikiTruth } from "../WikiTruth_account";
// import { HardhatRuntimeEnvironment } from "hardhat/types";
// import { NETWORKS } from '@oasisprotocol/sapphire-paratime';

// 这个函数的作用是：生成一个SIWE消息。
// 在前端一般是直接由钱包生成，然后发送给合约。
// 这里只是为了测试，所以手动生成。
export async function getSiweMsg(
    domain: string,
    signer: Signer,
    chainId: number,
    expiration?: Date, // 过期时间
    statement?: string, // 声明
    resources?: string[], // 资源
): Promise<string> {
    return new SiweMessage({
        domain,
        address: await signer.getAddress(), // 签名者地址，在前端一般是钱包地址
        statement:
            statement ||
            `I accept the ExampleOrg Terms of Service: https://${domain}/tos`,
        uri: `https://${domain}`,
        version: '1',
        chainId: chainId,
        expirationTime: expiration ? expiration.toISOString() : undefined,
        resources: resources || [],
    }).toMessage();
}

// Signs the given message as ERC-191 "personal_sign" message.
export async function erc191sign(msg: string, signer: Signer) {
    return ethers.Signature.from(await signer.signMessage(msg));
}

// let siweStr:any;

// it('1.测试登录', async function () {
//     this.timeout(TESTNET_CONFIG.timeout);


//     // 正确的登录
//     siweStr = await getSiweToken(domain, owner);
    
//     const token = await contract_owner.testLogin(
//         siweStr,
//         await erc191sign(siweStr, owner),
//     );
    
//     expect(token).to.have.length.greaterThan(2); // 验证token不为空
//     console.log("✅ 正确登录成功");

//     const tx1 = await contract_owner.testAuthMsgSender(token)

//     expect(tx1).to.equal(owner.address);
//     console.log("✅ 获取登录用户地址成功:", tx1);

// });

