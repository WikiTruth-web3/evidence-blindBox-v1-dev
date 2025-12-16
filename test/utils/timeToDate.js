const {
    // time,
    loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");


function secondsToDhms(seconds) {
    // const y = Math.floor(seconds / (3600 * 24 * 365));
    const d = Math.floor(seconds / (3600 * 24));
    const h = Math.floor((seconds % (3600 * 24)) / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    return [d, h, m, s].map(num => (`0${num}`).slice(-2)).join(':');
}

// 示例使用
// const seconds = 3600 * 24 * 365 + 3600 * 15 + 60 * 30 + 45; // 一年零十五天零三十分零四十五秒
// console.log(secondsToDhms(seconds)); // 将输出 "01:00:00:00"


function timestampToDate(timestamp) {
    // 将时间戳乘以1000以转换为毫秒
    const date = new Date(timestamp * 1000);

    // 格式化日期为字符串（也可以根据需要自定义格式）
    const options = {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        timeZoneName: 'short'
    };

    return date.toLocaleString('zh-CN', options); // 输出中文格式
}

// 示例使用
// const timestamp = 1761445254.856; // 例：1761445254.856
// const dateStr = convertTimestampToDate(timestamp);
// console.log(dateStr);

module.exports = {
    timestampToDate,
    secondsToDhms
};