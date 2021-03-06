// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

contract BuyCars {
    
    
    address public owner;
    address public bonusTokenAddress;
    address public accounter;
    
    event createOrderEvent(uint _tokens);
    
    constructor(address _btkaddr) {
        owner = msg.sender;
        bonusTokenAddress = _btkaddr;
        accounter = owner;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner can do this");
        _;
    }
    
    uint public UserID;
    uint public CarID;
    uint public OrderID;
    uint public ServicesOrderID;
    
    struct car {
        uint price;
        string brand;
        string model;
    }

    
    struct order {
        uint userID;
        uint carID;
        uint date;
        bool active;
        uint tokens;
    }

    struct serviceOrder {
        address userAddress;
        uint price;
        uint date;
    }
    
    struct user {
        uint userID;
        string name;
        uint tokens;
        uint[] orders;
    }

    car[] public CarList;
    user[] public UserList;
    order[] public OrderList;
    serviceOrder[] public ServiceOrderList;

    mapping(address => user) public Users;
    mapping(uint => address) public UserIDs;
    mapping(uint => car) public Cars;
    mapping(uint => order) public Orders;
    mapping(uint => serviceOrder) public ServicesOrders;
    
    //FUNCTIONS
        
    function setBonusTokenAddress(address _address) public onlyOwner {
        bonusTokenAddress = _address;
    }

    function addAccounter (address _address) public onlyOwner {
        accounter = _address;
    }
    
    
    function addUser(string memory _name, address _userAddress) public onlyOwner {
        UserID += 1;
        Users[_userAddress].name = _name;
        Users[_userAddress].userID = UserID;
        UserIDs[UserID] = _userAddress;   // UserIDs [1] <= UserID += 1;
        UserList.push(Users[_userAddress]); //UserList [0] index = UserID - 1
    }
    
    function addCar(string memory _brand, string memory _model, uint _price) public onlyOwner {
        CarID += 1;
        Cars[CarID].brand = _brand;
        Cars[CarID].model = _model;
        Cars[CarID].price = _price;
        CarList.push(Cars[CarID]);
    }

    function viewCarsList() public  view returns(car[] memory) {
        return CarList;
    }

    function viewUserList() public view returns(user[] memory) {
        return UserList;
    }

    function viewOrderList() public view returns(order[] memory) {
        return OrderList;
    }

    function viewServiceOrderList() public view returns(serviceOrder[] memory) {
        return ServiceOrderList;
    }

    function changeUsersTokensInList(uint _user_id) internal {
        user memory _user_for_change = Users[UserIDs[_user_id]];
        for (uint i; i < UserList.length; i++) {
            if ((i+1) == _user_id) {
                UserList[i] = _user_for_change;
            }
        }
    }
     
    function createOrder(uint _car_id, uint _user_id) public onlyOwner {
        OrderID += 1;
        Orders[OrderID].userID = _user_id;
        Orders[OrderID].carID = _car_id;
        Orders[OrderID].date = block.timestamp;
        Orders[OrderID].active = true;
        address _user_address = UserIDs[_user_id];
        Users[_user_address].orders.push(OrderID);
        uint _tokens = Cars[_car_id].price/100; 
        Orders[OrderID].tokens = _tokens;
        Users[_user_address].tokens = _tokens;
        IERC20 _bonusToken = IERC20(bonusTokenAddress);
        _bonusToken.mint(_user_address, _tokens * 10 ** 18);
        emit createOrderEvent(_tokens);  
        OrderList.push(Orders[OrderID]);

        changeUsersTokensInList(_user_id);
    }

    function createServiceOrder (address _address, uint _price) public onlyOwner {
        ServicesOrderID += 1;
        ServicesOrders[ServicesOrderID].userAddress = _address;
        ServicesOrders[ServicesOrderID].price = _price;
        ServicesOrders[ServicesOrderID].date = block.timestamp;
        ServiceOrderList.push(ServicesOrders[ServicesOrderID]);
        IERC20(bonusTokenAddress).burn(_address, _price * 10 ** 18);
        Users[_address].tokens -= _price;
        uint _user_id = Users[_address].userID;
        changeUsersTokensInList(_user_id);
    }

    function payByTokens(uint256 _serviceOrderID) public {
        uint256 _serviceAmount = ServicesOrders[_serviceOrderID].price;
        require(
            Users[msg.sender].tokens >= _serviceAmount,
            "Not enought tokens"
        ); 

        IERC20 _bon_token = IERC20(bonusTokenAddress); 
        _bon_token.transferFrom(msg.sender, accounter, _serviceAmount * 10**18); 
        Users[msg.sender].tokens -= _serviceAmount; 
    }

}
