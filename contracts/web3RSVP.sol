// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Web3RSVP {
    struct CreateEvent {
        bytes32 eventID;
        string eventDataCID;
        address eventOwner;
        uint256 eventTimestamp;
        uint256 deposit;
        uint256 maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSVPs;
        bool paidOut;
    }

    mapping(bytes32 => CreateEvent) public idToEvent;

    function createNewEvent(
        uint256 eventTimestamp,
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventDataCID
    ) external {
        //generate an eventID based on other things passed in to generate a hash
        bytes32 eventId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                eventTimestamp,
                deposit,
                maxCapacity
            )
        );

        address[] memory confirmedRSVPs;
        address[] memory claimedRSVPs;


        // this creates a new CreateEvent struct and adds it to the idToEvent mapping
        idToEvent[eventId] = CreateEvent(
            eventId,
            eventDataCID,
            msg.sender,
            eventTimestamp,
            deposit,
            maxCapacity,
            confirmedRSVPs,
            claimedRSVPs,
            false
        );
    }

        function createNewRSVP(bytes32 eventId) external payable {

            CreateEvent storage myEvent = idToEvent[eventId];

            require(msg.value == myEvent.deposit, "NOT ENOUGH");

            require(block.timestamp <= myEvent.eventTimestamp, "ALREADY HAPPENED");

            require(
                myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
                "This event has reached capacity"
            );

            for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
                require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED");
            }

            myEvent.confirmedRSVPs.push(payable(msg.sender));
        }

        function confirmAttendee(bytes32 eventId, address attendee) public {

            CreateEvent storage myEvent = idToEvent[eventId];

            require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

            address rsvpConfirm;

            for (uint8 i = 0; i < myEvent.claimedRSVPs.length; i++) {
                require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
            }
            
            // require that deposits are not already claimed by the event owner
            require(myEvent.paidOut == false, "ALREADY PAID OUT");

            // add the attendee to the claimedRSVPs list
            myEvent.claimedRSVPs.push(attendee);

            // sending eth back to the staker `https://solidity-by-example.org/sending-ether`
            (bool sent,) = attendee.call{value: myEvent.deposit}("");

            // if this fails, remove the user from the array of claimed RSVPs
            if (!sent) {
                myEvent.claimedRSVPs.pop();
            }

            require(sent, "Failed to send Ether");
        }

    
}