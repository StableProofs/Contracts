const StableProofs = artifacts.require("StableProofs");

contract("StableProofs test", async accounts => {
    it("should send ETH to the fallback function", async () => {
        const instance = await StableProofs.deployed();
        await instance.sendTransaction({from: accounts[0], to: instance.address, value:'100000000000000000'})
        const balance = await web3.eth.getBalance(instance.address);
        assert.equal(Number(balance), Number(100000000000000000));
    });

    it("should drain ETH from the contract", async () => {
        const instance = await StableProofs.deployed();
        await instance.withdrawFees('100000000000000000', accounts[0]);
        const balance = await web3.eth.getBalance(instance.address);
        assert.equal(Number(balance), Number(0));
    });

    it("should mint QED to the address that calls it", async () => {
        const instance = await StableProofs.deployed();
        const amount = 100000000000000000;
        await instance.mint(accounts[1], {value: amount, from: accounts[0]})
        const price = await instance.price();
        const toBalance = await instance.balanceOf(accounts[1])
        const mintAmount = (amount * .99) * (price / 100)
        assert.equal(Number(toBalance), mintAmount);
    });

    it("should pause the contract", async () => {
        const instance = await StableProofs.deployed();
        const isPausedFalse = await instance.isPaused()
        assert.equal(isPausedFalse, false);
        await instance.pauseContract({from: accounts[0]});
        const isPausedTrue = await instance.isPaused()
        assert.equal(isPausedTrue, true);
    });

    it("should unpause the contract", async () => {
        const instance = await StableProofs.deployed();
        const isPausedTrue = await instance.isPaused()
        assert.equal(isPausedTrue, true);
        await instance.unpauseContract({from: accounts[0]});
        const isPausedFalse = await instance.isPaused()
        assert.equal(isPausedFalse, false);
    });

    it("should return the total supply of QED", async () => {
        const instance = await StableProofs.deployed();
        const supply = await instance.totalSupply();
        const toBalance = await instance.balanceOf(accounts[1]);
        assert.equal(Number(toBalance), Number(supply));
    });

    it("should update the admin address", async () => {
        const instance = await StableProofs.deployed();
        await instance.updateAdminAddress(accounts[1], {from: accounts[0]});
        const admin1 = await instance.admin();
        assert.equal(admin1, accounts[1]);
        await instance.updateAdminAddress(accounts[0], {from: accounts[1]});
        const admin0 = await instance.admin();
        assert.equal(admin0, accounts[0]);
    });

    it("should update the admin fee", async () => {
        const instance = await StableProofs.deployed();
        await instance.updateAdminFee('2000000000000000000', {from: accounts[0]});
        const fee = await instance.adminFee();
        assert.equal(Number(fee), Number(2000000000000000000));
    });

    it("should approve an address to spend tokens resulting in an allowance", async () => {
        const instance = await StableProofs.deployed();
        await instance.approve(accounts[0], '2000000000000000000', {from: accounts[1]});
        const allowance = await instance.allowance(accounts[1], accounts[0]);
        assert.equal(allowance, Number(2000000000000000000));
    });

    it("should transfer tokens from one address to another", async () => {
        const instance = await StableProofs.deployed();
        await instance.transferFrom(accounts[1], accounts[0], '2000000000000000000', {from: accounts[0]});
        let balance = await instance.balanceOf(accounts[0]);
        assert.equal(balance, Number(2000000000000000000));
        await instance.transfer(accounts[1], '2000000000000000000', {from: accounts[0]})
        balance = await instance.balanceOf(accounts[0]);
        assert.equal(balance, Number(0));
    });

  });