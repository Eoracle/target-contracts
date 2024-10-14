import { initializeMCL, newKey, g2ToArray, g1ToArray, signMessageG1, g2FromArray } from './mcl';
import * as mcl from "mcl-wasm";
import { ethers } from "ethers";
import { MerkleTree } from 'merkletreejs';

const abiCoder = new ethers.AbiCoder();

function isBitOn(number: number, index: number): boolean {
    if (index < 1 || index > 32) {
        throw new Error('Index must be between 1 and 32.');
    }

    // Convert index from 1-32 range to 0-31 range for bitwise operation
    const bitPosition = index - 1;

    // Use bitwise AND to check if the bit at the specified position is set
    return (number & (1 << bitPosition)) !== 0;
}

interface IValidator {
    _address: string;
    g1pk: bigint[];
    g2pk: bigint[];
    votingPower: bigint;
}

interface ILeafInput {
    leafIndex: number;
    unhashedLeaf: string;
    proof?: string[]
}

async function run() {
    await initializeMCL();

    // full apk test - no non signers
    const leafInputs1: ILeafInput[] = [
        [1, 64000, 20398409483],
        [2, 3000, 20398409483],
        //        [3, 1300, 20398409483],
        //        [4, 800, 20398409483]
    ].map((d, i) => {
        const unhashedLeaf = abiCoder.encode(['uint16', 'uint256', 'uint64'], d);
        return {
            leafIndex: i + 1,
            unhashedLeaf,
        }
    });
    const tree1 = new MerkleTree(leafInputs1.map(d => ethers.keccak256(d.unhashedLeaf)), ethers.keccak256, { sort: true });
    const root1 = tree1.getRoot();
    leafInputs1.forEach((d, i) => {
        const leaf = ethers.keccak256(d.unhashedLeaf);
        const proof = tree1.getProof(leaf);
        d.proof = proof.map(p => '0x' + p.data.toString('hex'));
    })
    const block1 = 1;
    let _apkG2_1 = new mcl.G2();
    const nonSignersBitmap1 = '0x00';

    // second data set for testing partial signing but still within consensus threshold - 11/12 validators
    const leafInputs2: ILeafInput[] = [
        [1, 64001, 20398409484],
        [2, 3001, 20398409484]
    ].map((d, i) => {
        const unhashedLeaf = abiCoder.encode(['uint16', 'uint256', 'uint64'], d);
        return {
            leafIndex: i + 1,
            unhashedLeaf,
        }
    });
    const tree2 = new MerkleTree(leafInputs2.map(d => ethers.keccak256(d.unhashedLeaf)), ethers.keccak256, { sort: true });
    const root2 = tree2.getRoot();
    leafInputs2.forEach((d, i) => {
        d.proof = tree2.getProof(ethers.keccak256(d.unhashedLeaf)).map(p => '0x' + p.data.toString('hex'));
    })
    const block2 = 2;
    let _apkG2_2 = new mcl.G2();
    const nonSignersBitmap2 = '0x01';
    const secrets: bigint[] = [];
    const validators = []

    // third set of data for testing not enough voting power - we set only 1 validator posting a bogus value for the leaf 
    const leafInputs3: ILeafInput[] = [
        [1, 9999999999, 20398409484]
    ].map((d, i) => {
        const unhashedLeaf = abiCoder.encode(['uint16', 'uint256', 'uint64'], d);
        return {
            leafIndex: i + 1,
            unhashedLeaf,
        }
    });
    const tree3 = new MerkleTree(leafInputs3.map(d => ethers.keccak256(d.unhashedLeaf)), ethers.keccak256, { sort: true });
    const root3 = tree3.getRoot();
    leafInputs3.forEach((d, i) => {
        d.proof = tree3.getProof(ethers.keccak256(d.unhashedLeaf)).map(p => '0x' + p.data.toString('hex'));
    })
    const block3 = 3;
    let _apkG2_3 = new mcl.G2();
    const nonSignersBitmap3 = '0xfe'; // only one voter

    let _sig1: mcl.G1 = new mcl.G1(), _sig2: mcl.G1 = new mcl.G1(), _sig3: mcl.G1 = new mcl.G1();
    let msg1 = ethers.keccak256(ethers.solidityPacked(['bytes32', 'uint256'], [root1, block1]));
    let msg2 = ethers.keccak256(ethers.solidityPacked(['bytes32', 'uint256'], [root2, block2]));
    let msg3 = ethers.keccak256(ethers.solidityPacked(['bytes32', 'uint256'], [root3, block3]));
    for (let i = 0; i < 12; i++) {
        const { secret, g1pk, g2pk } = newKey();
        const g1pkArr = g1ToArray(g1pk);
        const g2pkArr = g2ToArray(g2pk);
        const v: IValidator = {
            _address: '0xf' + String(i).padStart(39, '0'),
            g1pk: g1pkArr,
            g2pk: g2pkArr,
            votingPower: BigInt(1000)
        }
        validators.push(v);
        secrets.push(BigInt(secret.getStr(10)));
        if (!isBitOn(ethers.toNumber(nonSignersBitmap1), i + 1)) {
            _apkG2_1 = mcl.add(_apkG2_1, g2FromArray(g2pkArr));
            const sig = signMessageG1(secret, msg1);
            _sig1 = mcl.add(_sig1, sig);
        }
        if (!isBitOn(ethers.toNumber(nonSignersBitmap2), i + 1)) {
            _apkG2_2 = mcl.add(_apkG2_2, g2pk);
            const sig = signMessageG1(secret, msg2);
            _sig2 = mcl.add(_sig2, sig);
        }

        if (!isBitOn(ethers.toNumber(nonSignersBitmap3), i + 1)) {
            _apkG2_3 = mcl.add(_apkG2_3, g2pk);
            const sig = signMessageG1(secret, msg3);
            _sig3 = mcl.add(_sig3, sig);
        }

    }
    const sig1 = g1ToArray(_sig1);
    const sig2 = g1ToArray(_sig2);
    const sig3 = g1ToArray(_sig3);
    const apkG2_1 = g2ToArray(_apkG2_1);
    const apkG2_2 = g2ToArray(_apkG2_2);
    const apkG2_3 = g2ToArray(_apkG2_3);

    // generate the full payload in one huge struct to preserve a shallow stack in solidity
    let decodedData = 'tuple(';
    [
        'tuple(address _address, uint256[2] g1pk, uint256[4] g2pk, uint256 votingPower)[] validators',
        'uint256[] secrets',

        'tuple(uint256 leafIndex, bytes unhashedLeaf, bytes32[] proof)[] leafInputs1',
        'bytes32 root1',
        'uint256 block1',
        'bytes nonSignersBitmap1',
        'uint256[2] signature1',
        'uint256[4] apkG2_1',

        'tuple(uint256 leafIndex, bytes unhashedLeaf, bytes32[] proof)[] leafInputs2',
        'bytes32 root2',
        'uint256 block2',
        'bytes nonSignersBitmap2',
        'uint256[2] signature2',
        'uint256[4] apkG2_2',

        'tuple(uint256 leafIndex, bytes unhashedLeaf, bytes32[] proof)[] leafInputs3',
        'bytes32 root3',
        'uint256 block3',
        'bytes nonSignersBitmap3',
        'uint256[2] signature3',
        'uint256[4] apkG2_3'
    ].forEach((t, i) => {
        if (i > 0) {
            decodedData += ',';
        }
        decodedData += t;
    });
    decodedData += ')';

    console.log(abiCoder.encode([
        decodedData
    ], [
        {
            validators,
            secrets,
            leafInputs1,
            root1,
            block1,
            nonSignersBitmap1: nonSignersBitmap1,
            signature1: sig1,
            apkG2_1: apkG2_1,
            leafInputs2,
            root2,
            block2,
            nonSignersBitmap2: nonSignersBitmap2,
            signature2: sig2,
            apkG2_2: apkG2_2,

            leafInputs3,
            root3,
            block3,
            nonSignersBitmap3: nonSignersBitmap3,
            signature3: sig3,
            apkG2_3: apkG2_3
        }
    ]));
}
run();
