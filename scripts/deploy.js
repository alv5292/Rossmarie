const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log(`🚀 Deploying with: ${deployer.address} (Balance: ${ethers.formatEther(balance)} CELO)`);

  const RossmariePass = await ethers.getContractFactory("RossmariePass");
  const contract = await RossmariePass.deploy(
    "ipfs://bafkreifbakymyhehgzvbu5viwbej7kibw2p6pbkdzhcb3ffex3df5xspky"
  );

  // Wait for 1 confirmation
  await contract.waitForDeployment();
  const address = await contract.getAddress();
  console.log(`✅ Contract deployed to: ${address}`);

  // Optional: verify
  if (process.env.CELOSCAN_API_KEY) {
    console.log("🔍 Verifying on CeloScan...");
    await hre.run("verify:verify", {
      address,
      constructorArguments: [
        "ipfs://bafkreifbakymyhehgzvbu5viwbej7kibw2p6pbkdzhcb3ffex3df5xspky",
      ],
    });
    console.log("✅ Verified on CeloScan");
  } else {
    console.warn("⚠️ Skipping verification: CELOSCAN_API_KEY not set");
  }
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exitCode = 1;
});
