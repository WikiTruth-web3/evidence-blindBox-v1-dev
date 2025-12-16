import { expect } from "chai";
import { ethers } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

/**
 * Sapphire 加密功能诊断测试
 * 
 * 用于检查 Sapphire 本地网络是否正确支持加密功能
 * 
 * 运行方式：
 * npx hardhat test test/diagnostic/sapphire-test.ts --network sapphire_localnet
 */

describe("Sapphire 加密功能诊断", function () {
    let hre: HardhatRuntimeEnvironment;
    let testContract: any;
    let owner: any;

    before(async function () {
        this.timeout(60000);
        
        hre = require("hardhat");
        
        console.log("🌐 切换到sapphire_localnet本地测试网...");
        await hre.switchNetwork("sapphire_localnet");
        
        const network = await ethers.provider.getNetwork();
        console.log("📡 网络信息 - chainId:", network.chainId, "name:", network.name);
        
        // 获取测试账户
        [owner] = await ethers.getSigners();
        console.log("👤 测试账户:", owner.address);
    });

    describe("1. 基础网络连接测试", function () {
        it("应该能够获取区块号", async function () {
            const blockNumber = await ethers.provider.getBlockNumber();
            console.log("✅ 当前区块号:", blockNumber);
            expect(blockNumber).to.be.gte(0);
        });

        it("应该能够获取账户余额", async function () {
            const balance = await ethers.provider.getBalance(owner.address);
            console.log("✅ 账户余额:", ethers.formatEther(balance), "ETH");
            expect(balance).to.be.gt(0);
        });
    });

    describe("2. Sapphire 加密功能测试", function () {
        it("应该能够部署使用加密功能的合约", async function () {
            const MockERC20Factory = await ethers.getContractFactory("MockERC20");
            const mockToken = await MockERC20Factory.connect(owner).deploy("Test Token", "TEST");
            await mockToken.waitForDeployment();
            
            const mockAddress = await mockToken.getAddress();
            console.log("✅ MockERC20 部署成功:", mockAddress);

            const ERC20SecretFactory = await ethers.getContractFactory("ERC20Secret");
            testContract = await ERC20SecretFactory.connect(owner).deploy(mockAddress);
            await testContract.waitForDeployment();
            
            const contractAddress = await testContract.getAddress();
            console.log("✅ ERC20Secret 部署成功:", contractAddress);
        });

        it("应该能够获取全局 nonce", async function () {
            try {
                const nonce = await testContract.getGlobalNonce();
                console.log("✅ 全局 Nonce:", nonce);
                expect(nonce).to.not.equal("0x0000000000000000000000000000000000000000000000000000000000000000");
            } catch (error: any) {
                console.error("❌ 获取 Nonce 失败:", error.message);
                throw error;
            }
        });

        it("应该能够读取加密余额（即使为0）", async function () {
            try {
                const balance = await testContract.getDecryptBalance(owner.address);
                console.log("✅ 解密余额成功:", balance.toString());
                expect(balance).to.equal(0);
            } catch (error: any) {
                console.error("❌ 解密余额失败:", error.message);
                console.error("这表明 Sapphire 的加密功能不可用！");
                throw error;
            }
        });

        it("应该能够读取加密的原始数据", async function () {
            try {
                const rawData = await testContract.getEncryptedBalanceRaw(owner.address);
                console.log("✅ 原始加密数据长度:", rawData.length);
            } catch (error: any) {
                console.error("❌ 读取加密数据失败:", error.message);
                throw error;
            }
        });
    });

    describe("3. 环境验证总结", function () {
        it("环境检查报告", async function () {
            console.log("\n" + "=".repeat(60));
            console.log("📊 Sapphire 环境诊断报告");
            console.log("=".repeat(60));
            
            const network = await ethers.provider.getNetwork();
            console.log("🌐 网络: sapphire_localnet");
            console.log("🔗 链ID:", network.chainId.toString());
            console.log("👤 测试账户:", owner.address);
            
            if (testContract) {
                console.log("📝 测试合约:", await testContract.getAddress());
                
                try {
                    const nonce = await testContract.getGlobalNonce();
                    const balance = await testContract.getDecryptBalance(owner.address);
                    
                    console.log("\n✅ 加密功能状态: 正常");
                } catch (error) {
                    console.log("\n❌ 加密功能状态: 异常");
                }
            }
            
            console.log("=".repeat(60) + "\n");
        });
    });
});

