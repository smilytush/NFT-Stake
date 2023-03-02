// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol";

contract NFTStaking is Context {
    struct Stake {
        uint256 id;
        address owner;
        uint256 nftId;
        uint256 duration;
        uint256 startTime;
        uint256 rewardRate;
        bool claimed;
    }

    mapping(uint256 => Stake) public stakes;

    address public nftContract;
    address public tokenContract;
    uint256 public totalStakes;
    uint256 public stakeId;

    event Staked(address indexed staker, uint256 indexed nftId, uint256 duration);
    event Unstaked(address indexed staker, uint256 indexed stakeId);
    event Claimed(address indexed staker, uint256 indexed stakeId);

    constructor(address _nftContract, address _tokenContract) {
        nftContract = _nftContract;
        tokenContract = _tokenContract;
        totalStakes = 0;
        stakeId = 1;
    }

    function getRewardRate(uint256 duration) public pure returns (uint256) {
        if (duration == 7 days) {
            return 10;
        } else if (duration == 14 days) {
            return 20;
        } else if (duration == 21 days) {
            return 30;
        } else if (duration == 28 days) {
            return 40;
        } else {
            revert("NFTStaking: invalid duration");
        }
    }

    function stake(uint256 nftId, uint256 duration) public {
        require(duration == 7 days || duration == 14 days || duration == 21 days || duration == 28 days, "NFTStaking: invalid duration");

        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(nftId) == _msgSender(), "NFTStaking: caller is not the owner of the NFT");

        IERC20 token = IERC20(tokenContract);
        uint256 rewardRate = getRewardRate(duration);
        uint256 rewardAmount = (duration * rewardRate) / 1 ether;

        nft.safeTransferFrom(_msgSender(), address(this), nftId);
        token.transferFrom(_msgSender(), address(this), rewardAmount);

        stakes[stakeId] = Stake(stakeId, _msgSender(), nftId, duration, block.timestamp, rewardRate, false);
        totalStakes += 1;
        stakeId += 1;

        emit Staked(_msgSender(), nftId, duration);
    }

    function unstake(uint256 stakeId) public {
        Stake storage stake = stakes[stakeId];
        require(stake.owner == _msgSender(), "NFTStaking: caller is not the owner of the stake");
        require(!stake.claimed, "NFTStaking: stake already claimed");

        IERC721 nft = IERC721(nftContract);
        IERC20 token =    IERC20(tokenContract);

    require(block.timestamp >= stake.startTime + stake.duration, "NFTStaking: stake not yet matured");

    nft.safeTransferFrom(address(this), _msgSender(), stake.nftId);
    token.transfer(_msgSender(), getRewardAmount(stake));

    stake.claimed = true;
    totalStakes -= 1;

    emit Unstaked(_msgSender(), stakeId);
}

function claim(uint256 stakeId) public {
    Stake storage stake = stakes[stakeId];
    require(stake.owner == _msgSender(), "NFTStaking: caller is not the owner of the stake");
    require(!stake.claimed, "NFTStaking: stake already claimed");
    require(block.timestamp >= stake.startTime + stake.duration, "NFTStaking: stake not yet matured");

    IERC20 token = IERC20(tokenContract);

    token.transfer(_msgSender(), getRewardAmount(stake));

    stake.claimed = true;
    totalStakes -= 1;

    emit Claimed(_msgSender(), stakeId);
}

function getRewardAmount(Stake memory stake) public view returns (uint256) {
    return (stake.duration * stake.rewardRate) / 1 ether;
}
}
// This contract allows users to stake their ERC721 NFT tokens for a set period of time (7 days, 14 days, 21 days, or 28 days) and earn ERC20 tokens as a reward. The amount of ERC20 tokens earned is determined by the duration of the stake, with longer stakes earning a higher reward rate.

// The `stake` function transfers the NFT token and the appropriate amount of ERC20 tokens from the staker to the contract. The details of the stake are stored in a `Stake` struct and added to a `stakes` mapping.

// The `unstake` function allows the staker to retrieve their NFT token and the earned ERC20 tokens once the stake has matured. The `claim` function allows the staker to retrieve only the earned ERC20 tokens.

// The `getRewardRate` function calculates the reward rate for a given duration. The `getRewardAmount` function calculates the total amount of ERC20 tokens earned for a given stake.

