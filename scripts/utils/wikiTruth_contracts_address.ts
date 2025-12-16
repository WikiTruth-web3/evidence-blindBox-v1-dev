import deploymentInfo from "../../deployments/sapphire_testnet.json";
import deploymentImplementation from "../../deployments/sapphire_testnet_implementation.json";



export const wikiTruth_contracts_address = {
    addressManager: deploymentInfo.AddressManager_Proxy,
    truthBox: deploymentInfo.TruthBox_Proxy,
    truthNFT: deploymentInfo.TruthNFT_Proxy,
    exchange: deploymentInfo.Exchange_Proxy,
    fundManager: deploymentInfo.FundManager_Proxy,
    userId: deploymentInfo.UserId_Proxy,
    siweAuth: deploymentInfo.SiweAuth,
    wroseSecret: deploymentInfo.WROSESecret,
    officialToken: deploymentInfo.OfficialToken,
    officialToken_Secret: deploymentInfo.OfficialToken_ERC20Secret,
};

export const wikiTruth_testnet_contracts = [
    {
        name: "AddressManager",
        contract: "AddressManager",
        address: deploymentInfo.AddressManager_Proxy,
        implementation: deploymentImplementation.AddressManager_Implementation,
    },
    {
        name: "TruthBox",
        contract: "TruthBox",
        address: deploymentInfo.TruthBox_Proxy,
        implementation: deploymentImplementation.TruthBox_Implementation,
    },
    {
        name: "TruthNFT",
        contract: "TruthNFT",
        address: deploymentInfo.TruthNFT_Proxy,
        implementation: deploymentImplementation.TruthNFT_Implementation,
    },
    {
        name: "Exchange",
        contract: "Exchange",
        address: deploymentInfo.Exchange_Proxy,
        implementation: deploymentImplementation.Exchange_Implementation,
    },
    {
        name: "FundManager",
        contract: "FundManager",
        address: deploymentInfo.FundManager_Proxy,
        implementation: deploymentImplementation.FundManager_Implementation,
    },
    {
        name: "UserId",
        contract: "UserId",
        address: deploymentInfo.UserId_Proxy,
        implementation: deploymentImplementation.UserId_Implementation,
    },
    {
        name: "SiweAuthWikiTruth",
        contract: "SiweAuthWikiTruth",
        address: deploymentInfo.SiweAuth,
        // implementation: '',
    },
    {
        name: "WROSEsecret",
        symbol: "wROSE.S",
        contract: "WROSEsecret",
        address: deploymentInfo.WROSESecret,
        // implementation: '',
    },
    {
        name: "OfficialToken",
        symbol: "WTRC",
        contract: "MockERC20",
        address: deploymentInfo.OfficialToken,
        // implementation: '',
    },
    {
        name: "OfficialToken_ERC20Secret",
        symbol: "WTRC.S",
        contract: "ERC20Secret",
        address: deploymentInfo.OfficialToken_ERC20Secret,
        // implementation: '',
    },
]


