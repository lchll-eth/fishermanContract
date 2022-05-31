// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "../../IToken.sol";

contract WAncientFisherman is Ownable {
    uint256 public tokenId;

    bool public isPrivateMint;
    bool public isPublicMint;

    //PRICES
    uint256 public mintPriceEth = 0.03 ether;
    uint256 public mintPriceBundleEth = 0.12 ether;
    uint256 public mintPriceWrld = 1000 ether;
    uint256 public mintPriceBundleWrld = 4000 ether;

    bytes32 public whitelistMerkleRoot;

    address public foundersWallet;

    IToken public WRLD_TOKEN;

    event MintEth(address indexed player, uint256 indexed tokenId, bool bundle, uint256 numberOfTokens);
    event MintWrld(address indexed player, uint256 indexed tokenId, bool bundle, uint256 numberOfTokens);

    constructor(){
        foundersWallet = 0x02367e1ed0294AF91E459463b495C8F8F855fBb8;
        WRLD_TOKEN = IToken(0xD5d86FC8d5C0Ea1aC1Ac5Dfab6E529c9967a45E9);
        whitelistMerkleRoot = 0x23b56d3d5fdb3794dbde2d8b4ddb588f3d3a26564ee14a099fa2dbaa303f51fa;
    }


    function setFoundersWallet(address newFoundersWallet) external onlyOwner{
        foundersWallet = newFoundersWallet;
    }

    //CONTROL FUNCTIONS
    function updateWhitelistMerkleRoot(bytes32 _newMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _newMerkleRoot;
    }

    function setPrice(uint256 mintPriceBundleEth_, uint256 mintPriceBundleWrld_, uint256 mintPriceEth_, uint256 mintPriceWrld_) external onlyOwner{
        mintPriceBundleEth = mintPriceBundleEth_;
        mintPriceBundleWrld = mintPriceBundleWrld_;
        mintPriceEth = mintPriceEth_;
        mintPriceWrld = mintPriceWrld_;
    }

    function setPublicMint(bool isPublicMint_) external onlyOwner{
        isPublicMint = isPublicMint_;
    }

    function setPrivateMint(bool isPrivateMint_) external onlyOwner{
        isPrivateMint = isPrivateMint_;
    }

    modifier onlyMinter(address player, uint256 _numberOfTokens, bool bundle, bytes32[] calldata merkleProof){
        require(isPrivateMint || isPublicMint, "Mint not open");
        if(bundle){
            require(_numberOfTokens <= 5, "max 5 blds");
        }else{
            require(_numberOfTokens <= 25, "max 5 blds");
        }

        if(!isPublicMint){
            bool isWhitelisted = MerkleProof.verify(
                merkleProof, //routeProof
                whitelistMerkleRoot, //root
                keccak256(abi.encodePacked(player)/* leaf */)
            );
            require(isWhitelisted, "invalid-proof");
        }
        _;
    }

    function mintEth(address player, uint256 _numberOfTokens, bool bundle, bytes32[] calldata merkleProof) external payable onlyMinter(player, _numberOfTokens, bundle, merkleProof){
        if(bundle){
            require(msg.value >= mintPriceBundleEth * _numberOfTokens * 5, "inc-bnd-val");
        }else{
            require(msg.value >= mintPriceEth * _numberOfTokens, "inc-eth-val");
        }

        emit MintEth(player, tokenId, bundle, _numberOfTokens);
        tokenId += _numberOfTokens;

    }
function mintWrld(address player, uint256 _numberOfTokens, bool bundle, bytes32[] calldata merkleProof) external payable onlyMinter(player, _numberOfTokens, bundle, merkleProof){
        if(bundle){
            require(mintPriceBundleWrld * _numberOfTokens * 5 <= WRLD_TOKEN.balanceOf(player), "low-balance-bnd-wrld");
            require(mintPriceBundleWrld * _numberOfTokens * 5 <= WRLD_TOKEN.allowance(player, address(this)), "low-allowance-bnd-wrld");
        }else{
            require(mintPriceWrld * _numberOfTokens <= WRLD_TOKEN.balanceOf(player), "low-balance-wrld");
            require(mintPriceWrld * _numberOfTokens <= WRLD_TOKEN.allowance(player, address(this)), "low-allowance-wrld");
        }

        emit MintWrld(player, tokenId, bundle, _numberOfTokens);
        tokenId += _numberOfTokens;

        WRLD_TOKEN.transferFrom(player, foundersWallet, mintPriceBundleWrld * _numberOfTokens);
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        payable(foundersWallet).transfer(_balance);
    }

}
