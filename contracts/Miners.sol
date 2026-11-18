// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Minimal view of the SPACE ID Agent ID HandleRegistry (BSC mainnet
///         0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F). The strong holder gate
///         used everywhere in this contract is:
///         balanceOf(wallet) > 0 AND handleOf(wallet) non-empty AND
///         ownerOfHandle(handle) == wallet.
interface IAgentIDRegistry {
    function balanceOf(address owner) external view returns (uint256);
    function handleOf(address owner) external view returns (string memory);
    function ownerOfHandle(string memory handle) external view returns (address);
}

/// @title DeepShard — Season 1: "The First Descent"
/// @notice A free-mint NFT collection for Agent ID holders only. Each miner
///         earns SHARD, an in-game points record kept inside this contract.
///         SHARD is NOT a token: it is non-transferable, has no price, and is
///         never promised to become one. Holders claim once a day to keep a
///         streak; streaks multiply SHARD; SHARD raises the miner's level.
///         Every claim also digs a shared community depth meter.
/// @dev    Design rules (public, verifiable in this source):
///         - Mint price is exactly 0. There are no payable functions at all.
///         - The contract never holds user funds and has no withdraw function.
///         - There is no owner and no admin function of any kind.
///         - Supply is hard-locked at 3,333 in code; max 2 mints per wallet.
///         - The contract never requests ERC-20 approvals from users.
///         - Miner class is deterministic from the Agent ID handle
///           (h = h*31 + byte over the handle bytes; class = h % 5), the same
///           rule the project website's class checker uses.
///         - Appearance traits are seeded at mint from data the minter cannot
///           choose (tokenId, minter, prevrandao, timestamp).
contract Miners {
    // ------------------------------------------------------------------
    // ERC-721 metadata
    // ------------------------------------------------------------------
    string public constant name = "DeepShard";
    string public constant symbol = "DSHARD";

    // ------------------------------------------------------------------
    // Collection rules
    // ------------------------------------------------------------------
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_PER_WALLET = 2;
    uint256 public constant DEPTH_TARGET = 10000; // metres, season goal

    // ------------------------------------------------------------------
    // Mining rules
    // ------------------------------------------------------------------
    uint256 public constant SHARD_PER_DAY = 100; // per NFT owned
    uint256 public constant CLAIM_COOLDOWN = 20 hours;
    uint256 public constant STREAK_GRACE = 48 hours;
    uint256 public constant ACCRUAL_CAP = 7 days;
    uint256 public constant DEPTH_PER_CLAIM = 4; // metres
    uint256 public constant CLASS_DAY_BONUS_X = 2;

    IAgentIDRegistry public immutable registry;
    string private _baseURI;
    uint256 public immutable startTime;

    // ------------------------------------------------------------------
    // ERC-721 state
    // ------------------------------------------------------------------
    uint256 public totalSupply;
    mapping(uint256 => address) private _ownerOf;
    mapping(address => uint256) private _balanceOf;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // ------------------------------------------------------------------
    // Game state
    // ------------------------------------------------------------------
    mapping(address => uint256) public mintedBy;
    mapping(uint256 => uint256) public traitSeedOf;
    uint256 public totalDepth; // shared community depth, in metres

    struct MinerState {
        uint256 shard; // lifetime SHARD (never decreases, never transferable)
        uint64 lastSettle; // last accrual settlement time
        uint64 lastClaim; // last successful claim time (0 = never)
        uint32 streak; // current claim streak in days
    }
    mapping(address => MinerState) private _miners;

    // ------------------------------------------------------------------
    // Events (the expedition log is read from Claimed events)
    // ------------------------------------------------------------------
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Minted(address indexed wallet, uint256 indexed tokenId, uint256 minerClass);
    event Claimed(
        address indexed wallet,
        uint256 shardGained,
        uint256 streak,
        uint256 depthAdded,
        uint256 totalDepth
    );

    constructor(address registry_, string memory baseURI_) {
        require(registry_ != address(0), "registry zero");
        registry = IAgentIDRegistry(registry_);
        _baseURI = baseURI_;
        startTime = block.timestamp;
    }

    // ------------------------------------------------------------------
    // Agent ID gate
    // ------------------------------------------------------------------
    function isAgentIDHolder(address wallet) public view returns (bool) {
        if (registry.balanceOf(wallet) == 0) return false;
        string memory handle = registry.handleOf(wallet);
        if (bytes(handle).length == 0) return false;
        return registry.ownerOfHandle(handle) == wallet;
    }

    function handleOf(address wallet) public view returns (string memory) {
        return registry.handleOf(wallet);
    }

    /// @notice Miner class 0..4: 0 Driller, 1 Blaster, 2 Engineer,
    ///         3 Cartographer, 4 Lantern Keeper. Deterministic from handle.
    function classOf(address wallet) public view returns (uint256) {
        bytes memory h = bytes(registry.handleOf(wallet));
        require(h.length > 0, "no handle");
        uint256 x = 0;
        for (uint256 i = 0; i < h.length; i++) {
            x = x * 31 + uint8(h[i]);
        }
        return x % 5;
    }

    /// @notice The class whose depth contribution is doubled today.
    function classOfDay() public view returns (uint256) {
        return (block.timestamp / 1 days) % 5;
    }

    // ------------------------------------------------------------------
    // Mint — free, standard signature, no arguments, no payment possible
    // ------------------------------------------------------------------
    function mintOpen() public view returns (bool) {
        return totalSupply < MAX_SUPPLY;
    }

    function mint() external {
        require(totalSupply < MAX_SUPPLY, "sold out");
        require(mintedBy[msg.sender] < MAX_PER_WALLET, "wallet cap");
        require(isAgentIDHolder(msg.sender), "Agent ID required");

        uint256 tokenId = ++totalSupply;
        mintedBy[msg.sender] += 1;
        traitSeedOf[tokenId] = uint256(
            keccak256(abi.encodePacked(tokenId, msg.sender, block.prevrandao, block.timestamp))
        );
        _mint(msg.sender, tokenId);
        emit Minted(msg.sender, tokenId, classOf(msg.sender));
    }

    // ------------------------------------------------------------------
    // Mining — time-based accrual, daily manual claim, streak, depth
    // ------------------------------------------------------------------
    function multiplierOf(uint256 streak) public pure returns (uint256) {
        if (streak >= 30) return 200;
        if (streak >= 14) return 150;
        if (streak >= 7) return 125;
        if (streak >= 3) return 110;
        return 100;
    }

    function levelOf(address wallet) public view returns (uint256) {
        uint256 s = _miners[wallet].shard;
        if (s >= 8000) return 10;
        if (s >= 5000) return 9;
        if (s >= 3200) return 8;
        if (s >= 2000) return 7;
        if (s >= 1200) return 6;
        if (s >= 700) return 5;
        if (s >= 350) return 4;
        if (s >= 150) return 3;
        if (s >= 50) return 2;
        return 1;
    }

    function shardOf(address wallet) public view returns (uint256) {
        return _miners[wallet].shard;
    }

    function streakOf(address wallet) public view returns (uint256) {
        return _miners[wallet].streak;
    }

    /// @notice SHARD that a claim would settle right now (before multiplier
    ///         is applied inside claim; this view already includes it).
    function pendingOf(address wallet) public view returns (uint256) {
        MinerState storage m = _miners[wallet];
        if (m.lastSettle == 0) return 0;
        uint256 elapsed = block.timestamp - m.lastSettle;
        if (elapsed > ACCRUAL_CAP) elapsed = ACCRUAL_CAP;
        uint256 base = (SHARD_PER_DAY * _balanceOf[wallet] * elapsed) / 1 days;
        uint256 streak = m.streak == 0 ? 1 : m.streak;
        return (base * multiplierOf(streak)) / 100;
    }

    function claim() external {
        require(_balanceOf[msg.sender] > 0, "no miner");
        require(isAgentIDHolder(msg.sender), "Agent ID required");
        MinerState storage m = _miners[msg.sender];
        if (m.lastClaim != 0) {
            require(block.timestamp - m.lastClaim >= CLAIM_COOLDOWN, "too early");
        }

        uint256 gained;
        if (m.lastSettle == 0) {
            // First claim starts the mining clock; nothing accrued yet.
            m.lastSettle = uint64(block.timestamp);
        } else {
            gained = pendingOf(msg.sender);
            m.shard += gained;
            m.lastSettle = uint64(block.timestamp);
        }

        // Streak: within the 48h grace the streak grows, otherwise it
        // restarts at 1. Missing more than the grace is the only reset.
        if (m.lastClaim == 0) {
            m.streak = 1;
        } else if (block.timestamp - m.lastClaim <= STREAK_GRACE) {
            m.streak += 1;
        } else {
            m.streak = 1;
        }
        m.lastClaim = uint64(block.timestamp);

        uint256 depthAdded = DEPTH_PER_CLAIM;
        if (classOf(msg.sender) == classOfDay()) {
            depthAdded = DEPTH_PER_CLAIM * CLASS_DAY_BONUS_X;
        }
        totalDepth += depthAdded;

        emit Claimed(msg.sender, gained, m.streak, depthAdded, totalDepth);
    }

    // ------------------------------------------------------------------
    // ERC-721 implementation (written from scratch, no external libs)
    // ------------------------------------------------------------------
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165
            || interfaceId == 0x80ac58cd // ERC721
            || interfaceId == 0x5b5e139f; // ERC721Metadata
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "zero address");
        return _balanceOf[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _ownerOf[tokenId];
        require(owner != address(0), "nonexistent token");
        return owner;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_ownerOf[tokenId] != address(0), "nonexistent token");
        return string(abi.encodePacked(_baseURI, _toString(tokenId)));
    }

    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender], "not authorized");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        require(_ownerOf[tokenId] != address(0), "nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "not authorized");
        require(ownerOf(tokenId) == from, "wrong from");
        require(to != address(0), "zero address");
        delete _tokenApprovals[tokenId];
        _balanceOf[from] -= 1;
        _balanceOf[to] += 1;
        _ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "unsafe recipient");
    }

    // ------------------------------------------------------------------
    // Internals
    // ------------------------------------------------------------------
    function _mint(address to, uint256 tokenId) internal {
        _balanceOf[to] += 1;
        _ownerOf[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = _ownerOf[tokenId];
        return spender == owner || _tokenApprovals[tokenId] == spender
            || _operatorApprovals[owner][spender];
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data)
        private
        returns (bool)
    {
        if (to.code.length == 0) return true;
        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (
            bytes4 retval
        ) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch {
            return false;
        }
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}
