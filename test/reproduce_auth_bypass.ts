
import { expect } from 'chai';
import { ethers } from 'hardhat';
import '@nomicfoundation/hardhat-chai-matchers';
import { 
    siweMsg, 
    erc191sign,
} from '../utils/getSiweAuth';
import { sleep} from '../utils/common';
import {getAccount, } from '../utils/getAccount'

describe('Reproduction: Unlisted Domain Login', function () {
    let accounts: any;
    let siweAuthContract: any;
    let contractAddress: string;
    let addr1: any;
    
    // Domains
    const primaryDomain = "example.com";
    const validDomains = [primaryDomain];
    const attackerDomain = "attacker.com";

    before(async function () {
        this.timeout(60000);
        
        console.log("🚀 Starting Reproduction Test...");

        // Ensure we are on a network that supports this (e.g., sapphire_localnet or hardhat)
        // For simplicity, we assume the environment is set up correctly for sapphire or we mock it if needed.
        // But since the project uses sapphire-contracts, we likely need sapphire network.
        // We will try to run on whatever network is default (likely hardhat or sapphire_localnet)
        
        const network = await ethers.provider.getNetwork();
        console.log("🌐 Network:", network.name, "Chain ID:", network.chainId);

        accounts = await getAccount(Number(network.chainId));
        addr1 = accounts.admin;

        // Deploy SiweAuth
        const contractFactory = await ethers.getContractFactory("contracts/SiweAuth.sol:SiweAuth");
        siweAuthContract = await contractFactory.deploy(
            primaryDomain,
            validDomains
        );
        await siweAuthContract.waitForDeployment();
        contractAddress = await siweAuthContract.getAddress();
        console.log("✅ SiweAuth deployed at:", contractAddress);
        
        await sleep(1000);
    });

    it('Should allow login with valid domain', async function () {
        const siweStrPrimary = await siweMsg({
            domain: primaryDomain,
            signer: addr1,
            chainId: Number((await ethers.provider.getNetwork()).chainId)
        });
        
        const token = await siweAuthContract.login(
            siweStrPrimary,
            await erc191sign(siweStrPrimary, addr1),
        );
        expect(token).to.have.length.greaterThan(2);
        console.log("✅ Valid domain login success");
    });

    it('Should REJECT login with unlisted domain (Attacker)', async function () {
        const siweStrAttacker = await siweMsg({
            domain: attackerDomain,
            signer: addr1,
            chainId: Number((await ethers.provider.getNetwork()).chainId)
        });
        
        console.log("Testing with attacker domain:", attackerDomain);
        
        try {
            await siweAuthContract.login(
                siweStrAttacker,
                await erc191sign(siweStrAttacker, addr1),
            );
            console.error("❌ FAILURE: Attacker domain login SUCCEEDED (Should have failed)");
            expect.fail("Attacker domain login should have failed");
        } catch (error: any) {
            if (error.message.includes("Attacker domain login should have failed")) {
                throw error;
            }
            console.log("✅ SUCCESS: Attacker domain login failed as expected");
            // console.log("Error details:", error.message);
        }
    });
});
