// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./impl/Enumerable.sol";
import "./impl/HookPausable.sol";
import "./mocks/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


/**
 * Reference implementation of ERC721 with Enumerable and Counter support
 */
contract VapenApes2981 is ERC721Enumerable, HookPausable, Ownable {

	/* ---------- Inheritance for solidity types ---------------- */
	using SafeMath for uint256;
	using Counters for Counters.Counter;
	Counters.Counter private _tokenIdTracker;
	/* ---------- Inheritance for solidity types ---------------- */

	// uint256 public constant reveal_timestamp = 1627588800; // Thu Jul 29 2021 20:00:00 GMT+0000


	uint256 public startingIndexBlock;
	uint256 public startingIndex;
	uint256 public constant APE_SALEPRICE = 70000000000000000; //0.70 ETH
	uint256 public constant APE_PRESALE_PRICE = 55000000000000000; //0.55 ETH
	uint256 public constant MAX_APE_PURCHASE = 10;
	address public constant DEV_ADDRESS = 0x02fA4fe6cBfa5dC167dDD06727906d0F884351e3;
	uint256 public constant MAX_APES = 10000;

	/* PRESALE CONFIGURATION */

	uint256 public constant MAX_PRESALE = 4000;
	uint256 public constant MAX_PRESALE_PURCHASE = 5;
	uint256 public constant NUM_TO_RESERVE = 50;
	bool public PRESALE_ACTIVE = false;
	uint256 public PRESALE_MINTED;

	mapping(address => uint256) public PRESALE_PURCHASES;

	/* Team structure */
	struct Team {
		address payable addr;
		uint256 percentage;
	}
	Team[] internal _team;

	/**
	 * @dev 
	 * Vapenapes Reveal configuration and handles for Metadata 
	 */
	string public apesReveal = "";
	string public baseTokenURI;
	uint256 public revealTimestamp;

	/* Events and logs */
  event MintApe(uint256 indexed id);


	constructor(string memory baseURI) ERC721("VapenApes", "VAPE") {
		setBaseURI(baseURI);
    pause(true);

		/* Add all team mates to the equity mapping */
		_team.push(Team(payable(DEV_ADDRESS), 24));
		_team.push(Team(payable(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2), 24));
		_team.push(Team(payable(0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c), 24));
		_team.push(Team(payable(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db), 24));
		/* Give some Royalties to the seedz project*/
		_team.push(Team(payable(0x583031D1113aD414F02576BD6afaBfb302140225), 4));
	}

	/**
	 * @dev 
	 * Encode team distribution percentage
	 * Embed all individuals equity and payout to seedz project
	 * retain at least 0.1 ether in the smart contract
	 */

	function withdraw() public onlyOwner {
		/* Minimum balance */
		require(address(this).balance > 0.5 ether);
		uint256 balance = address(this).balance - 0.1 ether;

		for (uint256 i = 0; i < _team.length; i++) {
			Team storage _st = _team[i];
			_st.addr.transfer((balance * _st.percentage) / 100);
		}
	}


/* Extends HookPausable */
	  function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

		  modifier saleIsOpen {
        require(totalSupply() <= MAX_APES, "Sale end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }
    function totalSupply() internal view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return totalSupply();
    }

	function baseURI()public  returns (string memory) {
		return __baseURI__;
	}



	/** 
	* @dev
	* Sometimes tokens sent to contracts and get lostm, due to user errors
	* This can enable withdrawal of any mistakenly send ERC-20 token to this address.
	*/
	function withdrawTokens(address tokenAddress) external onlyOwner {
		uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
		IERC20(tokenAddress).transfer(_msgSender(), balance);
	}

	/**
	 * Set some Apes aside
	 * We will set aside 50 Vapenapes for community giveaways and promotions
	 */
	function reserveApes() public onlyOwner {
		uint256 supply = totalSupply();
		uint256 i;
		for (i = 0; i < 50; i++) {
			_safeMint(_msgSender(), supply + i);
		}
	}



	function reserveApes() public onlyOwner {
		require(totalSupply().add(NUM_TO_RESERVE) <= MAX_SUPPLY, "Reserve would exceed max supply");

		uint256 supply = totalSupply();
		uint256 i;
		for (uint256 i = 0; i < NUM_TO_RESERVE; i++) {
			_safeMint(_msgSender(), supply + i);
		}
	}

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

	
	function flipPresaleState() external onlyOwner {
		PRESALE_ACTIVE = !PRESALE_ACTIVE;
	}


	function presalePurchasedCount(address addr) external view returns (uint256) {
		return PRESALE_PURCHASES[addr];
	}


	function presaleMintApe(uint256 numberOfTokens) external payable {
		require(PRESALE_ACTIVE, "Presale closed");
		require(PRESALE_MINTED + numberOfTokens <= MAX_PRESALE, "Purchase would exceed max presale");

		uint256 supply = totalSupply();
		require(supply.add(numberOfTokens) <= MAX_SUPPLY, "Purchase would exceed max supply of baddies");
		require(PRESALE_PURCHASES[_msgSender()] + numberOfTokens <= MAX_PRESALE_PURCHASE, "Purchase would exceed your max allocation");
		require(BADDIE_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

		for (uint256 i = 0; i < numberOfTokens; i++) {
			PRESALE_MINTED++;
			PRESALE_PURCHASES[_msgSender()]++;
			_safeMint(_msgSender(), supply + i);
		}
	}


	/**
	 * Mints Apes
	 */
	function mintApe(uint256 numberOfTokens) public payable saleIsOpen {
		require(saleIsActive, "Sale must be active to mint Ape");
		require(numberOfTokens <= MAX_APE_PURCHASE, "Can only mint 20 tokens at a time");

		require(totalSupply().add(numberOfTokens) <= maxApes, "Purchase would exceed max supply of Apes");
		require(APE_SALEPRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");


		for (uint256 i = 0; i < numberOfTokens; i++) {

			/* Increment supply and mint token */
				uint id = _totalSupply();
        _tokenIdTracker.increment();
			if (totalSupply() < maxApes) {
				_safeMint(msg.sender, id);

/* emit mint event */
emit MintApe(id);
			}
		}

		// If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
		// the end of pre-sale, set the starting index block
		if (startingIndexBlock == 0 && (totalSupply() == maxApes || block.timestamp >= revealTimestamp)) {
			startingIndexBlock = block.number;
		}
	}


	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

		string memory base = baseURI();
		if (STARTING_INDEX == 0) {
			return base;
		}

		uint256 id = (tokenId + STARTING_INDEX) % MAX_SUPPLY;
		return string(abi.encodePacked(base, id.toString()));
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

	   function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }


	/**
	 * Set the starting index block for the collection, essentially unblocking
	 * setting starting index
	 */
	function emergencySetStartingIndexBlock() public onlyOwner {
		require(startingIndex == 0, "Starting index is already set");

		startingIndexBlock = block.number;
	}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}