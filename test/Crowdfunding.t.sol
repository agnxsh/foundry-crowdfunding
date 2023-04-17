// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "src/Crowdfunding.sol";

contract CrowdfundingTest is Test{
    Crowdfunding public crowdFunding;

    address bob = address(0x1);
    address alice = address(0x2);

    function setUp() public{
        //this works like the beforeEach() function like in js,
        //we will create an instance of the crowdfunding contract 
        //we will also assign alice with some ether to donate 
        crowdFunding = new Crowdfunding();
        vm.deal(alice, 1000);
    }

    //testing the createCampaign() function
    function testCreateCampaign() public{
        //call the createCampaign() function with bob's address and store the returned id in a variable
        uint256 id = crowdFunding.createCampaign(
            address(bob),
            "Test",
            "Test Description",
            100,
            block.timestamp + 10000,
            "https://i.kym-cdn.com/photos/images/newsfeed/002/205/307/1f7.jpg"

        );
        //log the id, a feature of foundry
        emit log_uint(id);
        //different way of logging, named logging
        emit log_named_uint("id",id);
        //for the first campaign, the id should be 0
        assertEq(id, 0);
    }

    //Testing the donateToCampaign() function
    function testDonateToCampaign() public{
        uint256 id = crowdFunding.createCampaign(
            address(bob),
            "Test",
            "Test Description",
            100,
            block.timestamp + 10000,
            "https://i.kym-cdn.com/photos/images/newsfeed/002/205/307/1f7.jpg"
        );

    //this is a cheat code in Foundry, we will use the vm.prank(address) function to make alice
    //the msg.sender for the next call
    vm.prank(alice);
    //from now on alice will be the msg.sender while calling functions
    //alice will now call the donateToCampaign() function with the id of the campaign she wants to
    //donate to
    crowdFunding.donateToCampaign{value: 100}(id);

    uint256 contractBalance = address(crowdFunding).balance;
    //after donating, the contract balance should be 100
    assertEq(contractBalance, 100);
    }

    function testWithdraw() public {
        uint256 id = crowdFunding.createCampaign(
            address(bob),
            "Test",
            "Test Description",
            100,
            block.timestamp + 10000,
            "https://i.kym-cdn.com/photos/images/newsfeed/002/205/307/1f7.jpg"
        );
        //emit balance of bob
        uint256 bobBalance = address(bob).balance;
        emit log_named_uint("Bob's original balance", bobBalance);

        //alice will donate to the campaign
        vm.prank(alice);
        //emit balance of alice after the donation
        emit log_named_uint(
            "Alice's balance before donation",
            address(alice).balance
        );

        crowdFunding.donateToCampaign{value: 100}(id);
        //emit balance of alice after donation
        emit log_named_uint(
            "Alice's balance after donation",
            address(alice).balance
        );

        //bob will withdraw funds
        vm.prank(bob);
        //we are now using a cheat code to warp the time to 10001 seconds after the current time,
        //so that the campaign deadline is passed
        vm.warp(block.timestamp + 10001);
        crowdFunding.withdraw(id);

        //emit balance of bob after withdrawal
        uint256 bobBalanceAfterWithdrawal = address(bob).balance;
        emit log_named_uint(
            "Bob's balance after withdrawal",
            bobBalanceAfterWithdrawal
        );

        //When Bob started he had 0 in his address, then he created a campaign and alice donated 
        //100 to the campaign, so bob's balance should be 100 after withdrawal
        assertEq(bobBalanceAfterWithdrawal, bobBalance + 100);
        //after withdrawal, the contract balance should be 0
        assertEq(address(crowdFunding).balance,0);
    }

    //Testing the getCampaign() function
    function testGetCampaign() public{
        uint256 id = crowdFunding.createCampaign(
            address(bob),
            "Test",
            "Test Description",
            1000,
            block.timestamp + 10000,
            "https://i.kym-cdn.com/photos/images/newsfeed/002/205/307/1f7.jpg"
        );
        vm.prank(alice);
        crowdFunding.donateToCampaign{value: 100}(id);
        (
            address owner,
            string memory title,
            string memory description,
            uint256 target,
            uint256 deadline,
            uint256 amountCollected,
            string memory image
        ) = crowdFunding.getCampaign(id);
        assertEq(owner, address(bob));
        assertEq(title, "Test");
        assertEq(description, "Test Description");
        assertEq(target, 1000);
        assertEq(deadline, block.timestamp + 10000);
        assertEq(
            image,
            "https://i.kym-cdn.com/photos/images/newsfeed/002/205/307/1f7.jpg"
        );
        assertEq(amountCollected, 100);
    }

    // Testing the withdraw() function when the deadline has not passed yet
    // This function should revert
    // We are using vm.expectRevert() to check if the function reverts
    function testWithdrawFailBeforeDeadline() public{
        uint256 id = crowdFunding.createCampaign(
            address(bob),
            "Test",
            "Test Description",
            100,
            block.timestamp + 10000,
            "https://i.kym-cdn.com/photos/images/newsfeed/002/205/307/1f7.jpg"
        );

        //alice will donate to the campaign
        vm.prank(alice);
        crowdFunding.donateToCampaign{value: 100}(id);
         
        //bob will try to withdraw the funds before the deadline
        vm.prank(bob);
        //we are now using a cheat code in Foundry to warp the time to 9999 seconds
        //as we have mentioned in our contract that if 10000 seconds have not passed
        //since the block.timestamp then the deadline hasn't passed yet
        vm.warp(block.timestamp + 9999); 
        vm.expectRevert("The deadline has not passed yet.");
        crowdFunding.withdraw(id);
    }
}