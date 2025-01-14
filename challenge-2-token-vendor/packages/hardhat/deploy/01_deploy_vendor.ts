import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const deployVendor: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  // First deploy YourToken
  const yourTokenDeployment = await deploy("YourToken", {
    from: deployer,
    args: [],
    log: true,
  });

  console.log("Deployer address:", deployer);
  console.log("Token address:", yourTokenDeployment.address);

  // Deploy the Vendor contract with the correct token address
  const vendorDeployment = await deploy("Vendor", {
    from: deployer,
    args: [yourTokenDeployment.address],
    log: true,
  });

  console.log("Vendor contract deployed to:", vendorDeployment.address);

  try {
    // Get contract instances
    const yourToken = await hre.ethers.getContractAt("YourToken", yourTokenDeployment.address);
    const vendor = await hre.ethers.getContractAt("Vendor", vendorDeployment.address);
    
    // Transfer ownership of the Vendor contract to the deployer
    await vendor.transferOwnership(deployer);
    console.log("Vendor ownership transferred to deployer");
    
    // Check deployer's balance first
    const deployerBalance = await yourToken.balanceOf(deployer);
    console.log("Deployer token balance:", hre.ethers.formatEther(deployerBalance));

    // Only transfer if deployer has enough tokens
    if (deployerBalance >= hre.ethers.parseEther("1000")) {
      // Transfer tokens to the vendor
      const transferAmount = hre.ethers.parseEther("1000");
      console.log(`Attempting to transfer ${hre.ethers.formatEther(transferAmount)} tokens to Vendor...`);
      
      const tx = await yourToken.transfer(vendorDeployment.address, transferAmount);
      await tx.wait();
      
      console.log("Tokens transferred to Vendor successfully");

      // Verify the transfer
      const vendorBalance = await yourToken.balanceOf(vendorDeployment.address);
      console.log("Vendor token balance:", hre.ethers.formatEther(vendorBalance));
    } else {
      console.log("Deployer doesn't have enough tokens to transfer to Vendor");
      console.log("Make sure tokens are being minted in the YourToken constructor");
    }

  } catch (error) {
    console.error("Error in deployment:", error);
  }
};

export default deployVendor;
deployVendor.tags = ["Vendor"];