// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IERC20Token {
    function transfer(address, uint256) external returns (bool);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract SchoolResourcesMarketplace {
    uint256 private resourcesLength = 0;
    address private cUsdTokenAddress =
        0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    // fee to pay for downloading a resource
    uint256 public downloadFee = 1 ether;

    struct Resource {
        address payable owner;
        string title;
        string description;
        string url;
        uint256 price;
        bool isOnSale;
    }

    mapping(uint256 => Resource) private resources;
    // keeps track of resource's id that exist
    mapping(uint256 => bool) exists;

    /// @dev modifier to check if resource exist
    modifier exist(uint256 _index) {
        require(exists[_index], "Query of non existent resource");
        _;
    }

    /// @dev modifier to check if caller is resource owner
    modifier onlyResourceOwner(uint256 _index) {
        require(
            msg.sender == resources[_index].owner,
            "Only owner can perform this operation"
        );
        _;
    }

    /// @dev modifier to check if caller is a valid customer
    modifier onlyValidCustomer(uint256 _index) {
        require(
            resources[_index].owner != msg.sender,
            "You can't buy your own resource"
        );
        _;
    }

    /// @dev modifer to check if _price is valid
    modifier checkPrice(uint256 _price) {
        require(_price > 0, "Price needs to be at least one wei");
        _;
    }

    /// @dev adds a resource on the marketplace
    function addResource(
        string calldata _title,
        string calldata _description,
        string calldata _url,
        uint256 _price
    ) external checkPrice(_price) {
        require(bytes(_title).length > 0, "Empty title");
        require(bytes(_description).length > 0, "Empty description");
        require(bytes(_url).length > 0, "Empty url");
        resources[resourcesLength] = Resource(
            payable(msg.sender),
            _title,
            _description,
            _url,
            _price,
            true // onSale initialised as true
        );
        exists[resourcesLength] = true;
        resourcesLength++;
    }

    /// @dev buys a resource with _index
    function buyResource(uint256 _index)
        external
        payable
        exist(_index)
        onlyValidCustomer(_index)
    {
        address owner = resources[_index].owner;
        resources[_index].owner = payable(msg.sender);
        resources[_index].isOnSale = false;
        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                owner,
                resources[_index].price
            ),
            "Transfer failed."
        );
}
function cancelSale(uint256 _index)
external
exist(_index)
onlyResourceOwner(_index)
{
resources[_index].isOnSale = false;
}

/// @dev updates the price of a resource with _index
function updatePrice(uint256 _index, uint256 _price)
    external
    exist(_index)
    onlyResourceOwner(_index)
    checkPrice(_price)
{
    resources[_index].price = _price;
}

/// @dev returns the number of resources added on the marketplace
function getResourcesLength() external view returns (uint256) {
    return resourcesLength;
}

/// @dev returns the details of a resource with _index
function getResourceDetails(uint256 _index)
    external
    view
    exist(_index)
    returns (
        address owner,
        string memory title,
        string memory description,
        string memory url,
        uint256 price,
        bool isOnSale
    )
{
    Resource memory resource = resources[_index];
    owner = resource.owner;
    title = resource.title;
    description = resource.description;
    url = resource.url;
    price = resource.price;
    isOnSale = resource.isOnSale;
}

/// @dev downloads a resource with _index
function downloadResource(uint256 _index) external payable exist(_index) {
    require(
        resources[_index].isOnSale,
        "Resource not available for download"
    );
    require(
        msg.value >= downloadFee,
        "Insufficient funds to download resource"
    );
    resources[_index].owner.transfer(msg.value);
}

}