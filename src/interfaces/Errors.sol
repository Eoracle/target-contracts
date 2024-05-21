// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/*//////////////////////////////////////////////////////////////////////////
                                EOFeedManager
//////////////////////////////////////////////////////////////////////////*/
error CallerIsNotWhitelisted(address caller);
error MissingLeafInputs();
error FeedNotSupported(uint16 feedId);
error BlockNumberAlreadyProcessed();

/*//////////////////////////////////////////////////////////////////////////
                                EOFeedVerifier
//////////////////////////////////////////////////////////////////////////*/
error FeedVerifierNotInitialized();
error InvalidProof();
error InvalidAddress();
error InvalidValidatorSetHash();
error InvalidEventRoot();
error VotingPowerIsZero();
error AggVotingPowerIsZero();
error InsufficientVotingPower();
error SignatureVerficationFailed();

/*//////////////////////////////////////////////////////////////////////////
                                EOFeedRegistryAdapter
//////////////////////////////////////////////////////////////////////////*/
error FeedAlreadyExists();
error BaseQuotePairExists();
