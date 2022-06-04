const hre = require("hardhat");
const { CRYPTODEVS_NFT_CONTRACT_ADDRESS } = require("../constants");

async function main() {
    const fakeNFTMarketplaceFactory = await hre.ethers.getContractFactory("FakeNFTMarketplace");
    const fakeNFTMarketplaceContract = await fakeNFTMarketplaceFactory.deploy();
    await fakeNFTMarketplaceContract.deployed();

    const cryptodevsDaoFactory = await hre.ethers.getContractFactory("CryptodevsDAO");
    const cryptodevsDaoFactoryContract = await cryptodevsDaoFactory.deploy(
        fakeNFTMarketplaceContract.address,
        CRYPTODEVS_NFT_CONTRACT_ADDRESS,
        {
            value: hre.ethers.utils.parseEther("0.0001")
        });
    await cryptodevsDaoFactoryContract.deployed();
    console.log(cryptodevsDaoFactoryContract.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });