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
        [2, 3000, 20398409483]
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
        d.proof = tree1.getProof(ethers.keccak256(d.unhashedLeaf)).map(p => '0x'+p.data.toString('hex'));
    })
    const block1 = 1;
    let _apkG2_1 = new mcl.G2();
    const nonSignersBitmap1 = '0x00';

    // second data set for testing partial signing but still within consensus threshold - 3/4 validators
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
        d.proof = tree2.getProof(ethers.keccak256(d.unhashedLeaf)).map(p => '0x'+p.data.toString('hex'));
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
    const root3 = tree2.getRoot();
    leafInputs3.forEach((d, i) => {
        d.proof = tree2.getProof(ethers.keccak256(d.unhashedLeaf)).map(p => '0x'+p.data.toString('hex'));
    })
    const block3 = 3;
    let _apkG2_3 = new mcl.G2();
    const nonSignersBitmap3 = '0x0e'; // only one voter

    let _sig1: mcl.G1 = new mcl.G1(), _sig2: mcl.G1 = new mcl.G1(), _sig3: mcl.G1 = new mcl.G1();
    let msg1 = ethers.keccak256(ethers.solidityPacked(['bytes32', 'uint256'], [root1, block1]));
    let msg2 = ethers.keccak256(ethers.solidityPacked(['bytes32', 'uint256'], [root2, block2]));
    let msg3 = ethers.keccak256(ethers.solidityPacked(['bytes32', 'uint256'], [root3, block3]));
    for (let i = 0; i < 4; i++) {
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

    // console.log('ROOT:       ' + root1.toString('hex'));
    // console.log('SIGNATURE:  ' + sig1);
    // console.log('APK G2:     ' + _apkG2_1.getStr(10));
    // console.log('MESSAGE G1: ' + hashToPoint(msg1, DOMAIN).getStr(10));
    // return
    // const verifyEthPairing = (a: bigint[], b: bigint[]) => {
    //     const a1: mcl.G1 = g1FromArray([BigInt(a[0]), BigInt(a[1])]);
    //     console.log('A1: ' + a1.getStr(10));
    //     const b1: mcl.G1 = g1FromArray([BigInt(b[0]), BigInt(b[1])]);
    //     console.log('B1: ' + b1.getStr(10));
    //     const a2: mcl.G2 = g2FromArray([BigInt(a[3]), BigInt(a[2]), BigInt(a[5]), BigInt(a[4])]);
    //     console.log('A2: ' + a2.getStr(10));
    //     const b2: mcl.G2 = g2FromArray([BigInt(b[3]), BigInt(b[2]), BigInt(b[5]), BigInt(b[4])]);
    //     console.log('B2: ' + b2.getStr(10));
    //     const pairing = mcl.mul(mcl.pairing(a1, a2), mcl.pairing(b1, b2));
    //     return toBigInt(pairing.serialize().reverse()); //to big endian
    // }
    // const ng2 = g2ToArray(mcl.neg(g2()));
    // const m = g1ToArray(hashToPoint(msg1, DOMAIN));
    // console.log('verify: ' + verifySignature(g2FromArray(apkG2_1), g1FromArray(sig1), msg1));
    // console.log('test: ' + mcl.mul(mcl.pairing(g1FromArray(sig1), g2FromArray(ng2)), mcl.pairing(g1FromArray(m), g2FromArray(apkG2_1))).serialize().reverse());
    // console.log(`[${sig1[0]}, ${sig1[1]}, ${ng2[1]}, ${ng2[0]} ${ng2[3]}, ${ng2[2]}], [${m[0]}, ${m[1]}, ${apkG2_1[1]}, ${apkG2_1[0]}, ${apkG2_1[3]}, ${apkG2_1[2]}]`);
    // console.log(g2ToArray(mcl.neg(g2())));
    // return;
//  [844632404156993305817852911303902622083885840228231898451395099306951798319, 19684076810391313060206141342967322552919068531712231534464901018889429706772, 11559732032986387107991004021392285783925812861821192530917403151452391805634, 10857046999023057135944570762232829481370756359578518086990519993285655852781, 17805874995975841540914202342111839520379459829704422454583296818431106115052, 13392588948715843804641432497768002650278120570034223513918757245338268106653], [6533196836614429860413573310143167080212049683150873056074392462148763921503, 16123913767699218274148335276855873513084001978894621429465889741282790581919, 17577399953798862380987573965590827693574145399306740271042783443046234111885, 15693991417947318966531622826694032461402158848772261947361879024777051464850, 21588438139864545175370857962783713312668744829732611604650631825903377461022, 3017895435737783597539696400846177338343684843429769397170398610139916504081]
//  [844632404156993305817852911303902622083885840228231898451395099306951798319, 19684076810391313060206141342967322552919068531712231534464901018889429706772, 11559732032986387107991004021392285783925812861821192530917403151452391805634, 10857046999023057135944570762232829481370756359578518086990519993285655852781, 17805874995975841540914202342111839520379459829704422454583296818431106115052, 13392588948715843804641432497768002650278120570034223513918757245338268106653], [16055256255278101123720674686003377966216868653318324755058358743374319087889, 4680274558307191975105661369765819689310076978632307758980931260666264665340, 17577399953798862380987573965590827693574145399306740271042783443046234111885, 15693991417947318966531622826694032461402158848772261947361879024777051464850, 21588438139864545175370857962783713312668744829732611604650631825903377461022, 3017895435737783597539696400846177338343684843429769397170398610139916504081]
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
