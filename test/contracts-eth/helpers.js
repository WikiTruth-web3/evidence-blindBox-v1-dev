// test/helpers/TimeHelpers.js
const { expect } = require("chai");
const { network, ethers } = require("hardhat");

// 直接定义Status枚举，与Solidity合约中保持一致
const Status = {
    Storing: 0,
    Selling: 1,
    Auctioning: 2,
    Paid: 3,
    Refunding: 4,
    Delaying: 5,
    Published: 6,
    Blacklisted: 7
};

const TimeHelpers = {
    // 验证时间差是否在预期范围内
    verifyTimeDifference(actualDiff, expectedDiff, allowedDelta = 10, message = "") {
        expect(actualDiff).to.be.closeTo(
            expectedDiff,
            allowedDelta,
            message || `Time difference should be approximately ${expectedDiff} seconds`
        );
    },

    // 验证截止时间
    verifyDeadline(deadline, baseTime, expectedDiff, allowedDelta = 10) {
        const actualDiff = Number(deadline) - Number(baseTime);
        this.verifyTimeDifference(
            actualDiff,
            expectedDiff,
            allowedDelta,
            "Deadline is not within expected range"
        );
    },

    // 推进区块链时间
    // async advanceTime(seconds) {
    //     await network.provider.send("evm_increaseTime", [seconds]);
    //     await network.provider.send("evm_mine");
    // },

    // // 推进到特定截止日期
    // async advanceToDeadline(deadline) {
    //     const now = (await ethers.provider.getBlock("latest")).timestamp;
    //     const timeToAdvance = Number(deadline) - now;
    //     if (timeToAdvance > 0) {
    //         await this.advanceTime(timeToAdvance);
    //     }
    // },

    // // 快速推进常用时间周期
    // async advanceDays(days) {
    //     await this.advanceTime(days * 24 * 60 * 60);
    // },


};

// 2. 状态处理辅助函数
// const StatusHelpers = {
//     // 验证代币状态
//     async verifyTokenStatus(truthBox, tokenId, expectedStatus) {
//         const status = await truthBox.getStatus(tokenId);
//         expect(status).to.equal(expectedStatus);
//     },

//     // 验证时间戳存在
//     async verifyTimestampExists(exchange, tokenId, timestampGetter) {
//         const timestamp = await timestampGetter(tokenId);
//         expect(timestamp).to.not.equal(0);
//     },

// };

module.exports = {
    Status,
    ...TimeHelpers
};