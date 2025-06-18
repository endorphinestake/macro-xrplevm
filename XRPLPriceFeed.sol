// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PriceFeed {
    address public owner;
    address public bandBridge;
    uint8 public constant DECIMALS = 8;

    struct PriceData {
        uint256 price;
        uint256 lastUpdated;
    }

    mapping(string => PriceData) private prices;

    string[] private knownKeys;
    mapping(string => bool) private knownKeyExists;

    event PriceUpdated(string indexed key, uint256 price, uint256 timestamp);

    modifier onlyAuthorized() {
        require(
            msg.sender == bandBridge || msg.sender == owner,
            "Not authorized"
        );
        _;
    }

    constructor(address _bandBridge) {
        require(_bandBridge != address(0), "Invalid BandBridge address");
        owner = msg.sender;
        bandBridge = _bandBridge;
    }

    function setPrices(
        string[] calldata keys,
        uint256[] calldata values
    ) external onlyAuthorized {
        require(keys.length == values.length, "Length mismatch");

        for (uint256 i = 0; i < keys.length; i++) {
            PriceData storage existing = prices[keys[i]];

            if (!knownKeyExists[keys[i]]) {
                knownKeys.push(keys[i]);
                knownKeyExists[keys[i]] = true;
            }

            if (existing.price != values[i]) {
                existing.price = values[i];
                existing.lastUpdated = block.timestamp;

                emit PriceUpdated(keys[i], values[i], block.timestamp);
            }
        }
    }

    function getPrice(
        string calldata key
    ) external view returns (uint256 price, uint256 timestamp) {
        PriceData memory data = prices[key];
        return (data.price, data.lastUpdated);
    }

    function getPrices(
        string[] calldata keys
    )
        external
        view
        returns (uint256[] memory values, uint256[] memory timestamps)
    {
        uint256 len = keys.length;
        require(len > 0, "Keys required");

        values = new uint256[](len);
        timestamps = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            PriceData memory data = prices[keys[i]];
            values[i] = data.price;
            timestamps[i] = data.lastUpdated;
        }

        return (values, timestamps);
    }

    function getAllPrices()
        external
        view
        returns (
            string[] memory keys,
            uint256[] memory values,
            uint256[] memory timestamps
        )
    {
        uint256 len = knownKeys.length;
        keys = new string[](len);
        values = new uint256[](len);
        timestamps = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            keys[i] = knownKeys[i];
            PriceData memory data = prices[knownKeys[i]];
            values[i] = data.price;
            timestamps[i] = data.lastUpdated;
        }

        return (keys, values, timestamps);
    }

    function removePrice(string calldata key) external {
        require(msg.sender == owner, "Only owner");
        require(knownKeyExists[key], "Key does not exist");

        delete prices[key];
        knownKeyExists[key] = false;

        uint256 len = knownKeys.length;
        for (uint256 i = 0; i < len; i++) {
            if (keccak256(bytes(knownKeys[i])) == keccak256(bytes(key))) {
                knownKeys[i] = knownKeys[len - 1];
                knownKeys.pop();
                break;
            }
        }
    }

    function updateBandBridge(address newBridge) external {
        require(msg.sender == owner, "Only owner");
        require(newBridge != address(0), "Invalid address");
        bandBridge = newBridge;
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "Only owner");
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
}
