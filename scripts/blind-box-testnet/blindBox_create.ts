import { ethers } from "hardhat";
import { getSigners_SapphireTestnet } from "../utils/signers-sapphire-testnet";
import { ContractRunner } from "../utils/contract-runner";
import { CallFunctionParams } from "../types/call-params";
import { boxList } from "../../secret/boxList";
import { box_private_key } from "../../secret/box-private-key";

/**
 * 运行命令：npx hardhat run scripts/blind-box-testnet/blindBox_create.ts --network sapphire-testnet
 */

// ⚙️ 断点续跑配置：
// 如果之前执行在某个 index 中断了（例如在 index = 3 处失败），可以将此处改为对应的索引值（如 3），
// 脚本启动时就会自动排除该索引之前（已成功）的所有铸造任务，直接从该 index 开始往后执行。
const START_INDEX = 0;

async function main() {
    console.log(`🚀 开始执行 BlindBox 批量创建任务... (起始索引配置为: ${START_INDEX})`);

    const { minterSigner } = await getSigners_SapphireTestnet();
    if (!minterSigner) {
        console.error("❌ 未找到有效的 minter 签名者，请检查签名者配置");
        return;
    }

    // 编排批量铸造任务清单 (应用筛选条件排除之前成功的 index)
    const tasks: CallFunctionParams[] = boxList
        .map((box, index) => ({ box, index }))
        .filter(({ index }) => index >= START_INDEX)
        .map(({ box, index }) => {
            const boxCID = box.metadataBoxCID;
            // 将 price 转换成合约支持的 18位 decimals 单位 (ROSE/ERC20)
            const boxPrice = ethers.parseEther(box.price.toString());

            if (box.mintMethod === 'create') {
                const key = box_private_key[index];
                if (!key) {
                    throw new Error(`❌ 盲盒 #${index} (ID: ${box.boxId}) 缺少对应的私钥，请在 box-private-key.ts 中配置`);
                }

                return {
                    taskName: `[Create] 铸造盲盒 #${index} (ID: ${box.boxId})`,
                    contractsName: "BlindBox",
                    functionName: "create",
                    params: [boxCID, key, boxPrice],
                    signer: minterSigner
                } as CallFunctionParams;
            } else {
                return {
                    taskName: `[Create & Publish] 铸造并发布盲盒 #${index} (ID: ${box.boxId})`,
                    contractsName: "BlindBox",
                    functionName: "createAndPublish",
                    params: [boxCID],
                    signer: minterSigner
                } as CallFunctionParams;
            }
        });

    console.log(`[BlindBox] 筛选后待执行任务数: ${tasks.length} (总数: ${boxList.length})`);

    if (tasks.length === 0) {
        console.log("⚠️ 没有需要执行的任务，请检查 START_INDEX 配置。");
        return;
    }

    // 执行批量任务，设置 8000ms 间隔以适应 Sapphire Testnet
    await ContractRunner.executeBatch(tasks, 8000);

    console.log("\n✅ BlindBox 批量铸造任务全部成功执行完毕！");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ 批量铸造执行失败:", error);
        process.exit(1);
    });
