pragma solidity ^0.4.18;

library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
 contract Ownable {
 	address public owner;


 	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


	/**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
     function Ownable() public {
     	owner = msg.sender;
     }

	/**
     * @dev Throws if called by any account other than the owner.
     */
     modifier onlyOwner() {
     	require(msg.sender == owner);
     	_;
     }

	/**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
     function transferOwnership(address newOwner) public onlyOwner {
     	require(newOwner != address(0));
     	emit OwnershipTransferred(owner, newOwner);
     	owner = newOwner;
     }

 }
 contract ERC20Basic {
 	uint256 public totalSupply;
 	function balanceOf(address who) public constant returns (uint256);
 	function transfer(address to, uint256 value) public returns (bool);
 	event Transfer(address indexed from, address indexed to, uint256 value);
 }

 contract ERC20 is ERC20Basic {
 	function allowance(address owner, address spender) public constant returns (uint256);
 	function transferFrom(address from, address to, uint256 value) public returns (bool);
 	function approve(address spender, uint256 value) public returns (bool);
 	event Approval(address indexed owner, address indexed spender, uint256 value);
 }

 contract Bidding {
 	function increaseBalance(address wallet, uint amount) public;
 	function decreaseBalance(address wallet, uint amount) public;
 	function increaseReputation(address wallet, uint amount) public;
 }
 contract EscrowHolder is Ownable{
 	using SafeMath for uint256;

 	ERC20 public token;
 	Bidding public bidding;

 	function EscrowHolder(address tokenAddress)
 	public{
 		require ( tokenAddress != address(0) );
 		token = ERC20(tokenAddress);
 	}

 	function setBidding(address biddingAddress) 
 	public onlyOwner{
 		require ( biddingAddress != address(0) );
 		bidding = Bidding(biddingAddress);
 	}


 	/*    ----------------------------- ESCROW -----------------------------     */


 	enum EscrowStatus {inactive, initiated, verified, active, canceled, completed}

 	struct EscrowDefinition{
 		address DC_wallet;

 		uint token_amount;
 		uint tokens_sent;

 		uint stake_amount;

 		uint last_confirmation_time;
 		uint end_time;
 		uint total_time_in_seconds;
 		
 		bytes32 total_data_hash;
 		uint decryption_key_checksum;

 		EscrowStatus escrow_status;
 	}

 	mapping(bytes32 => mapping( address => EscrowDefinition)) public escrow;

 	event EscrowInitated(address DC_wallet, address DH_wallet, bytes32 offer_hash, uint token_amount, uint stake_amount, uint total_time_in_minutes);
 	event EscrowVerified(bytes32 import_id, address DC_wallet, bool verification_successful);
 	event EscrowStarted(bytes32 import_id, address DC_wallet, uint timestamp);
 	event EscrowCanceled(bytes32 import_id, address DC_wallet);
 	event EscrowCompleted(bytes32 import_id, address DC_wallet);

 	function initiateEscrow(address DC_wallet, address DH_wallet, bytes32 DH_node_id, bytes32 import_id, uint token_amount, uint stake_amount,  uint total_time_in_minutes)
 	public onlyOwner{

 		require(escrow[import_id][DH_wallet].escrow_status != EscrowStatus.active
 			&&  escrow[import_id][DH_wallet].escrow_status != EscrowStatus.canceled);

 		require(total_time_in_minutes > 0);

 		escrow[import_id][DH_wallet].DC_wallet = DC_wallet;
 		escrow[import_id][DH_wallet].token_amount = token_amount;
 		escrow[import_id][DH_wallet].tokens_sent = 0;
 		escrow[import_id][DH_wallet].stake_amount = stake_amount;
 		escrow[import_id][DH_wallet].last_confirmation_time = 0;
 		escrow[import_id][DH_wallet].end_time = 0;
 		escrow[import_id][DH_wallet].total_time_in_seconds = total_time_in_minutes.mul(60);
 		escrow[import_id][DH_wallet].escrow_status = EscrowStatus.initiated;

 		emit EscrowInitated(DC_wallet, DH_wallet, import_id, token_amount, stake_amount, total_time_in_minutes);
 	}
 	
 	function verifyEscrow(bytes32 import_id, uint token_amount, uint stake_amount, uint total_time_in_minutes, bytes32 root_hash, uint decryption_key_checksum)
 	public returns (bool isVerified){
 		isVerified = false;

 		EscrowDefinition storage this_escrow = escrow[import_id][msg.sender];

 		require(this_escrow.token_amount == token_amount &&
 			this_escrow.stake_amount == stake_amount &&
 			this_escrow.escrow_status == EscrowStatus.initiated &&
 			this_escrow.total_time_in_seconds == total_time_in_minutes.mul(60));

 		this_escrow.total_data_hash = root_hash;
 		this_escrow.decryption_key_checksum = decryption_key_checksum;

 		//Transfer the stake_amount to the escrow
 		bidding.decreaseBalance(msg.sender, stake_amount);

 		this_escrow.escrow_status = EscrowStatus.verified;
 		isVerified = true;
 		emit EscrowVerified(import_id, msg.sender, isVerified);
 	}

 	function verifyHashes(bytes32 import_id, address DH_wallet)
 	public {
 	    EscrowDefinition storage this_escrow = escrow[import_id][DH_wallet];
 	    
 	    require(this_escrow.DC_wallet == msg.sender &&
 	        this_escrow.escrow_status == EscrowStatus.verified);

 		this_escrow.last_confirmation_time = block.timestamp;
 		this_escrow.end_time = SafeMath.add(block.timestamp, this_escrow.total_time_in_seconds);
 	        
 		this_escrow.escrow_status = EscrowStatus.verified;
 	    emit EscrowStarted(import_id, DH_wallet, block.timestamp);
 	}



 	function payOut(bytes32 import_id)
 	public{
 		EscrowDefinition storage this_escrow = escrow[import_id][msg.sender];

 		require(this_escrow.escrow_status == EscrowStatus.active);

 		uint256 amount_to_send;

 		uint end_time = block.timestamp;
 		if(end_time > this_escrow.end_time){
 			uint stake_to_send = this_escrow.stake_amount;
 			this_escrow.stake_amount = 0;
 			if(stake_to_send > 0) {
 				bidding.increaseBalance(msg.sender, stake_to_send);
 				bidding.increaseReputation(msg.sender, stake_to_send);
 				bidding.increaseReputation(this_escrow.DC_wallet, this_escrow.token_amount);
 			}
 			amount_to_send = SafeMath.sub(this_escrow.token_amount, this_escrow.tokens_sent);
 			this_escrow.escrow_status = EscrowStatus.completed;
 			emit EscrowCompleted(import_id, msg.sender);
 		}
 		else{
 			amount_to_send = SafeMath.mul(this_escrow.token_amount,SafeMath.sub(end_time,this_escrow.last_confirmation_time)) / this_escrow.total_time_in_seconds;
 			this_escrow.last_confirmation_time = end_time;
 		}
 		
 		if(amount_to_send > 0) {
 			this_escrow.tokens_sent = this_escrow.tokens_sent.add(amount_to_send);
 			bidding.increaseBalance(msg.sender, amount_to_send);
 		}
 	}

 	function cancelEscrow(bytes32 import_id, address DH_wallet)
 	public {
 		EscrowDefinition storage this_escrow = escrow[import_id][DH_wallet];

 		require(this_escrow.DC_wallet == msg.sender &&
 			this_escrow.escrow_status != EscrowStatus.completed &&
 			this_escrow.escrow_status != EscrowStatus.canceled);

 		uint256 amount_to_send;
 		if(this_escrow.escrow_status == EscrowStatus.active){

 			uint cancelation_time = block.timestamp;
 			if(this_escrow.end_time < block.timestamp) cancelation_time = this_escrow.end_time;

 			amount_to_send = SafeMath.mul(this_escrow.token_amount, SafeMath.sub(this_escrow.end_time,cancelation_time)) / this_escrow.total_time_in_seconds;
 			this_escrow.escrow_status = EscrowStatus.canceled;
 		}
 		else {
 			amount_to_send = this_escrow.token_amount;
 			this_escrow.escrow_status = EscrowStatus.completed;
 		}

 		//Transfer the amount_to_send to DC 
 		if(amount_to_send > 0) {
 			this_escrow.tokens_sent = this_escrow.tokens_sent.add(amount_to_send);
 			bidding.increaseBalance(msg.sender, amount_to_send);
 		}

 		//Calculate the amount to send back to DH and transfer the money back
 		amount_to_send = SafeMath.sub(this_escrow.token_amount, this_escrow.tokens_sent);
 		if(amount_to_send > 0) {
 			this_escrow.tokens_sent = this_escrow.tokens_sent.add(amount_to_send);
 			bidding.increaseBalance(DH_wallet, amount_to_send);
 		}

 		uint stake_to_send = this_escrow.stake_amount;
 		this_escrow.stake_amount = 0;
 		if(stake_to_send > 0) bidding.increaseBalance(DH_wallet, amount_to_send);

 		this_escrow.escrow_status = EscrowStatus.completed;
 		emit EscrowCanceled(import_id, DH_wallet);
 	}

 	/*    ----------------------------- LITIGATION -----------------------------     */



 	// Litigation protocol:
 	// 	1. DC creates a litigation for a specific DH over a specific offer_hash
 	// 		DC sends an array of hashes and the order number of the requested data
 	// 	2. DH sends the requested data -> answer
 	// 		The answer is stored in the SC, and it will be checked once the DH sends their answer and starts the proof
 	// 	3. DC sends the correct data -> proof. It and the answer get checked if they are correct
 	// 		a. If the answer is correct, DH gets +rep 
 	// 		b. If the proof is correct, any party can call the completion function (step 4a)
 	// 	4. The lititigation completion function is called
 	// 		a. If the answer was correct, or the proof was incorrect, DH gets refunded for the transaction costs and his reputation gets increased
 	// 		b. If DH didn't send the answer, or it was incorrect and the proof was correct, DC receives a proportional amount of token to the DH stake commited


 	// Answer/Proof verifiation:
 	// 	1. The data sent gets hashed
 	// 	2. The hash is hashed with the first hash in the array which DC sent. (Ordering of the hashes is determined by the index of the requested data)
 	// 	3. For the entire hash array the next item gets hashed together with the result of the previous iteration (with the ordering determined by the proper bit in hash_order_identification)
 	// 	4. At the end the result should be the root hash of the merkle tree of the entire data, hence it gets compared to the total_data_hash defined in the escrow
 	// 	5. If the hashes are equal the Answer/Proof is correct. Otherwise, it fails.

		enum LitigationStatus {inactive, initiated, answered, timed_out, completed}

		struct LitigationDefinition{
			uint requested_data_index;
			bytes32 requested_data;
			bytes32[] hash_array;
			uint litigation_start_time;
			LitigationStatus litigation_status;
		}

		event LitigationInitiated(bytes32 import_id, address DH_wallet, uint requested_data_index);
		event LitigationAnswered(bytes32 import_id, address DH_wallet);
		event LitigationTimedOut(bytes32 import_id, address DH_wallet);
		event LitigationCompleted(bytes32 import_id, address DH_wallet, bool DH_was_penalized);

		mapping(bytes32 => mapping ( address => LitigationDefinition)) public litigation;

		function initateLitigation(bytes32 import_id, address DH_wallet, uint requested_data_index, bytes32[] hash_array)
		public returns (bool newLitigationInitiated){
			LitigationDefinition storage this_litigation = litigation[import_id][DH_wallet];
			EscrowDefinition storage this_escrow = escrow[import_id][DH_wallet];

			require(this_escrow.DC_wallet == msg.sender && this_escrow.escrow_status == EscrowStatus.active);
			require(this_litigation.litigation_start_time == 0 || this_litigation.litigation_status == LitigationStatus.completed);

			this_litigation.requested_data_index = requested_data_index;
			this_litigation.hash_array = hash_array;
			this_litigation.litigation_start_time = block.timestamp;
			this_litigation.litigation_status = LitigationStatus.initiated;

			emit LitigationInitiated(import_id, DH_wallet, requested_data_index);
			return true;
		}

		function answerLitigation(bytes32 import_id, bytes32 requested_data)
		public returns (bool answer_accepted){
			LitigationDefinition storage this_litigation = litigation[import_id][msg.sender];
			EscrowDefinition storage this_escrow = escrow[import_id][msg.sender];

			require(this_litigation.litigation_start_time > 0 && this_litigation.litigation_status == LitigationStatus.initiated);

			if(block.timestamp > this_litigation.litigation_start_time + 30 minutes){
				this_litigation.litigation_status = LitigationStatus.completed;
				this_escrow.escrow_status = EscrowStatus.completed;
				//TODO Transfer remaining escrow tokens
				bidding.increaseBalance(this_escrow.DC_wallet, this_escrow.stake_amount);
				this_escrow.stake_amount = 0;
				emit LitigationTimedOut(import_id, msg.sender);
				return false;
			}
			else {
				this_litigation.requested_data = keccak256(requested_data, this_litigation.requested_data_index);
				// this_litigation.requested_data = keccak256(abi.encodePacked(requested_data, this_litigation.requested_data_index));
				emit LitigationAnswered(import_id, msg.sender);
				return true;
			}
		}

		function proveLitigaiton(bytes32 import_id, address DH_wallet, bytes32 proof_data)
		public returns (bool DH_was_penalized){
			LitigationDefinition storage this_litigation = litigation[import_id][DH_wallet];
			EscrowDefinition storage this_escrow = escrow[import_id][DH_wallet];

			require(this_escrow.DC_wallet == msg.sender && this_litigation.litigation_start_time > 0 && this_litigation.litigation_status != LitigationStatus.completed);

			if (block.timestamp > this_litigation.litigation_start_time + 30 minutes || this_litigation.litigation_status == LitigationStatus.initiated){
				this_litigation.litigation_status = LitigationStatus.completed;
				this_escrow.escrow_status = EscrowStatus.completed;
				bidding.increaseBalance(msg.sender, this_escrow.stake_amount);
				this_escrow.stake_amount = 0;
				// send tokens to DC
			}

			uint256 i = 0;
			uint256 one = 1;
			bytes32 proof_hash = keccak256(proof_data, this_litigation.requested_data_index);	
			// bytes32 proof_hash = keccak256(abi.encodePacked(proof_data, this_litigation.requested_data_index));	
			bytes32 answer_hash = this_litigation.requested_data;

			// ako je bit 1 on je levo
			while (i < this_litigation.hash_array.length){

				if( ((one << i) & this_litigation.requested_data_index) != 0 ){
					proof_hash = keccak256(this_litigation.hash_array[i], proof_hash);
					answer_hash = keccak256(this_litigation.hash_array[i], answer_hash);
					// proof_hash = keccak256(abi.encodePacked(this_litigation.hash_array[i], proof_hash));
					// answer_hash = keccak256(abi.encodePacked(this_litigation.hash_array[i], answer_hash));
				}
				else {
					proof_hash = keccak256(proof_hash, this_litigation.hash_array[i]);
					answer_hash = keccak256(answer_hash, this_litigation.hash_array[i]);
					// proof_hash = keccak256(abi.encodePacked(proof_hash, this_litigation.hash_array[i]));
					// answer_hash = keccak256(abi.encodePacked(answer_hash, this_litigation.hash_array[i]));
				}
				i++;
			}

			if(answer_hash == this_escrow.total_data_hash){
				this_litigation.litigation_status = LitigationStatus.completed;
				emit LitigationCompleted(import_id, DH_wallet, false);
				return false;
			}
			else {
				if(proof_hash == this_escrow.total_data_hash){
					bidding.increaseBalance(msg.sender, this_escrow.stake_amount);
					this_escrow.stake_amount = 0;
					this_litigation.litigation_status = LitigationStatus.completed;
					emit LitigationCompleted(import_id, DH_wallet, false);
				}
				this_litigation.litigation_status = LitigationStatus.completed;
				emit LitigationCompleted(import_id, DH_wallet, false);
				return false;
			}
		}


 }