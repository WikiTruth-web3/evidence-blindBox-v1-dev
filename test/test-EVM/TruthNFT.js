// 测试TruthNFT合约中的功能，比如发送、加入黑名单、移除黑名单、设置URI\CID等操作。
const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { deployTruthBoxFixture } = require("./Fixture.js");
const { Status } = require("./helpers.js");

describe("TruthNFT测试", function () {
    // 测试发送NFT功能
    it("应该能正确转移NFT", async function () {
        const {
            minter, buyer, other, admin, dao, address_zero,
            truthNFT, truthBox_minter, truthBox_buyer, truthBox_DAO,
            nft_minter, nft_buyer, nft_other, exchange_minter, exchange_buyer
        } = await loadFixture(deployTruthBoxFixture);

        // 检查初始所有者
        expect(await truthNFT.ownerOf(0)).to.equal(minter.address);

        // 完成交易
        await exchange_minter.sell(0, address_zero, 2000);
        await exchange_buyer.buy(0);
        await exchange_buyer.completeOrder(0);

        // 转移NFT
        await nft_minter.transferFrom(minter.address, buyer.address, 0);

        // 验证转移后的所有者
        expect(await truthNFT.ownerOf(0)).to.equal(buyer.address);

        // 从buyer转到other
        await nft_buyer.transferFrom(buyer.address, other.address, 0);
        expect(await truthNFT.ownerOf(0)).to.equal(other.address);
    });

    // 测试加入黑名单功能
    it("应该能正确加入黑名单", async function () {
        const {
            minter, buyer, admin, dao,
            truthNFT, truthBox, truthBox_minter,
            nft_minter, nft_DAO,truthBox_DAO
        } = await loadFixture(deployTruthBoxFixture);

        // 初始状态下，NFT不应在黑名单中
        expect(await truthBox.isInBlacklist(0)).to.equal(false);
        expect(await truthBox.isInBlacklist(1)).to.equal(false);

        // 只有DAO可以加入黑名单
        await expect(truthBox_minter.addBoxToBlacklist(0)).to.be.revertedWithCustomError(truthBox, "NotDAO");

        // DAO加入黑名单
        await truthBox_DAO.addBoxToBlacklist(0);
        await truthBox_DAO.addBoxToBlacklist(1);

        // 验证黑名单状态
        expect(await truthBox.isInBlacklist(0)).to.equal(true);
        expect(await truthBox.isInBlacklist(1)).to.equal(true);
        expect(await truthBox.isInBlacklist(2)).to.equal(false);

        // 当NFT在黑名单中时，不能转移
        await expect(nft_minter.transferFrom(minter.address, buyer.address, 0))
            .to.be.reverted;
    });

    // 测试黑名单对TruthBox操作的影响
    it("黑名单NFT应该无法在TruthBox中执行操作", async function () {
        const {
            minter, buyer, admin, dao,
            truthNFT, truthBox, truthBox_minter, address_zero,
            exchange_minter, testToken,truthBox_DAO
        } = await loadFixture(deployTruthBoxFixture);

        // 加入黑名单
        await truthBox_DAO.addBoxToBlacklist(0);

        // 黑名单中的NFT不能出售
        await expect(exchange_minter.sell(0, address_zero, 2000)).to.be.reverted;

        // 黑名单中的NFT不能拍卖
        await expect(exchange_minter.auction(0, address_zero, 2000)).to.be.reverted;

        // 黑名单中的NFT不能查看信息 TODO: 暂时不需要这个函数
        // await expect(truthBox.getBoxInfoCID(0)).to.be.reverted;

    });

    // 测试设置URI功能
    it("应该能正确设置token URI-黑名单无法查看", async function () {
        const {
            minter, admin, dao,truthBox,
            truthNFT, truthBox_minter,truthBox_DAO,
            nft_minter, nft_DAO
        } = await loadFixture(deployTruthBoxFixture);

        // 检查初始URI
        expect(await truthNFT.tokenURI(0)).to.equal("ipfs://00_tokenURIfleek.app");

        // 只有Admin可以设置
        await expect(nft_DAO.setNetwork("https://", "truth.app")).to.be.revertedWithCustomError(truthNFT, "NotAdmin");

        // 铸造者设置URI
        await truthNFT.setNetwork("https://", ".truth.app");
        expect(await truthNFT.tokenURI(0)).to.equal("https://00_tokenURI.truth.app");

        // 加入黑名单--无法查看URI
        await truthBox_DAO.addBoxToBlacklist(0);
        await expect(nft_DAO.tokenURI(0)).to.be.revertedWithCustomError(truthNFT, "InBlacklist");

    });

    // 此处添加设置logoCID 的设置
    // 测试设置logoCID功能
    // it("应该能正确设置和查询logoCID", async function () {
    //     const {
    //         minter, admin, dao,
    //         truthNFT, truthBox_minter,
    //         nft_minter, nft_DAO, 
    //     } = await loadFixture(deployTruthBoxFixture);

    //     // 先设置网络和后缀以便测试完整的URI
    //     await truthNFT.setNetwork("https://", ".truth.app");

    //     // 非管理员不能设置logoCID
    //     await expect(nft_minter.setLogoCID("new_logo_cid")).to.be.revertedWithCustomError(truthNFT, "NotAdmin");
    //     await expect(nft_DAO.setLogoCID("new_logo_cid")).to.be.revertedWithCustomError(truthNFT, "NotAdmin");

    //     // 管理员可以设置logoCID
    //     await truthNFT.setLogoCID("test_logo_cid");

    //     // 验证logoURI返回正确的完整URI
    //     expect(await truthNFT.logoURI()).to.equal("https://test_logo_cid.truth.app");

    //     // 更新logoCID并再次验证
    //     await truthNFT.setLogoCID("updated_logo_cid");
    //     expect(await truthNFT.logoURI()).to.equal("https://updated_logo_cid.truth.app");
    // });

    

    // 测试totalSupply和多个铸造
    it("应该能正确跟踪NFT的totalSupply", async function () {
        const {
            minter, buyer, admin, dao,truthBox,bytes_mint,
            truthNFT, truthBox_minter, truthBox_buyer
        } = await loadFixture(deployTruthBoxFixture);

        // 初始供应量应该为0
        expect(await truthNFT.totalSupply()).to.equal(6);

        // 铸造多个NFT
        await truthBox_minter.create(minter.address, "test_tokenURI_1", "test_infoURI_1", bytes_mint, 1000);
        expect(await truthNFT.totalSupply()).to.equal(7);

        await truthBox_minter.create(minter.address, "test_tokenURI_2", "test_infoURI_2", bytes_mint, 2000);
        expect(await truthNFT.totalSupply()).to.equal(8);

        await truthBox_minter.create(minter.address, "test_tokenURI_3", "test_infoURI_3", bytes_mint, 3000);
        expect(await truthNFT.totalSupply()).to.equal(9);

    });

    // 测试将truthBox铸造给其他人, 其他人是否能够将truthNFT转移发送
    it("铸造时将NFT发送给其他人，接收者应该能够转移NFT", async function () {
        const {
            minter, buyer, admin, other, other2,truthBox,bytes_mint,nft_minter,
            truthNFT, truthBox_minter, nft_other, exchange_minter, exchange_buyer,
            address_zero,
        } = await loadFixture(deployTruthBoxFixture);

        // 铸造NFT给other用户
        await truthBox_minter.create(other.address, "test_recipient_tokenURI", "test_recipient_infoURI", bytes_mint, 1000);
        const newId = Number(await truthNFT.totalSupply()) - 1;
        
        // 验证owner是other
        expect(await truthNFT.ownerOf(newId)).to.equal(other.address);

        // 完成交易
        await exchange_minter.sell(newId, address_zero, 2000);
        await exchange_buyer.buy(newId);
        await exchange_buyer.completeOrder(newId);
        
        // minter 无法转移NFT
        await expect(nft_minter.transferFrom(other.address, buyer.address, newId)).to.be.reverted;
        // other用户应该能够转移NFT给other2
        await nft_other.transferFrom(other.address, other2.address, newId);

        // 验证转移成功
        expect(await truthNFT.ownerOf(newId)).to.equal(other2.address);
        
    });
    
});





