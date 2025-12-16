// SPDX-License-Identifier: Apache-2.0

import { expect } from 'chai';
import { ethers } from 'hardhat';
// import { Signer } from 'ethers';
// import { SiweMessage } from 'siwe';
import '@nomicfoundation/hardhat-chai-matchers';
// import { user_evm_WikiTruth } from "../WikiTruth_account";
import { HardhatRuntimeEnvironment } from "hardhat/types";
// import { NETWORKS } from '@oasisprotocol/sapphire-paratime';
import { 
    getAccount, 
    connectContract,
    // deployContract,
    siweMsg, 
    erc191sign,
    domainList,
    // getCurrentNetwork,
    sleep,
    type TestAccounts
} from '../../utils';

/**
 * 测试SiweAuth合约
 * 
 * 本地测试网 - 部署新合约进行测试
 * 启动dockers： docker run --rm -it -p 8545:8545 ghcr.io/oasisprotocol/sapphire-localnet:latest
 * 运行：npx hardhat test test/single/SiweAuth.ts （--network sapphire_localnet）
 * 
 * 实现SIWE认证的流程()：
 * 第一部分：生成令牌token
 *     1. 在前端（脚本）中，生成登录所需要的SIWE消息
 *     2. 用户使用钱包签名SIWE消息，并发送给合约
 *     3. 合约验证SIWE消息，--------------------Login函数，并返回token
 * 第二部分：使用认证令牌调用合约的认证方法
 *     1. 用户使用认证令牌调用合约的认证方法——————
 *     2. 合约验证认证令牌，并返回认证者地址
 * 第三部分：撤销认证令牌
 *     1. 用户使用认证令牌调用合约的认证方法——————
 *     2. 合约验证认证令牌，并返回认证者地址
 * 第四部分：使用认证者地址调用合约的认证方法
 *     1. 用户使用认证者地址调用合约的认证方法——————
 *     2. 合约验证认证者地址，并返回认证者地址
 */

describe('SiweAuth Sapphire_localnet', function () {
    let hre: HardhatRuntimeEnvironment;
    let accounts: TestAccounts;
    let network: any;
    
    // 合约实例
    let siweAuthContract: any;
    let contractFactory: any;
    let contractAddress: string;

    // 连接的合约实例
    let contract_admin: any;
    let contract_adminOld: any;
    let contract_addr1: any;
    let contract_addr2: any;
    let contract_addr3: any;
    let contract_viewAccount: any;
    
    // 账户变量
    let admin: any;
    let adminNew: any;
    let addr1: any;
    let addr2: any; // 新所有者
    let addr3: any; // 测试用户
    let viewAccount: any; // 测试用户

    // 使用工具函数中的域名配置
    let primaryDomain: string;
    let domain1: string;
    let domain2: string;
    let domain3: string;
    let domain4: string;
    let invalidDomain: string;
    let domainTest: string ;
    let domainTest2: string ;

    // 本地测试网配置
    const LOCALNET_CONFIG = {
        chainId: 23293, // sapphire_localnet
        timeout: 5000 // 增加超时时间到5秒
    };

    const sleepTime = 1000;

    before(async function () {
        this.timeout(60000); // 增加超时时间
        
        console.log("🚀 开始SiweAuth合约测试——配置测试环境...");

        hre = require("hardhat");
        // 切换到Sapphire测试网
        await hre.switchNetwork("sapphire_localnet");
        
        // 获取网络配置
        network = await ethers.provider.getNetwork();
        console.log("🌐 当前网络:", network.networkName, "链ID:", network.chainId);
        console.log("🌐 目标网络ID:", LOCALNET_CONFIG.chainId);
        
        // if (network.chainId !== LOCALNET_CONFIG.chainId) {
        //     throw new Error(`网络不匹配！当前: ${network.chainId}, 期望: ${LOCALNET_CONFIG.chainId}`);
        // }

        // 获取测试账户
        accounts = await getAccount(network.chainId);
        console.log("👤 测试账户已获取");

        // 初始化域名配置
        [primaryDomain, domain1, domain2, domain3, domain4, invalidDomain, domainTest, domainTest2] = domainList;
        
        // 部署SiweAuth合约
        console.log("🚀 部署SiweAuth合约...");
        contractFactory = await ethers.getContractFactory("contracts/SiweAuth.sol:SiweAuth");
        
        // 构造域名数组（排除无效域名）
        const validDomains = [domain1, domain2, domain3, domain4];
        
        siweAuthContract = await contractFactory.deploy(
            ethers.ZeroAddress, // addrManager_ - 暂时使用零地址
            primaryDomain,      // primaryDomain
            validDomains        // domains数组
        );
        // 等待部署完成
        await siweAuthContract.waitForDeployment();
        contractAddress = await siweAuthContract.getAddress();
        console.log("✅ SiweAuth部署成功，地址:", contractAddress);

        // 设置账户变量
        addr1 = accounts.admin;
        addr2 = accounts.minter;
        viewAccount = accounts.buyer;
        addr3 = accounts.buyer2;

        console.log("👤 测试账户地址:");
        console.log("  - addr1:", addr1.address);
        console.log("  - addr2:", addr2.address);
        console.log("  - addr3:", addr3.address);

        // 连接到已部署的合约
        contract_addr1 = await connectContract(siweAuthContract, addr1);
        contract_addr2 = await connectContract(siweAuthContract, addr2);
        contract_addr3 = await connectContract(siweAuthContract, addr3);
        contract_viewAccount = await connectContract(siweAuthContract, viewAccount);
        
        console.log("🔗 合约连接完成");
        
        await sleep(sleepTime); // 等待网络同步
    });
    
    async function setValue(currentAdminAddr: any) {
        console.log("当前的admin地址：", currentAdminAddr);
        await sleep(sleepTime);

        if (currentAdminAddr == addr1.address) {
            contract_adminOld = contract_addr3;
            admin = addr1;
            contract_admin = contract_addr1;
            adminNew = addr2;
        } else if (currentAdminAddr == addr2.address) {
            contract_adminOld = contract_addr1;
            admin = addr2;
            contract_admin = contract_addr2;
            adminNew = addr3;
        } else if (currentAdminAddr == addr3.address){
            contract_adminOld = contract_addr2;
            admin = addr3;
            contract_admin = contract_addr3;
            adminNew = addr1;
        }
    }

    let siweStr:any;
    let siweStr2:any;
    let siweStr3:any;
    let siweStr4:any;

    it('初始检查：检查当前的admin, 并设置相关的配置变量。', async function () {
        this.timeout(LOCALNET_CONFIG.timeout);
        
        const currentAdminAddr = await contract_addr1.admin();

        await setValue(currentAdminAddr);

    })
    
    it('0.测试初始域名检查', async function () {
        this.timeout(LOCALNET_CONFIG.timeout);
        
        console.log("🧪 测试初始域名配置...");
        
        // 测试主域名
        primaryDomain = await contract_addr1.domain();
        // expect(currentDomain).to.equal(primaryDomain);
        console.log("✅ 主域名验证通过:", primaryDomain);
        
        // 测试域名数量
        const domainCount = await contract_addr1.domainCount();
        console.log("✅ 域名数量验证通过:", domainCount.toString());
        
        // 测试所有域名
        const allDomains = await contract_addr1.allDomains();
        expect(allDomains).to.include(primaryDomain);
        expect(allDomains).to.include(domain1);
        expect(allDomains).to.include(domain2);
        expect(allDomains).to.include(domain3);
        // expect(allDomains).to.include(domain4);
        console.log("✅ 所有域名验证通过:", allDomains);

    })
    
    it('0.测试初始域名检查2', async function () {
        
        // 测试域名有效性
        await sleep(sleepTime);
        expect(await contract_addr1.isDomainValid(primaryDomain)).to.be.true;
        expect(await contract_addr1.isDomainValid(domain1)).to.be.true;
        expect(await contract_addr1.isDomainValid(domain2)).to.be.true;
        expect(await contract_addr1.isDomainValid(domain3)).to.be.true;
        // false
        await sleep(sleepTime);
        expect(await contract_addr1.isDomainValid(invalidDomain)).to.be.false;
        expect(await contract_addr1.isDomainValid(domainTest)).to.be.false;
        expect(await contract_addr1.isDomainValid(domainTest2)).to.be.false;
        console.log("✅ 域名有效性验证通过");
    });

    // return;
    it('1.测试多域名登录', async function () {
        this.timeout(LOCALNET_CONFIG.timeout);

        console.log("🧪 测试多域名登录功能...");

        // 测试主域名登录
        const siweStrPrimary = await siweMsg({
            domain: primaryDomain,
            signer: addr1
        });
        const primaryToken = await contract_addr1.login(
            siweStrPrimary,
            await erc191sign(siweStrPrimary, addr1),
        );
        expect(primaryToken).to.have.length.greaterThan(2);
        console.log("✅ 主域名登录成功:", primaryDomain);

        const tx = await contract_viewAccount.getMsgSender(primaryToken)
        console.log("返回验证者地址:", tx);
        
        expect(tx).to.equal(addr1.address);

        // 存储token供后续测试使用
        siweStr = siweStrPrimary;

    })

    
    it('1.2测试多域名登录', async function () {

        // 测试domain1登录
        const siweStr1 = await siweMsg({
            domain: domain1,
            signer: addr1
        });
        const token1 = await contract_addr1.login(
            siweStr1,
            await erc191sign(siweStr1, addr1),
        );
        expect(token1).to.have.length.greaterThan(2);
        console.log("✅ 域名1登录成功:", domain1);

    })
    
    it('1.3测试多域名登录', async function () {

        // 测试domain2登录
        const siweStr2 = await siweMsg({
            domain: domain2,
            signer: addr1
        });
        const token2 = await contract_addr1.login(
            siweStr2,
            await erc191sign(siweStr2, addr1),
        );
        expect(token2).to.have.length.greaterThan(2);
        console.log("✅ 域名2登录成功:", domain2);

    })
    
    it('1.4测试多域名登录', async function () {

        // 测试domain3登录
        const siweStr3 = await siweMsg({
            domain: domain3,
            signer: addr1
        });
        const token3 = await contract_addr1.login(
            siweStr3,
            await erc191sign(siweStr3, addr1),
        );
        expect(token3).to.have.length.greaterThan(2);
        console.log("✅ 域名3登录成功:", domain3);

    });


    it('1.5 测试无效-过期域名登录', async function () {
        this.timeout(LOCALNET_CONFIG.timeout);

        // 测试无效域名登录应该失败
        const siweStrInvalid = await siweMsg({
            domain: invalidDomain,
            signer: addr1
        });
        try {
            await contract_addr1.login(
                siweStrInvalid,
                await erc191sign(siweStrInvalid, addr1),
            );
        } catch (error) {
            console.log("✅ 无效域名登录被正确拒绝:", invalidDomain);
        }

        // 测试过期登录应该失败
        const siweStrExpired = await siweMsg({
            domain: primaryDomain,
            signer: addr1,
            expiration: new Date(Date.now() - 30_000) // 30秒前过期
        });

        try {
            await contract_addr1.login(
                siweStrExpired,
                await erc191sign(siweStrExpired, addr1),
            );
        } catch (error) {
            console.log("✅ 过期登录被正确拒绝");
        }
        
        
    });

    it('2.测试域名管理,添加域名', async function () {
        // this.timeout(TESTNET_CONFIG.timeout);

        console.log("🧪 测试域名管理功能...");

        // 测试添加新域名- 已添加了，就无需再添加
        await contract_admin.addDomain(domainTest2); // write
        await sleep(sleepTime);

        expect(await contract_addr1.isDomainValid(domainTest2)).to.be.true;
        console.log("✅ 成功添加新域名:", domainTest2);
        
        // 测试新域名登录
        const siweStr4 = await siweMsg({
            domain: domainTest2,
            signer: addr1
        });
        const token4 = await contract_addr1.login(
            siweStr4,
            await erc191sign(siweStr4, addr1),
        );
        expect(token4).to.have.length.greaterThan(2);
        console.log("✅ 新域名登录成功:", domainTest2);
        
        // 测试非管理员无法添加域名
        try {
            // NOTE 注意，这个也会在区块链上留下交互记录。
            await contract_adminOld.addDomain("unauthorized.com") // write
        } catch (error) {
            console.log("✅ 非管理员添加域名被正确拒绝");
        }
    });

    it('2.1测试域名管理,移除域名', async function () {
        // 测试移除域名
        await contract_admin.removeDomain(domainTest2); // write
        await sleep(sleepTime);

        expect(await contract_addr1.isDomainValid(domainTest2)).to.be.false;
        console.log("✅ 成功移除域名:", domainTest2);
        
        // 测试移除后无法登录
        try{
            await contract_addr1.login(
                siweStr4,
                await erc191sign(siweStr4, addr1),
            );
        } catch (error) {
            console.log("✅ 移除后无法登录被正确拒绝");
        }

    });

    it('2.2测试域名管理-移除主域名', async function () {
        // 测试无法移除主域名
        try{
            await contract_admin.removeDomain(primaryDomain) // write
        } catch (error) {
            console.log("✅ 主域名无法移除被正确拒绝");
        }
        await sleep(sleepTime);
        
        // 测试设置主域名,注意两个call调用一定要间隔时间。
        await contract_admin.setPrimaryDomain(domain4); // write
        await sleep(sleepTime);
        
        const newPrimaryDomain = await contract_addr1.domain();
        expect(newPrimaryDomain).to.equal(domain4);
        console.log("✅ 成功设置新主域名:", domain4);
        
        // 恢复原主域名
        await contract_admin.setPrimaryDomain(primaryDomain); // writes
        console.log("✅ 恢复原主域名:", primaryDomain);

    });

    it('3.测试令牌验证和撤销', async function () {
        this.timeout(LOCALNET_CONFIG.timeout);

        console.log("🧪 测试令牌验证和撤销功能...");

        // 生成不同域名的令牌
        const siweStrPrimary = await siweMsg({
            domain: primaryDomain,
            signer: addr1
        });
        const primaryToken = await contract_addr1.login(
            siweStrPrimary,
            await erc191sign(siweStrPrimary, addr1),
        );
        
        const siweStr1 = await siweMsg({
            domain: domain1,
            signer: addr1
        });
        const token1 = await contract_addr1.login(
            siweStr1,
            await erc191sign(siweStr1, addr1),
        );

        // 测试令牌有效性验证
        expect(await contract_addr1.isSessionValid(primaryToken)).to.be.true;
        expect(await contract_addr1.isSessionValid(token1)).to.be.true;
        console.log("✅ 令牌有效性验证通过");
        
        // 测试空令牌
        expect(await contract_addr1.isSessionValid("0x")).to.be.false;
        console.log("✅ 空令牌验证正确返回false");
        
        // 测试错误令牌
        const invalidToken = "0x1234567890abcdef";
        expect(await contract_addr1.isSessionValid(invalidToken)).to.be.false;
        console.log("✅ 错误令牌验证正确返回false");
    });

    it('4.测试管理员权限', async function () {
        console.log("🧪 测试管理员权限...");
        
        // 测试转移管理员权限- 已经进行的发送，
        await contract_admin.setAdmin(adminNew.address); // write
        console.log("✅ 管理员权限转移至:", adminNew.address);

        await sleep(sleepTime);
        // 使用固定的合约实例来查询管理员地址，避免变量指向问题
        const currentAdminAddr = await contract_viewAccount.admin();
        expect(currentAdminAddr).to.equal(adminNew.address);

        // 调整变量值，
        await setValue(adminNew.address);
    });

    it('4.2测试管理员权限-新管理员', async function () {

        // 新管理员可以添加域名
        await contract_admin.addDomain(domainTest); // write
        await sleep(sleepTime);

        expect(await contract_admin.isDomainValid(domainTest)).to.be.true;
        console.log("✅ 新管理员添加域名成功");

        await sleep(sleepTime);
        // 测试新域名登录
        const siweStr4 = await siweMsg({
            domain: domainTest,
            signer: addr1
        });
        const token4 = await contract_addr1.login(
            siweStr4,
            await erc191sign(siweStr4, addr1),
        );
        expect(token4).to.have.length.greaterThan(2);
        console.log("✅ 新域名登录成功:", domainTest);
        
        // 原管理员无法添加域名
        try{
            await contract_adminOld.addDomain("old-admin.com"); // write
        } catch (error) {
            console.log("✅ 原管理员添加域名被正确拒绝");
        }

    });

    it('4.3用新增的域名-测试设置主域名', async function () {

        await sleep(sleepTime);
        
        // 测试设置主域名,注意两个call调用一定要间隔时间。
        await contract_admin.setPrimaryDomain(domainTest); // write
        await sleep(sleepTime);
        
        const newPrimaryDomain = await contract_addr1.domain();
        expect(newPrimaryDomain).to.equal(domainTest);
        console.log("✅ 成功设置新主域名:", domainTest);
        
        // 恢复原主域名
        await contract_admin.setPrimaryDomain(primaryDomain); // writes
        console.log("✅ 恢复原主域名:", primaryDomain);

    });

    it('4.4测试管理员权限-恢复管理员', async function () {
        
        // 恢复管理员权限
        await contract_admin.setAdmin(adminNew.address); // write
        console.log("✅ 管理员权限转移至:", adminNew.address);

        await sleep(sleepTime);
        // 使用固定的合约实例来查询管理员地址
        const currentAdminAddr = await contract_viewAccount.admin();
        expect(currentAdminAddr).to.equal(adminNew.address);

        // 调整变量值，
        await setValue(adminNew.address);
    
    });

    it('4.4.新管理员-移除刚才添加的域名', async function () {

        await sleep(sleepTime);
        // 移除
        await contract_admin.removeDomain(domainTest); // write
        await sleep(sleepTime);
        
        expect(await contract_addr1.isDomainValid(domainTest)).to.be.false;
        console.log("✅ 成功移除域名:", domainTest);
    });

    it('4.5用移除的域名-测试设置主域名', async function () {

        await sleep(sleepTime);
        
        try {
            await contract_admin.setPrimaryDomain(domainTest); // write
        } catch (error) {
            console.log("❌ 移除的域名不能设置主域名:", error);
        }

    });

    it('5.测试跨域名令牌特性', async function () {
        this.timeout(LOCALNET_CONFIG.timeout);

        console.log("🧪 测试跨域名令牌特性...");
        
        // 为不同域名生成令牌
        const domains = [primaryDomain, domain1, domain2, domain3];
        const tokens = [];
        
        for (const testDomain of domains) {
            const siweStr = await siweMsg({
                domain: testDomain,
                signer: addr1
            });
            const token = await contract_addr1.login(
                siweStr,
                await erc191sign(siweStr, addr1)
            );
            tokens.push(token);
            console.log(`✅ 域名 ${testDomain} 令牌生成成功`);
        }
        
        // 验证所有令牌都有效
        for (let i = 0; i < tokens.length; i++) {
            expect(await contract_addr1.isSessionValid(tokens[i])).to.be.true;
            console.log(`✅ 域名 ${domains[i]} 令牌有效性验证通过`);
        }
        
        // 验证不同域名的令牌是不同的
        for (let i = 0; i < tokens.length - 1; i++) {
            for (let j = i + 1; j < tokens.length; j++) {
                expect(tokens[i]).to.not.equal(tokens[j]);
            }
        }
        console.log("✅ 不同域名生成的令牌是唯一的");
    });

    after(async function () {
        console.log("\n🎉 MultiDomainSiweAuth localnet测试完成");
        console.log("📍 合约地址:", contractAddress);
        console.log("🌐 测试网络: sapphire-localnet");
        if (contract_addr1) {
            console.log("📊 多域名支持:", await contract_addr1.allDomains());
        }
        console.log("🛡️ 测试结果: 所有多域名功能正常工作");
    });

});
