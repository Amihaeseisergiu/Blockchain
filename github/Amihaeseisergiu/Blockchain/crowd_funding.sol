// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;

import './sponsor_funding.sol';

contract CrowdFunding {
    struct Contributor {
        string name;
        uint contributedSum;
    }

    uint public fundingGoal;

    mapping(address => Contributor) private contributors;
    address private contractOwnerAddress;
    uint private state;
    bool private distributed;

    modifier contractOwnerAccess() {
        require(msg.sender == contractOwnerAddress, "Access restricted to the contract owner!");
        _;
    }

    modifier inState(uint givenState) {
        require(state == givenState, "Crowd funding not in the correct state!");
        _;
    }

    modifier verifyWithdrawedSum(uint sum) {
        require(sum <= contributors[payable(msg.sender)].contributedSum,
            "Can't withdraw a sum bigger than the one contributed!");
        _;
    }

    modifier notDistributed() {
        require(!distributed, "Already distributed to share holders!");
        _;
    }

    constructor(uint givenFundingGoal)
    {
        state = 0;
        fundingGoal = givenFundingGoal;
        contractOwnerAddress = msg.sender;
    }

    function getRaisedSum()
    external
    view
    returns(uint raisedSum)
    {
        return address(this).balance;
    }

    function getState()
    public
    view 
    returns(string memory currentState, uint currentStateInt)
    {
        //A mapping would be more elegant, but it costs more gas :(
        if(state == 0) {
            return ("nonfinanced", state);
        } else if(state == 1) {
            return ("prefinanced", state);
        } else if(state == 2) {
            return ("financed", state);
        }

        require(false, "Unknown state");
    }

    function contribute(string calldata name)
    inState(0)
    external
    payable
    {
        address payable contributorAddress = payable(msg.sender);
        Contributor memory contributor = Contributor(name, msg.value);

        //Add the previous contributed sum if the contributor already exists
        contributor.contributedSum += contributors[contributorAddress].contributedSum;
        contributors[contributorAddress] = contributor;

        if(address(this).balance >= fundingGoal) {
            state = 1;
        }
    }

    function withdraw(uint sum)
    inState(0)
    verifyWithdrawedSum(sum)
    external
    {
        address payable contributorAddress = payable(msg.sender);
        contributors[contributorAddress].contributedSum -= sum;
        contributorAddress.transfer(sum);
    }

    function finalizeCollectingSum(address sponsorFundingAddress)
    inState(1)
    contractOwnerAccess()
    external
    {
        (bool success, ) = payable(sponsorFundingAddress).call
            (abi.encodeWithSignature("sponsor()"));
        require(success, "Getting financed by a sponsor failed!");
        state = 2;
    }

    function distribute(address distributeFundingAddress)
    inState(2)
    contractOwnerAccess()
    notDistributed()
    external
    {
        (bool success, ) = payable(distributeFundingAddress).call
            {value: address(this).balance}
            (abi.encodeWithSignature("receiveFunds()"));
        require(success, "Distributing funds failed!");

        distributed = true;
    }

    receive()
    external
    payable
    {

    }
}
