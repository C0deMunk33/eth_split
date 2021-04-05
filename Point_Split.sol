// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

contract Point_Split {

  event Point_Transfer(address indexed from, address indexed to, uint16 amount, bool restricted);

  constructor() {
    points_balance[msg.sender] = points_total_supply;//100%
    emit Point_Transfer(address(0), msg.sender, points_total_supply, false);
  }

  uint256 lifetime_balance;
  uint256 last_balance;
  uint16 constant points_total_supply = 10000;
  mapping(address => uint256) last_seen_lifetime_balance;
  //10,000 == 100% so 5000 == 50% and 5 == 0.05% || 0.0001
  mapping(address => uint16) permanent_points_balance;
  mapping(address => uint16) revokable_points_balance;

  function withdraw_payout(address target) public {
    //update lifetime_balance, only new Eth with have come in since last withdraw
    lifetime_balance +=  address(this).balance - last_balance;
    //withdraw available_balance
    target.transfer(available_balance(target));
    //update last_seen_lifetime_balance
    last_seen_lifetime_balance[target] = lifetime_balance;
    //update last_balance
    last_balance = address(this).balance;
  }

  function transfer_points(address target, uint16 amount) public {
    //pull current amount
    points_balance[msg.sender] -= amount;
    points_balance[target] += amount;
    withdraw(msg.sender);
    withdraw(target);
    emit Point_Transfer(msg.sender, target, amount, false);
  }
  function available_eth_balance(address user) public returns(uint256){
    return (lifetime_balance - last_seen_lifetime_balance[user]/((permanent_points_balance[user] + revokable_points_balance[user]) / points_total_supply));
  }

  // assign points issue but do not lock
  function assign_revocable_points(address target, uint256 amount) public only_owner {
    permanent_points_balance[msg.sender] -= amount;
    revokable_points_balance[target] += amount;
    emit Point_Transfer(msg.sender, target, amount, true);
  }
  function revoke_points(address target, uint256 amount) public only_owner {
    revokable_points_balance[target] -= amount;
    permanent_points_balance[msg.sender] += amount;
    emit Point_Transfer(target, msg.sender, amount, false);
  }
  function convert_revocable_points(address target, uint256 amount) public only_owner {
    revokable_points_balance[target] -= amount;
    permanent_points_balance[target] += amount;
    emit Point_Transfer(target, target, amount, false);
  }

  // assign points perma-lock
  function assign_permanent_points(address target, uint256 amount) public only_owner {
    permanent_points_balance[msg.sender] -= amount;
    permanent_points_balance[target] += amount;
    emit Point_Transfer(msg.sender, target, amount, false);
  }
}
