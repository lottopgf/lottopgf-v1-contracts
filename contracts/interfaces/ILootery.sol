// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IRandomiserCallback} from "./IRandomiserCallback.sol";

/// @title ILootery
/// @custom:version 1.3.0
/// @notice Lootery contract interface
interface ILootery is IRandomiserCallback, IERC721 {
    /// @notice Initial configuration of Lootery
    struct InitConfig {
        address owner;
        string name;
        string symbol;
        uint8 numPicks;
        uint8 maxBallValue;
        uint256 gamePeriod;
        uint256 ticketPrice;
        uint256 communityFeeBps;
        address randomiser;
        address prizeToken;
        uint256 seedJackpotDelay;
        uint256 seedJackpotMinValue;
        address ticketSVGRenderer;
    }

    /// @notice Current state of the lootery
    enum GameState {
        /// @notice Unitialised state, i.e. before the `init` function
        ///     has been called
        Uninitialised,
        /// @notice This is the only state where the jackpot can increase
        Purchase,
        /// @notice Waiting for VRF fulfilment
        DrawPending,
        /// @notice Lootery is closed (forever)
        Dead
    }

    struct CurrentGame {
        /// @notice aka uint8
        GameState state;
        /// @notice current gameId
        uint248 id;
    }

    /// @notice A ticket to be purchased
    struct Ticket {
        /// @notice For whomst shall this purchase be made out
        address whomst;
        /// @notice Lotto numbers, pick wisely! Picks must be ASCENDINGLY
        ///     ORDERED, with NO DUPLICATES!
        uint8[] picks;
    }

    struct Game {
        /// @notice Number of tickets sold per game
        uint64 ticketsSold;
        /// @notice Timestamp of when the game started
        uint64 startedAt;
        /// @notice Winning pick identity, once it's been drawn
        uint256 winningPickId;
    }

    /// @notice An already-purchased ticket, assigned to a tokenId
    struct PurchasedTicket {
        /// @notice gameId that ticket is valid for
        uint256 gameId;
        /// @notice Pick identity - see {Lootery-computePickIdentity}
        uint256 pickId;
    }

    /// @notice Describes an inflight randomness request
    struct RandomnessRequest {
        uint208 requestId;
        uint48 timestamp;
    }

    event TicketPurchased(
        uint256 indexed gameId,
        address indexed whomst,
        uint256 indexed tokenId,
        uint8[] picks
    );
    event BeneficiaryPaid(
        uint256 indexed gameId,
        address indexed beneficiary,
        uint256 value
    );
    event GameFinalised(uint256 gameId, uint8[] winningPicks);
    event Transferred(address to, uint256 value);
    event WinningsClaimed(
        uint256 indexed tokenId,
        uint256 indexed gameId,
        address whomst,
        uint256 value
    );
    event ConsolationClaimed(
        uint256 indexed tokenId,
        uint256 indexed gameId,
        address whomst,
        uint256 value
    );
    event DrawSkipped(uint256 indexed gameId);
    event Received(address sender, uint256 amount);
    event JackpotSeeded(address indexed whomst, uint256 amount);
    event JackpotRollover(
        uint256 indexed gameId,
        uint256 unclaimedPayouts,
        uint256 currentJackpot,
        uint256 nextUnclaimedPayouts,
        uint256 nextJackpot
    );
    event GasRefundAttempted(
        address indexed to,
        uint256 value,
        uint256 gasUsed,
        uint256 gasPrice,
        bool success
    );

    error TransferFailure(address to, uint256 value, bytes reason);
    error InvalidNumPicks(uint256 numPicks);
    error InvalidGamePeriod(uint256 gamePeriod);
    error InvalidTicketPrice(uint256 ticketPrice);
    error InvalidRandomiser(address randomiser);
    error InvalidPrizeToken(address prizeToken);
    error InvalidSeedJackpotConfig(uint256 delay, uint256 minValue);
    error IncorrectPaymentAmount(uint256 paid, uint256 expected);
    error InvalidTicketSVGRenderer(address renderer);
    error UnsortedPicks(uint8[] picks);
    error InvalidBallValue(uint256 ballValue);
    error GameAlreadyDrawn();
    error UnexpectedState(GameState actual);
    error RequestAlreadyInFlight(uint256 requestId, uint256 timestamp);
    error RequestIdOverflow(uint256 requestId);
    error CallerNotRandomiser(address caller);
    error RequestIdMismatch(uint256 actual, uint208 expected);
    error InsufficientRandomWords();
    error NoWin(uint256 pickId, uint256 winningPickId);
    error WaitLonger(uint256 deadline);
    error InsufficientOperationalFunds(uint256 have, uint256 want);
    error ClaimWindowMissed(uint256 tokenId);
    error GameInactive();
    error RateLimited(uint256 secondsToWait);
    error InsufficientJackpotSeed(uint256 value);

    /// @notice Initialises the contract instance
    function init(InitConfig memory initConfig) external;
}
