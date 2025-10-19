// SPDX-License-Indentifier: MIT
pragma solidity ^0.8.0;

contract CrowdTank {
    // struct to store project details
    struct Project {
        address creator;
        string name;
        string description;
        uint fundingGoal;
        uint deadline;
        uint amountRaised;
        bool funded;
    }
    // projectId => project details
    mapping(uint => Project) public projects;
    // projectId => user => contribution amount/funding amount 
    mapping(uint => mapping(address => uint)) public contributions;

    // projectId => whether the id is used or not
    mapping(uint => bool) public isIdUsed;


    // events
    event ProjectCreated(uint indexed projectId, address indexed creator, string name, string description, uint fundingGoal, uint deadline);
    event ProjectFunded(uint indexed projectId, address indexed contributor, uint amount);
    event FundsWithdrawn(uint indexed projectId, address indexed withdrawer, uint amount, string withdrawerType);
    // withdrawerType = "user" ,= "admin"

    // create project by a creator
    // external public internal private
    function createProject(string memory _name, string memory _description, uint _fundingGoal, uint _durationSeconds, uint _id) external {
        require(!isIdUsed[_id], "Project Id is already used");
        isIdUsed[_id] = true;
        projects[_id] = Project({
        creator : msg.sender,
        name : _name,
        description : _description,
        fundingGoal : _fundingGoal,
        deadline : block.timestamp + _durationSeconds,
        amountRaised : 0,
        funded : false
        });
        emit ProjectCreated(_id, msg.sender, _name, _description, _fundingGoal, block.timestamp + _durationSeconds);
    }

    function fundProject(uint _projectId) external payable {
        Project storage project = projects[_projectId];
        require(block.timestamp <= project.deadline, "Project deadline is already passed");
        require(!project.funded, "Project is already funded");
        require(msg.value > 0, "Must send some value of ether");
        project.amountRaised += msg.value;
        contributions[_projectId][msg.sender] = msg.value;
        emit ProjectFunded(_projectId, msg.sender, msg.value);
        if (project.amountRaised >= project.fundingGoal) {
            project.funded = true;
        }
    }

    function userWithdrawFinds(uint _projectId) external payable {
        Project storage project = projects[_projectId];
        require(project.amountRaised < project.fundingGoal, "Funding goal is reached,user cant withdraw");
        uint fundContributed = contributions[_projectId][msg.sender];
        payable(msg.sender).transfer(fundContributed);
    }

    function adminWithdrawFunds(uint _projectId) external payable {
        Project storage project = projects[_projectId];
        uint totalFunding = project.amountRaised;
        require(project.funded, "Funding is not sufficient");
        require(project.creator == msg.sender, "Only project admin can withdraw");
        require(project.deadline <= block.timestamp, "Deadline for project is not reached");
        payable(msg.sender).transfer(totalFunding);
    }

    // this is example of a read-only function
    function isIdUsedCall(uint _id)external view returns(bool){
        return isIdUsed[_id];
    }
}
