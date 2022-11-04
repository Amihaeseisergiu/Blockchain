// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;

import './crowd_funding.sol';

contract DistributeFunding {
    struct ShareHolder {
        uint8 percentage;
        bool withdrawed;
    }

    mapping(address => ShareHolder) private shareHolders;
    uint private totalShareHoldersPercentage;
    bool private fundingReceived;
    uint private baseSum;

    modifier validateShareHolder(uint shareHolderPercentage) {
        require(!fundingReceived, "Can't become a shareholder after the funds have been received!");
        require(shareHolderPercentage <= 100, "Shareholder percentage should be between 0 and 100!");

        //Substract the old percentage in case the shareholder exists. Otherwise it is 0 and it won't have any effect
        totalShareHoldersPercentage -= shareHolders[payable(msg.sender)].percentage;
        require(totalShareHoldersPercentage + shareHolderPercentage <= 100,
            "Total sponsor percentage of shareholders surpasses 100!");
        _;
    }

    modifier canWithdraw() {
        require(fundingReceived, "Can't withdraw. Wait to receive the funds from crowd funding!");
        require(!shareHolders[payable(msg.sender)].withdrawed, "Already withdrawed!");
        _;
    }

    modifier verifyFundingNotReceived() {
        require(!fundingReceived, "Funding already received!");
        _;
    }

    modifier verifyCrowdFundingFinanced() {
        address payable crowdFundingAddress = payable(msg.sender);
        CrowdFunding crowdFunding = CrowdFunding(crowdFundingAddress);
        (, uint state) = crowdFunding.getState();

        require(state == 2, "Crowd funding not financed!");
        _;
    }

    function becomeShareHolder(uint8 shareHolderPercentage)
    validateShareHolder(shareHolderPercentage)
    external
    {
        ShareHolder memory shareHolder = ShareHolder(shareHolderPercentage, false);

        shareHolders[payable(msg.sender)] = shareHolder;
        totalShareHoldersPercentage += shareHolderPercentage;
    }

    function receiveFunds()
    verifyFundingNotReceived()
    verifyCrowdFundingFinanced()
    external
    payable
    {
        fundingReceived = true;
        baseSum = address(this).balance;
    }

    function withdraw()
    canWithdraw()
    external
    {
        address payable withdrawee = payable(msg.sender);
        uint sum = shareHolders[payable(msg.sender)].percentage * baseSum / 100;

        (bool success, ) = withdrawee.call{value: sum}("");
        require(success, "Withdrawal failed!");
        
        shareHolders[withdrawee].withdrawed = true;
    }
}
