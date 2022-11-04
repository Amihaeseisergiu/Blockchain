// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;

import './crowd_funding.sol';

contract SponsorFunding {
    uint public sponsorPercentage;
    address private contractOwnerAddress;

    modifier contractOwnerAccess()
    {
        require(msg.sender == contractOwnerAddress, "Access restricted to the contract owner!");
        _;
    }

    modifier validPercentage(uint percentage)
    {
        require(percentage <= 100, "Sponsor percentage should be between 0 and 100!");
        _;
    }

    modifier verifyCrowdFundingPrefinanced()
    {
        address payable crowdFundingAddress = payable(msg.sender);
        CrowdFunding crowdFunding = CrowdFunding(crowdFundingAddress);
        (, uint state) = crowdFunding.getState();

        require(state == 1, "Crowd funding not prefinanced!");
        _;
    }

    constructor(uint initialSponsorPercentage)
    validPercentage(initialSponsorPercentage)
    payable
    {
        contractOwnerAddress = msg.sender;
        sponsorPercentage = initialSponsorPercentage;
    }

    function getBalance()
    view
    external
    returns(uint balance)
    {
        return address(this).balance;
    }

    function updateSponsoringDetails(uint newSponsorPercentage)
    contractOwnerAccess()
    validPercentage(newSponsorPercentage)
    external
    payable
    {
        sponsorPercentage = newSponsorPercentage;
    }

    function sponsor()
    verifyCrowdFundingPrefinanced()
    external
    {
        address payable crowdFundingAddress = payable(msg.sender);
        
        uint nullifier = 1;
        if(sponsorPercentage * crowdFundingAddress.balance / 100 > address(this).balance) {
            nullifier = 0;
        }

        //Using call since the transfer may fail
        crowdFundingAddress.transfer(nullifier * sponsorPercentage * crowdFundingAddress.balance / 100);
    }
}
