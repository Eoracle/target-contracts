import { ethers } from "ethers";
import { MerkleTree } from "merkletreejs";
import * as mcl from "./mcl";
const input = process.argv[2];

let domain: any;

let validatorSecretKeys: any[] = [];
const validatorSetSize = Math.floor(Math.random() * (5 - 1) + 8); // Randomly pick 8 - 12
let aggMessagePoints: mcl.MessagePoint[] = [];
let accounts: any[] = [
  "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
  "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
  "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
  "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
  "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65",
  "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc",
  "0x976EA74026E726554dB657fA54763abd0C3a0aa9",
  "0x14dC79964da2C08b23698B3D3cc7Ca32193d9955",
  "0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f",
  "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720",
  "0xBcd4042DE499D14e55001CcbB24a551F3b954096",
  "0x71bE63f3384f5fb98995898A86B02Fb2426c5788",
];
let validatorSet: any[] = [];
const chainId = 1;
let eventRoot1: any;
let blockHash: any;
let currentValidatorSetHash: any;
let bitmaps: any[] = [];
let unhashedLeaves: any[] = [];
let proves: any[] = [];
let leavesArray: any[] = [];
let symbol: any[] = [];
let rate: any[] = [];
let timestamp: any[] = [];

async function generateMsg() {
  const argsLen = process.argv.length;
  const symbolArgs = process.argv.slice(3, argsLen);
  [domain] = ethers.utils.defaultAbiCoder.decode(["bytes32"], process.argv[2]);
  for (let i = 0; i < symbolArgs.length; i++) {
    [symbol[i], rate[i], timestamp[i]] = ethers.utils.defaultAbiCoder.decode(
      ["uint16", "uint256", "uint256"],
      symbolArgs[i],
    );
  }

  await mcl.init();

  validatorSet = [];
  for (let i = 0; i < validatorSetSize; i++) {
    const { pubkey, secret } = mcl.newKeyPair();
    validatorSecretKeys.push(secret);
    validatorSet.push({
      _address: accounts[i],
      blsKey: mcl.g2ToHex(pubkey),
      votingPower: ethers.utils.parseEther(((i + 1) * 2).toString()),
    });
  }

  blockHash = ethers.utils.hexlify(ethers.utils.randomBytes(32));
  currentValidatorSetHash = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["tuple(address _address, uint256[4] blsKey, uint256 votingPower)[]"],
      [validatorSet],
    ),
  );
  generateSignatureMultipleLeaves();

  const output = ethers.utils.defaultAbiCoder.encode(
    [
      "uint256",
      "tuple(address _address, uint256[4] blsKey, uint256 votingPower)[]",
      "uint256[2][]",
      "bytes32[]",
      "bytes[]",
      "bytes[]",
      "bytes32[][]",
      "bytes32[][]",
    ],
    [
      validatorSetSize,
      validatorSet,
      aggMessagePoints,
      [eventRoot1, blockHash, currentValidatorSetHash],
      bitmaps,
      unhashedLeaves,
      proves,
      leavesArray,
    ],
  );

  console.log(output);
}

function generateSignatureMultipleLeaves() {
  let leaves = [
    ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    ethers.utils.hexlify(ethers.utils.randomBytes(32)),
    ethers.utils.hexlify(ethers.utils.randomBytes(32)),
  ];

  const id = 0;
  const sender = accounts[0];
  const receiver = accounts[1];
  let _data;
  let _unhashedLeaf;
  for (let i = 0; i < symbol.length; i++) {
    _data = ethers.utils.defaultAbiCoder.encode(["uint16", "uint256", "uint256"], [symbol[i], rate[i], timestamp[i]]);
    _unhashedLeaf = ethers.utils.defaultAbiCoder.encode(
      ["uint", "address", "address", "bytes"],
      [id + i, sender, receiver, _data],
    );
    leaves[i] = ethers.utils.keccak256(_unhashedLeaf);

    unhashedLeaves.push(_unhashedLeaf);
  }

  const tree = new MerkleTree(leaves, ethers.utils.keccak256);

  eventRoot1 = tree.getHexRoot();
  const checkpoint = {
    epoch: 1,
    blockNumber: 1,
    eventRoot: eventRoot1,
  };

  const checkpointMetadata = {
    blockHash,
    blockRound: 0,
    currentValidatorSetHash,
  };

  const bitmap = "0xffff";
  const messageOfValidatorSet = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["tuple(address _address, uint256[4] blsKey, uint256 votingPower)[]"],
      [validatorSet],
    ),
  );

  const message = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["uint256", "uint256", "bytes32", "uint256", "uint256", "bytes32", "bytes32", "bytes32"],
      [
        chainId,
        checkpoint.blockNumber,
        checkpointMetadata.blockHash,
        checkpointMetadata.blockRound,
        checkpoint.epoch,
        checkpoint.eventRoot,
        checkpointMetadata.currentValidatorSetHash,
        messageOfValidatorSet,
      ],
    ),
  );

  const signatures: mcl.Signature[] = [];

  let aggVotingPower = 0;
  for (let i = 0; i < validatorSecretKeys.length; i++) {
    const byteNumber = Math.floor(i / 8);
    const bitNumber = i % 8;

    if (byteNumber >= bitmap.length / 2 - 1) {
      continue;
    }

    // Get the value of the bit at the given 'index' in a byte.
    const oneByte = parseInt(bitmap[2 + byteNumber * 2] + bitmap[3 + byteNumber * 2], 16);
    if ((oneByte & (1 << bitNumber)) > 0) {
      const { signature, messagePoint } = mcl.sign(message, validatorSecretKeys[i], ethers.utils.arrayify(domain));
      signatures.push(signature);
      aggVotingPower = validatorSet[i].votingPower.add(aggVotingPower);
    } else {
      continue;
    }
  }

  const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
  aggMessagePoints.push(aggMessagePoint);
  bitmaps.push(bitmap);

  const leafIndex = 0;

  for (let i = 0; i < symbol.length; i++) {
    const proof = tree.getHexProof(leaves[leafIndex + i]);
    proves.push(proof);
  }

  leavesArray.push(leaves);
}

generateMsg();
