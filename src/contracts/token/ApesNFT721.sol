// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../overrides/RoyaltyOverrideCore.sol";
import "../impl/ERC721Enumerable.sol";
import "../impl/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * Reference implementation of ERC721 with EIP2981 support
 */
contract Apes2981 is ERC721Enumerable, EIP2981RoyaltyOverrideCore, Ownable {
	using SafeMath for uint256;

	uint256 public startingIndexBlock;
	uint256 public startingIndex;
	uint256 public constant APE_PRICE = 80000000000000000; //0.08 ETH
	uint256 public constant MAX_APE_PURCHASE = 20;
	uint256 public maxApes;
	bool public saleIsActive = false;
	
	struct Team {
	    address payable addr;
	    uint percentage;
	}
	
	Team[] internal _team;

	/* Setup Reveal Vars */
	string public apesReveal = "";
	uint256 public revealTimestamp;

	constructor(
		string memory name,
		string memory symbol,
		uint256 maxNftSupply,
		uint256 saleStart
	) ERC721(name, symbol) {
		maxApes = maxNftSupply;
		revealTimestamp = saleStart + (86400 * 9);
		
		/* Add all team mates to the equity mapping */
		_team.push(Team(payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4), 24));
		_team.push(Team(payable(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2), 24));
		_team.push(Team(payable(0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c), 24));
		_team.push(Team(payable(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db), 24));
		/* Give some benefits to the seedz project*/
		_team.push(Team(payable(0x583031D1113aD414F02576BD6afaBfb302140225), 4));
		
	}

    /* Encode team distribution percentage */
    // Embed all individuals equity and payout to seedz project
    // retain at least 0.1 ether in the smart contract 
    
	function withdraw() public onlyOwner {
	    /* Minimum balance */
	    require(address(this).balance > 0.5 ether);
	    uint balance = address(this).balance - 0.1 ether;
	    
	    for(uint i = 0; i < _team.length; i++) {
	        Team storage _st = _team[i];
	        _st.addr.transfer((balance * _st.percentage) / 100);
	    }
	    
	}

	/**
	 * Set some Apes aside
	 */
	function reserveApes() public onlyOwner {
		uint256 supply = totalSupply();
		uint256 i;
		for (i = 0; i < 30; i++) {
			_safeMint(msg.sender, supply + i);
		}
	}

	/**
	 * DM Gargamel in Discord that you're standing right behind him.
	 */
	function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
		revealTimestamp = revealTimeStamp;
	}

	/*
	 * Set provenance once it's calculated
	 */
	function setProvenanceHash(string memory provenanceHash) public onlyOwner {
		apesReveal = provenanceHash;
	}

	function setBaseURI(string memory baseURI) public onlyOwner {
		_setBaseURI(baseURI);
	}


	/*
	 * Pause sale if active, make active if paused
	 */
	function flipSaleState() public onlyOwner {
		saleIsActive = !saleIsActive;
	}

	/**
	 * Mints Apes
	 */
	function mintApe(uint256 numberOfTokens) public payable {
		require(saleIsActive, "Sale must be active to mint Ape");
		require(numberOfTokens <= MAX_APE_PURCHASE, "Can only mint 20 tokens at a time");
		require(totalSupply().add(numberOfTokens) <= maxApes, "Purchase would exceed max supply of Apes");
		require(APE_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

		for (uint256 i = 0; i < numberOfTokens; i++) {
			uint256 mintIndex = totalSupply();
			if (totalSupply() < maxApes) {
				_safeMint(msg.sender, mintIndex);
			}
		}

		// If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
		// the end of pre-sale, set the starting index block
		if (startingIndexBlock == 0 && (totalSupply() == maxApes || block.timestamp >= revealTimestamp)) {
			startingIndexBlock = block.number;
		}
	}

	/**
	 * Set the starting index for the collection
	 */
	function setStartingIndex() public {
		require(startingIndex == 0, "Starting index is already set");
		require(startingIndexBlock != 0, "Starting index block must be set");

		startingIndex = uint256(blockhash(startingIndexBlock)) % maxApes;
		// Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
		if (block.number.sub(startingIndexBlock) > 255) {
			startingIndex = uint256(blockhash(block.number - 1)) % maxApes;
		}
		// Prevent default sequence
		if (startingIndex == 0) {
			startingIndex = startingIndex.add(1);
		}
	}

	/**
	 * Set the starting index block for the collection, essentially unblocking
	 * setting starting index
	 */
	function emergencySetStartingIndexBlock() public onlyOwner {
		require(startingIndex == 0, "Starting index is already set");

		startingIndexBlock = block.number;
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, EIP2981RoyaltyOverrideCore) returns (bool) {
		return ERC721.supportsInterface(interfaceId) || EIP2981RoyaltyOverrideCore.supportsInterface(interfaceId);
	}

	/**
	 * @dev See {IEIP2981RoyaltyOverride-setTokenRoyalties}.
	 */
	function setTokenRoyalties(TokenRoyaltyConfig[] calldata royaltyConfigs) external override onlyOwner {
		_setTokenRoyalties(royaltyConfigs);
	}

	/**
	 * @dev See {IEIP2981RoyaltyOverride-setDefaultRoyalty}.
	 */
	function setDefaultRoyalty(TokenRoyalty calldata royalty) external override onlyOwner {
		_setDefaultRoyalty(royalty);
	}
}
