const { ethers } = require("hardhat");
const { CRYPTO_DEVS_NFT_CONTRACT_ADDRESS } = require("../constants");

async function main() {
  // Deploy the FakeNFTMarketplace contract first
  const FakeNFTMarketplace = await ethers.getContractFactory(
    "FakeNFTMarketplace"
  );
  const fakeNFTMarketplace = await FakeNFTMarketplace.deploy();
  await fakeNFTMarketplace.deployed();
  console.log("FakeNFTMarketplace deployed at", fakeNFTMarketplace.address);

  // Now deploy the CryptoDevsDAO contract
  const CryptoDevsDAO = await ethers.getContractFactory("CryptoDevsDAO");
  const cryptoDevsDAO = await CryptoDevsDAO.deploy(
    fakeNFTMarketplace.address,
    CRYPTO_DEVS_NFT_CONTRACT_ADDRESS,
    {
      // Change this value as you want
      value: ethers.utils.parseEther("0.01"),
    }
  );
  await cryptoDevsDAO.deployed();
  console.log("CryptoDevsDAO deployed at", cryptoDevsDAO.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// ALCHEMY_API_KEY_URL = "https://eth-goerli.alchemyapi.io/v2/NtwSByKmv68UiwyPNiJgPLQQ2ZCMPmhl"
// FakeNFTMarketplace deployed at 0x6E34729Ddf26643Cc2abFCf209947fBe1852E5B7
// CryptoDevsDAO deployed at 0xcFbBdd0148f45043860eA9D05d915eead4feEfaC

// Rinkeby
// FakeNFTMarketplace deployed at 0x7c54b8E925E9ab26e5fEbAa56d2748dB80beE71A
// CryptoDevsDAO deployed at 0x1dBF12cDde49115e04b85325c08F243c5E639076
