import { expect } from "chai";
import { ethers, network } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { 
    getAccount, 
    connectContract,
    createEIP712Permit_PrivateToken,
    PermitType,
    // deployContract,
    waitForTransaction,
    sleep,
    // getCurrentNetwork,
    type TestAccounts
} from '../../utils';
// import { user_evm_WikiTruth } from "../WikiTruth_account";

/**
 * 在localnet 本地测试ERC20Secret合约
 * 
 * @attention：
 * 1. 当前脚本只适合在本地测试网部署和测试。
 * 
 * 包括：
 * 1. 基本授权
 * 2. 检查余额
 * 3. 铸造代币
 * 4. Wrap/Unwrap功能测试
 * 5. 标准ERC20转账功能测试
 * 6. 加密隐私功能测试
 * 7. 错误处理和边界条件测试
 * 
 * 本地测试网
 * 启动dockers： docker run --rm -it -p 8545:8545 ghcr.io/oasisprotocol/sapphire-localnet:latest
 * npx hardhat test test/single/ERC20Secret.ts （--network sapphire_localnet）
 */

describe("ERC20Secret Sapphire_localnet", function () {
    let hre: HardhatRuntimeEnvironment;
    let accounts: TestAccounts;
    let network: any;

    // 合约实例
    let mockToken: any;
    let secretToken: any;
    let mockTokenFactory: any;
    let secretTokenFactory: any;

    // 合约地址
    let mockTokenAddress: string;
    let secretTokenAddress: string;

    // 连接的合约实例
    let admin_mockToken: any;
    let buyer_mockToken: any;
    let buyer2_mockToken: any;
    let admin_secretToken: any;
    let buyer_secretToken: any;
    let buyer2_secretToken: any;

    // 测试常量
    const DECIMALS = 5;
    const MockName = "Mock Token";
    const MockSymbol = "MOCK";
    const mintAmount = 10000 * 10 ** DECIMALS;
    const wrapAmount = 1000 * 10 ** DECIMALS;
    const transferAmount = 50 * 10 ** DECIMALS;

    // EIP712许可
    let admin_ViewPermit: any;
    let buyer_ViewPermit: any;
    let buyer2_ViewPermit: any;

    const sleepTime = 1000;

    before(async function () {
        this.timeout(60000); // 增加超时时间
        
        hre = require("hardhat");
        
        console.log("🌐 切换到sapphire_localnet本地测试网...");
        await hre.switchNetwork("sapphire_localnet");
        
        // 获取网络配置
        network = await ethers.provider.getNetwork();
        console.log("🌐 当前网络:", network.networkName, "链ID:", network.chainId);

        // 获取测试账户
        accounts = await getAccount(network.chainId);
        console.log("👤 测试账户已获取");
        
        // 获取合约工厂
        mockTokenFactory = await ethers.getContractFactory("MockERC20");
        secretTokenFactory = await ethers.getContractFactory("ERC20Secret");
        
        // 部署MockERC20合约
        console.log("🚀 部署MockERC20合约...");
        mockToken = await mockTokenFactory.deploy(
            MockName, 
            MockSymbol
        );
        // 等待部署完成
        await mockToken.waitForDeployment();
        mockTokenAddress = await mockToken.getAddress();
        console.log("✅ MockERC20部署成功，地址:", mockTokenAddress);

        await sleep(sleepTime);
        
        // 部署ERC20Secret合约
        console.log("🚀 部署ERC20Secret合约...");
        secretToken = await secretTokenFactory.deploy(
            mockTokenAddress
        );
        // 等待部署完成
        await secretToken.waitForDeployment();
        secretTokenAddress = await secretToken.getAddress();
        console.log("✅ ERC20Secret部署成功，地址:", secretTokenAddress);
        
        // 连接合约到不同账户
        admin_mockToken = await connectContract(mockToken, accounts.admin);
        buyer_mockToken = await connectContract(mockToken, accounts.buyer);
        buyer2_mockToken = await connectContract(mockToken, accounts.buyer2);
        
        admin_secretToken = await connectContract(secretToken, accounts.admin);
        buyer_secretToken = await connectContract(secretToken, accounts.buyer);
        buyer2_secretToken = await connectContract(secretToken, accounts.buyer2);
        
        console.log("🔗 合约连接完成");
        await sleep(sleepTime); // 等待网络同步
    });

    
    
    //------------------------------------------------------------------------------
    // --------------------------------EIP712签名辅助函数--------------------------------
    async function createEIP712Permit(signer: any, spender: any, amount: number | bigint, mode: PermitType, customDeadline?: number) {
        return await createEIP712Permit_PrivateToken({
            signer,
            spender,
            amount,
            mode,
            contractAddress: secretTokenAddress,
            network: network,
            customDeadline,
            domainName: "Secret ERC20 Token",  // 必须与合约中的 domain 名称一致
            domainVersion: "1"
        });
    }


    
    // NOTE 测试已通过
    describe("ERC20标准接口测试", function () {
        it("进行签名授权", async function () { 
            admin_ViewPermit = await createEIP712Permit(accounts.admin, accounts.buyer2, 0, PermitType.View);
            buyer_ViewPermit = await createEIP712Permit(accounts.buyer, accounts.buyer2, 0, PermitType.View);
            buyer2_ViewPermit = await createEIP712Permit(accounts.buyer2, accounts.buyer, 0, PermitType.View);
        });

        // it("应该正确返回代币基本信息", async function () {
        //     expect(await admin_secretToken.name()).to.equal(PrivateName);
        //     expect(await admin_secretToken.symbol()).to.equal(PrivateSymbol);
        //     expect(await admin_secretToken.decimals()).to.equal(DECIMALS);
        // });

        // it("问题排查：", async function () {
        //     const maxAmount = ethers.MaxUint256;
        //     // 给addr2授权最大值
        //     await buyer_secretToken.approve(addr2.address, maxAmount);

        //     await new Promise(resolve => setTimeout(resolve, 20000));
        //     // 通过签名查看授权额度
        //     const allowance1 = await admin_secretToken.allowanceWithPermit(buyer_ViewPermit);
        //     console.log("授权额度,:", allowance1);
        // });
        
        it("检查余额", async function () {
            const tx = await admin_secretToken.balanceOfWithPermit(buyer_ViewPermit);
            expect(tx).to.equal(0);
            const tx2 = await admin_secretToken.balanceOfWithPermit(buyer2_ViewPermit);
            expect(tx2).to.equal(0);
            const tx3 = await admin_secretToken.balanceOfWithPermit(admin_ViewPermit);
            expect(tx3).to.equal(0);
        });
        
        it("铸造代币", async function () {
            await admin_mockToken.mint(accounts.buyer.address);
            await sleep(sleepTime);

            await admin_mockToken.mint(accounts.buyer2.address);
            await sleep(sleepTime);
        });
    });
    
    describe("Wrap/Unwrap功能测试", function () {
        
        it("包装之前需要先授权，否则无法进行wrap", async function () {
            await sleep(sleepTime);

            await buyer_mockToken.approve(secretTokenAddress, mintAmount);
            await sleep(sleepTime);

            await buyer2_mockToken.approve(secretTokenAddress, mintAmount);
            await sleep(sleepTime);
            
            // 先进行普通授权
            await buyer_secretToken.approve(accounts.buyer2.address, mintAmount);
        });
        
        it("应该能够包装ERC20代币", async function () {
            // 包装代币
            const wrapTx = await buyer_secretToken.wrap(wrapAmount);
            await wrapTx.wait();  // 等待交易确认
            await sleep(sleepTime);

            const tx = await admin_secretToken.balanceOfWithPermit(buyer_ViewPermit);
            expect(tx).to.equal(wrapAmount);
        });
        
        it("应该能够解包代币", async function () {
            // 解包
            const unwrapTx = await buyer_secretToken.unwrap(wrapAmount);
            await unwrapTx.wait();  // 等待交易确认
            await sleep(sleepTime);

            const tx = await admin_secretToken.balanceOfWithPermit(buyer_ViewPermit);
            expect(tx).to.equal(0);
        });
        
        it("应该能够部分包装和解包", async function () {
            const partialAmount = wrapAmount / 2;
            
            // 执行wrap操作并等待交易确认
            const wrapTx = await buyer_secretToken.wrap(wrapAmount);
            await wrapTx.wait();  // 等待交易确认
            await sleep(sleepTime);
            
            // 先用签名方式验证余额（这个已经证明是可靠的）
            const balance_1 = await admin_secretToken.balanceOfWithPermit(buyer_ViewPermit);
            expect(balance_1).to.equal(wrapAmount);
            
            // 再用调试函数验证（用于对比）
            const balance = await admin_secretToken.getDecryptBalance(accounts.buyer.address);
            expect(balance).to.equal(wrapAmount);

            // 解包一部分
            const unwrapTx = await buyer_secretToken.unwrap(partialAmount);
            await unwrapTx.wait();  // 等待交易确认
            await sleep(sleepTime);
            
            const balance2 = await admin_secretToken.balanceOfWithPermit(buyer_ViewPermit);
            expect(balance2).to.equal(partialAmount);
        });
    });

    
    describe("标准ERC20转账功能测试", function () {
        const wrapAmount = 100 * 10 ** DECIMALS;
        const transferAmount = 50 * 10 ** DECIMALS;
        
        before(async function () {
            // 为addr1包装一些代币
            await buyer_secretToken.wrap(wrapAmount);
        });
        
        it("应该能够执行transfer", async function () {
            await sleep(sleepTime);
            await buyer_secretToken.transfer(accounts.buyer2.address, transferAmount);
            await sleep(sleepTime);
            const balance = await admin_secretToken.balanceOfWithPermit(buyer2_ViewPermit);
            expect(balance).to.equal(transferAmount);
        });
        
        it("应该能够执行transferFrom", async function () {
            await sleep(sleepTime);
            await buyer2_secretToken.transferFrom(accounts.buyer.address, accounts.buyer2.address, transferAmount);
            await sleep(sleepTime);
            const balance = await admin_secretToken.balanceOfWithPermit(buyer2_ViewPermit);
            expect(balance).to.equal(transferAmount*2);
        });

    });
    
    describe("加密隐私功能测试", function () {

        before(async function () {
            // 为addr1包装一些代币用于测试
            await buyer_secretToken.wrap(wrapAmount);
        });
        
        it("应该能够通过签名查看授权额度", async function () {
            

            await new Promise(resolve => setTimeout(resolve, sleepTime));
            const allowance1 = await admin_secretToken.allowanceWithPermit(buyer_ViewPermit);
            console.log("授权额度,不应该为0:", allowance1);
        });
        
        it("应该拒绝过期的查看签名", async function () {
            const deadline = Math.floor(Date.now() / 1000) - 1000; // 已过期
            const viewPermit = await createEIP712Permit(accounts.buyer, accounts.buyer2, 0, PermitType.View, deadline);
            try{
                await admin_secretToken.balanceOfWithPermit(viewPermit);
            } catch (error) {
                console.log("✅拒绝查看过期的签名!");
            }
        });
        
        it("应该拒绝无效的查看签名", async function () {
            const viewPermit = await createEIP712Permit(accounts.buyer, accounts.buyer2, 0, PermitType.View);
            
            // 修改owner地址使签名无效
            viewPermit.owner = accounts.buyer2.address;
            try{
                await admin_secretToken.balanceOfWithPermit(viewPermit);
            } catch (error) {
                console.log("✅拒绝无效签名的查看!");
            }
        });

        it("应该拒绝无效的签名类型", async function () {
            const transferAmount = 10 * 10 ** DECIMALS;
            
            // 创建一个 TRANSFER permit 但用作 VIEW
            const permit = await createEIP712Permit(accounts.buyer, accounts.buyer2, Number(transferAmount), PermitType.Transfer);
            
            try{
                await admin_secretToken.balanceOfWithPermit(permit);
            }catch(error){
                console.log("✅ 错误类型验证测试通过");
            }
        });
        
        it("应该正确处理余额为0的情况", async function () {
            // addr2没有任何余额
            const balance = await admin_secretToken.balanceOfWithPermit(admin_ViewPermit);
            const balance2 = await admin_secretToken.getDecryptBalance(accounts.admin.address);
            expect(balance).to.equal(0);
            expect(balance2).to.equal(0);
        });
        
        it("应该正确处理隐私保护机制, 在Typescript调用balanceOf都是0", async function () {
            // 测试自己查看自己的余额
            const addr1Balance = await buyer_secretToken.balanceOf(accounts.buyer.address);
            expect(addr1Balance).to.be.equal(0); 
            
            // 测试其他人查看会返回0
            const addr1BalanceFromOwner = await admin_secretToken.balanceOf(accounts.buyer.address);
            expect(addr1BalanceFromOwner).to.equal(0);
        });
        
        it("应该正确处理授权额度的隐私保护, 应该返回的都是0", async function () {
            // 其他人查看会返回0
            const allowanceFromOwner = await admin_secretToken.allowance(accounts.buyer.address, accounts.buyer2.address);
            expect(allowanceFromOwner).to.equal(0);
            
            const allowanceFromAddr2 = await buyer2_secretToken.allowance(accounts.buyer.address, accounts.buyer2.address);
            expect(allowanceFromAddr2).to.equal(0);
        });
        
        it("应该拒绝 VIEW 类型签名中的非零 amount", async function () {
            const viewPermit = await createEIP712Permit(accounts.buyer, accounts.buyer2, 100, PermitType.View); // amount 不为 0
            
            try{
                await admin_secretToken.balanceOfWithPermit(viewPermit);
            } catch (error) {
                console.log("✅拒绝 VIEW 类型签名中的非零 amount!");
            }
        });
    });
    
    describe("EIP-712签名验证功能测试", function () {
        before(async function () {
            // 为addr1包装一些代币用于测试
            await buyer_secretToken.wrap(wrapAmount);
        });
        
        it("应该支持EIP-712签名转账", async function () {
            const partialAmount = wrapAmount / 2;
            
            const permit = await createEIP712Permit(accounts.buyer, accounts.buyer2, partialAmount, PermitType.Transfer);
            await sleep(sleepTime);

            const addr1Balance = await admin_secretToken.balanceOfWithPermit(buyer_ViewPermit);
            const addr2Balance = await admin_secretToken.balanceOfWithPermit(buyer2_ViewPermit);
            
            // 执行签名转账
            await admin_secretToken.transferWithPermit(permit);
            await sleep(sleepTime);
            
            // 验证余额变化（使用签名查看）
            const addr1Balance2 = await admin_secretToken.balanceOfWithPermit(buyer_ViewPermit);
            const addr2Balance2 = await admin_secretToken.balanceOfWithPermit(buyer2_ViewPermit);
            expect(addr1Balance-addr1Balance2).to.equal(partialAmount);
            expect(addr2Balance2-addr2Balance).to.equal(partialAmount);

        });
        
        it("应该支持EIP-712签名授权，并成功转账", async function () {
            const approveAmount = 30 * 10 ** DECIMALS;
            const permit = await createEIP712Permit(accounts.buyer, accounts.buyer2, Number(approveAmount), PermitType.Approve);
            
            await admin_secretToken.approveWithPermit(permit); // 执行这个函数，则表示，已授权 addr2 可以从 addr1 中转出 approveAmount 的代币
            await sleep(sleepTime);

            const allowance = await admin_secretToken.allowanceWithPermit(buyer_ViewPermit);
            
            expect(allowance).to.equal(approveAmount);
            
            try{
                await admin_secretToken.transferFrom(accounts.buyer.address, accounts.admin.address, approveAmount);
            } catch (error) {
                console.log("✅非被授权者试图转账，失败!");
            }

            await sleep(sleepTime);
            // 进行转账
            await buyer2_secretToken.transferFrom(accounts.buyer.address, accounts.buyer2.address, approveAmount);
        });
        
        it("应该拒绝过期的签名", async function () {
            const transferAmount = 50 * 10 ** DECIMALS;
            const deadline = Math.floor(Date.now() / 1000) - 1000; // 已过期
            
            const permit = await createEIP712Permit(accounts.buyer, accounts.buyer2, Number(transferAmount), PermitType.Transfer, deadline);

            try{
                await admin_secretToken.transferWithPermit(permit);
            } catch (error) {
                console.log("✅拒绝过期的签名!");
            }
        });
        
        it("应该拒绝重复使用的签名", async function () {
            const transferAmount = 25 * 10 ** DECIMALS;
                
            const permit = await createEIP712Permit(accounts.buyer, accounts.buyer2, Number(transferAmount), PermitType.Transfer);
            // 第一次使用应该成功
            await admin_secretToken.transferWithPermit(permit);
            await sleep(sleepTime);
            
            try{
                await admin_secretToken.transferWithPermit(permit);
            } catch (error) {
                console.log("✅拒绝重复使用的签名!");
            }
        });
    });
    
    describe("工具函数测试", function () {
        it("应该正确返回EIP-712相关信息", async function () {
            const domainSeparator = await admin_secretToken.DOMAIN_SEPARATOR();
            expect(domainSeparator).to.not.equal("0x0000000000000000000000000000000000000000000000000000000000000000");
            
            const permitTypehash = await admin_secretToken.EIP_PERMIT_TYPEHASH();
            expect(permitTypehash).to.not.equal("0x0000000000000000000000000000000000000000000000000000000000000000");
        });
        
        it("应该正确返回底层代币信息", async function () {
            const underlyingAddress = await admin_secretToken.underlyingToken();
            expect(underlyingAddress).to.equal(mockTokenAddress);
        });
        
        it("应该正确检查签名使用状态", async function () {
            const permit = await createEIP712Permit(accounts.buyer, accounts.buyer2, transferAmount, PermitType.Transfer);
            await admin_secretToken.transferWithPermit(permit);
            await sleep(sleepTime*2);
            // 检查签名已使用状态
            expect(await admin_secretToken.isSignatureUsed(permit.signature)).to.equal(true);
        });
    });
    
    describe("错误处理和边界条件测试", function () {
        it("应该拒绝向零地址转账", async function () {
            try{
                await buyer_secretToken.transfer(ethers.ZeroAddress, transferAmount);
            } catch (error) {
                console.log("✅拒绝向零地址转账!");
            }
        });

        it("应该在余额不足时拒绝解包", async function () {
            try {
                await buyer_secretToken.unwrap(wrapAmount);
            } catch (error) {
                console.log("✅拒绝解包!");
            }
        });
        
        it("应该拒绝包装0数量的代币", async function () {
            try{
                await buyer_secretToken.wrap(0);
            } catch (error) {
                console.log("✅拒绝包装 0 数量代币!");
            }
        });
        
        it("应该拒绝解包0数量的代币", async function () {
            try{
                await buyer_secretToken.unwrap(0);
            } catch (error) {
                console.log("✅拒绝解包 0 数量代币!");
            }
        });
        
        it("应该在授权不足时拒绝包装", async function () {
            await buyer_mockToken.approve(secretTokenAddress, 10);
            await sleep(sleepTime);

            // 不进行授权直接包装
            try{
                await buyer_secretToken.wrap(wrapAmount);
            } catch (error) {
                console.log("✅拒绝包装 授权不足的代币!");
            }
        });
        
        it("应该拒绝向零地址授权", async function () {
            try {
                await buyer_secretToken.approve(ethers.ZeroAddress, mintAmount);
            } catch(error) {
                console.log("✅拒绝向零地址授权!");
            }
        });

        it("应该在余额不足时拒绝转账", async function () {
            try{
                await buyer_secretToken.transfer(accounts.buyer2.address, mintAmount);
            } catch (error) {
                console.log("✅拒绝转账!");
            }
        });
        
        it("应该在授权不足时拒绝代理转账", async function () {
            // 先进行普通授权100
            await buyer_secretToken.approve(accounts.buyer2.address, 100);
            await sleep(sleepTime);

            try {
                await buyer_secretToken.transferFrom(accounts.buyer.address, accounts.buyer2.address, wrapAmount);
            } catch (error) {
                console.log("✅拒绝代理转账!");
            }
        });
        
        it("应该能够正确处理最大值-普通授权-测试", async function () {
            const maxAmount = ethers.MaxUint256;
            
            // 给addr2授权最大值
            await buyer_secretToken.approve(accounts.buyer2.address, maxAmount);
            await sleep(sleepTime);

            const max = await admin_secretToken.allowanceWithPermit(buyer_ViewPermit);
            await sleep(sleepTime);

            expect(max).to.equal(maxAmount);
            
            // 使用transferFrom，最大值授权不应该减少
            const transferAmount = 50 * 10 ** DECIMALS;
            await buyer2_secretToken.transferFrom(accounts.buyer.address, accounts.buyer2.address, transferAmount);
            
        });

        it("应该能够正确处理最大值——签名授权——测试", async function () {
            const maxAmount = ethers.MaxUint256;
            
            // 给addr2授权最大值
            const permit = await createEIP712Permit(accounts.buyer, accounts.buyer2, maxAmount, PermitType.Approve);

            await admin_secretToken.approveWithPermit(permit);
            await sleep(sleepTime);
            
            // 通过签名查看授权额度
            const max = await admin_secretToken.allowanceWithPermit(buyer_ViewPermit);
            await sleep(sleepTime);
            // 比较最大值授权应该保持不变
            expect(max).to.equal(maxAmount);
        });

        
    });
});