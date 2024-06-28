const { ethers } = require("hardhat");

const { expect } = require("chai");

describe("Migrations contract", function () {
  it("Deployment should set the owner address", async function () {
    const [owner] = await ethers.getSigners();

    const program = await ethers.deployContract("Migrations");
    expect(await program.owner()).to.equal(owner.address);
  });
  it("Should set lastCompletedMigration", async function () {
    const [owner] = await ethers.getSigners();

    const program = await ethers.deployContract("Migrations");
    await program.connect(owner).setCompleted(5);
    const lastCompletedMigration = await program.lastCompletedMigration();
    expect(await lastCompletedMigration).to.equal(5);
  });
  it("Should fail since sender is not restricted", async function () {
    const [owner, adrr1] = await ethers.getSigners();

    const program = await ethers.deployContract("Migrations");
    await expect(program.connect(adrr1).setCompleted(4)).to.be.revertedWith("Only owner can migrate the contract");
    const lastCompletedMigration = await program.lastCompletedMigration();
    expect(await lastCompletedMigration).to.equal(0);
  });
  it("Should fail since sender is not restricted 2", async function () {
    const [owner, adrr1] = await ethers.getSigners();

    const program = await ethers.deployContract("Migrations");
    await expect(program.connect(adrr1).upgrade(owner.address)).to.be.revertedWith("Only owner can migrate the contract");
    const lastCompletedMigration = await program.lastCompletedMigration();
    expect(await lastCompletedMigration).to.equal(0);
  });

});