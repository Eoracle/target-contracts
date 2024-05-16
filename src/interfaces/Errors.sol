// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/*//////////////////////////////////////////////////////////////////////////
                                EOFeedRegistry
//////////////////////////////////////////////////////////////////////////*/
error CallerIsNotWhitelisted(address caller);
error MissingLeafInputs();
error SymbolNotSupported(uint16 symbol);
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
