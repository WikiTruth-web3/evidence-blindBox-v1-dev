// SPDX-License-Identifier: Apache-2.0

import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Signer } from 'ethers';
import { SiweMessage } from 'siwe';
import '@nomicfoundation/hardhat-chai-matchers';
// import { user_evm_WikiTruth } from "../WikiTruth_account";
// import { HardhatRuntimeEnvironment } from "hardhat/types";
// import { NETWORKS } from '@oasisprotocol/sapphire-paratime';

export async function getSiweMsg(
    domain: string,
    signer: Signer,
    chainId: number,
    expiration?: Date, // 过期时间
    statement?: string, // 
    resources?: string[], // 
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

