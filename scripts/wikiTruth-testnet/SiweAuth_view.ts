import { ethers } from "hardhat";
import {
    user_evm_WikiTruth
} from "../../WikiTruth_account";
import { wikiTruth_contracts_address } from "../utils/wikiTruth_contracts_address";
import { getSiweMsg, erc191sign } from "../utils/SiweAuth";
import { boxList } from "../../private/boxList";

/**
 * 
 * @returns 使用SIWE验证身份，并读取TruthBox合约数据
 * 
 * 实现流程：
 * 1. 创建一个SIWE消息
 * 2. 使用signer签名SIWE消息
 * 3. 调用SiweAuth合约的login函数获取认证token
 * 4. 使用token调用TruthBox合约的getPrivateData函数读取私密数据
 * 
 * 运行命令：npx hardhat run scripts/wikiTruth-testnet/SiweAuth_view.ts --network sapphire-testnet
 */

const primaryDomain = "wikitruth.eth.limo";
const chainId = 23295; // sapphire-testnet

async function main() {
    console.log("🚀 开始使用SIWE认证读取TruthBox合约数据...");

    // 检查chainId 
    const network = await ethers.provider.getNetwork();
    console.log("🌐 当前网络ID:", network.chainId);
    if (Number(network.chainId) !== chainId) {
        console.error("❌ 当前网络ID不是23295，请检查网络ID");
        return;
    }

    // 获取签名者账户
    const privateKey = user_evm_WikiTruth.minter.privateKey;
    if (!privateKey) {
        console.error("❌ privateKey不存在，请检查配置");
        return;
    }
    const signer = new ethers.Wallet(privateKey, ethers.provider);
    const signerAddress = await signer.getAddress();
    console.log("👤 签名者地址:", signerAddress);

    // =========================== 第一步：获取SiweAuth合约 ==================================
    console.log("\n📝 第一步：获取SiweAuthWikiTruth合约...");
    const siweAuth = await ethers.getContractAt("SiweAuthWikiTruth", wikiTruth_contracts_address.siweAuth);
    const siweAuthConnected = siweAuth.connect(signer) as any;
    
    // 验证域名是否有效
    const isValidDomain = await siweAuth.isDomainValid(primaryDomain);
    if (!isValidDomain) {
        console.error(`❌ 域名 ${primaryDomain} 无效，请先添加到合约中`);
        return;
    }
    console.log(`✅ 域名 ${primaryDomain} 验证通过`);

    // =========================== 第二步：生成SIWE消息并签名 ==================================
    console.log("\n🔐 第二步：生成SIWE消息并签名...");
    
    // 设置过期时间（24小时后）
    const expiration = new Date();
    expiration.setHours(expiration.getHours() + 24);
    
    // 生成SIWE消息
    const siweMessage = await getSiweMsg(
        primaryDomain,
        signer,
        chainId,
        expiration,
        `I accept the WikiTruth Terms of Service: https://${primaryDomain}/tos`
    );
    console.log("✅ SIWE消息生成成功");
    
    // 签名SIWE消息
    const signature = await erc191sign(siweMessage, signer);
    console.log("✅ SIWE消息签名成功");

    await new Promise(resolve => setTimeout(resolve, 2000));

    // =========================== 第三步：调用login函数获取认证token ==================================
    console.log("\n🔑 第三步：调用SiweAuth合约login函数获取认证token...");
    try {
        const authToken = await siweAuthConnected.login(siweMessage, signature);
        console.log("✅ 登录成功，获取到认证token");
        console.log("   Token长度:", authToken.length, "bytes");
        
        // 验证token是否有效
        const isTokenValid = await siweAuth.isSessionValid(authToken);
        if (!isTokenValid) {
            console.error("❌ Token验证失败");
            return;
        }
        console.log("✅ Token验证通过");

        // 获取token对应的用户地址
        const tokenSender = await siweAuth.getMsgSender(authToken);
        console.log("   Token对应的用户地址:", tokenSender);
        console.log("   签名者地址:", signerAddress);
        if (tokenSender.toLowerCase() !== signerAddress.toLowerCase()) {
            console.warn("⚠️ Token用户地址与签名者地址不匹配");
        } else {
            console.log("✅ Token用户地址验证通过");
        }

        await new Promise(resolve => setTimeout(resolve, 2000));

        // =========================== 第四步：使用token读取TruthBox合约数据 ==================================
        console.log("\n📦 第四步：使用token读取TruthBox合约数据...");
        const contractAddress = wikiTruth_contracts_address.truthBox;
        const truthBox = await ethers.getContractAt("TruthBox", contractAddress);
        const truthBoxConnected = truthBox.connect(signer) as any;

        // 读取多个box的数据
        for (let i = 0; i < boxList.length; i++) {
            const box = boxList[i];
            const boxId = box.boxId;
            
            console.log(`\n📋 读取 Box ${boxId} 的数据...`);
            
            try {
                // 读取公开数据（不需要token）
                const [status, price, deadline] = await truthBox.getBasicData(boxId);
                console.log(` ✅ 公开数据读取成功:`);
                console.log(` - Price: ${price}`);
                
                // 读取私密数据（需要token）
                try {
                    const privateData = await truthBoxConnected.getPrivateData(boxId, authToken);
                    console.log(`   ✅ 私密数据读取成功:`);
                    if (privateData.length > 0) {
                        console.log(` - 数据内容: ${privateData}`);
                    }
                } catch (error: any) {
                    console.log(`   ⚠️ 私密数据读取失败: ${error.message || error}`);
                    // 可能的原因：不是minter/buyer，或者状态不允许读取
                }
                
            } catch (error: any) {
                console.log(`   ❌ Box ${boxId} 数据读取失败: ${error.message || error}`);
            }
            
            await new Promise(resolve => setTimeout(resolve, 10000));
        }

        console.log("\n✅ 所有数据读取完成！");

    } catch (error: any) {
        console.error("❌ 登录失败:", error.message || error);
        if (error.reason) {
            console.error("   原因:", error.reason);
        }
        return;
    }
}

// 运行部署脚本
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("失败:", error);
        process.exit(1);
    });
