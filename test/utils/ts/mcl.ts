import * as mcl from 'mcl-wasm';
import { BigNumberish, ethers, getBytes } from "ethers";
import { randHex } from "./utils";
import { hexlify, toBigInt, keccak256, solidityPacked } from "ethers";
import { FIELD_ORDER, hashToField } from "./hashToField";

const DOMAIN = getBytes(keccak256(solidityPacked(["string"], ["EORACLE_FEED_VERIFIER"])));

const abiCoder = new ethers.AbiCoder();

export type mclG2 = any;
export type mclG1 = any;
export type mclFP = any;
export type mclFR = any;

export type SecretKey = mclFR;
export type MessagePoint = mclG1;
export type Signature = mclG1;
export type PublicKey = mclG2;

export type solG1 = [BigNumberish, BigNumberish];
export type solG2 = [BigNumberish, BigNumberish, BigNumberish, BigNumberish];

export interface KeyInfo {
    g1pk: mcl.G1;
    g2pk: mcl.G2;
    secret: mcl.Fr;
}

export type Domain = Uint8Array;

let zG1: mcl.Fp, zG2: mcl.Fp2;

export async function initializeMCL() {
    await mcl.init(mcl.BN_SNARK1);
    mcl.setMapToMode(mcl.BN254);
    mcl.setETHserialization(true);
    zG1 = new mcl.Fp();
    zG2 = new mcl.Fp2();
    zG1.setInt(1);
    zG2.setInt(1, 0);
}

export function validateDomain(domain: Domain) {
    if (domain.length != 32) {
      throw new Error("bad domain length");
    }
  }
  
  export function hashToPoint(msg: string, domain: Domain): MessagePoint {
    if (!ethers.isHexString(msg)) {
      throw new Error("message is expected to be hex string");
    }
  
    const _msg = getBytes(msg);
    const [e0, e1] = hashToField(domain, _msg, 2);
    const p0 = mapToPoint(e0);
    const p1 = mapToPoint(e1);
    const p: mcl.G1 = mcl.add(p0, p1);
    p.normalize();
    return p;
  }
  
export function mapToPoint(e0: bigint): mclG1 {
    let e1 = new mcl.Fp();
    e1.setStr((e0 % FIELD_ORDER).toString());
    return e1.mapToG1();
}
export function randFr(): mclFR {
    const r = randHex(12);
    let fr = new mcl.Fr();
    fr.setHashOf(r);
    return fr;
}

// Function to generate a private key
export function generatePrivateKey(): mcl.Fr {
    const privateKey = new mcl.Fr();
    privateKey.setByCSPRNG(); // Generate a random private key using a cryptographically secure random number generator
    return privateKey;
}

export function toBigEndian(p: mclFP): Uint8Array {
    // serialize() gets a little-endian output of Uint8Array
    // reverse() turns it into big-endian, which Solidity likes
    return p.serialize().reverse();
}

export function g1(): mclG1 {
    const g1 = new mcl.G1();
    g1.setStr("1 0x01 0x02", 16);
    return g1;
}
export function g2(): mclG2 {
    const g2 = new mcl.G2();
    g2.setStr(
      "1 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa 0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b"
    );
    return g2;
}
  
export function negateG2(): mclG2 {
    const g2 = new mcl.G2();
    g2.setStr(
      "1 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2 0x1d9befcd05a5323e6da4d435f3b617cdb3af83285c2df711ef39c01571827f9d 0x275dc4a288d1afb3cbb1ac09187524c7db36395df7be3b99e673b13a075a65ec"
    );
    return g2;
}
  

export function fromStringG1(s: string): mclG1 {
    const g1 = mcl.deserializeHexStrToG1(s);
    return g1;
}

export function fromStringG2(s: string): mclG2 {
    const g2 = mcl.deserializeHexStrToG2(s);
    return g2;
}

export function g1ToArray(p: mcl.G1): bigint[] {
    p.normalize();
    const x = hexlify(toBigEndian(p.getX()));
    const y = hexlify(toBigEndian(p.getY()));
    return [x, y].map(toBigInt);
}

export function g2ToArray(p: mcl.G2): bigint[] {
    p.normalize();
    const x = toBigEndian(p.getX());
    const x0 = hexlify(x.slice(32));
    const x1 = hexlify(x.slice(0, 32));
    const y = toBigEndian(p.getY());
    const y0 = hexlify(y.slice(32));
    const y1 = hexlify(y.slice(0, 32));
    return [BigInt(p.getX().get_a().getStr(10)), BigInt(p.getX().get_b().getStr(10)), BigInt(p.getY().get_a().getStr(10)), BigInt(p.getY().get_b().getStr(10))];
}

export function g1FromArray(arr: bigint[]): mcl.G1 {
    const p = new mcl.G1();
    p.setStr(`1 ${arr.map(a => `0x${a.toString(16)}`).join(' ')}`, 16);
    return p;
}

export function g2FromArray(arr: bigint[]): mcl.G2 {
    const p = new mcl.G2();
    p.setStr(`1 ${arr.map(a => `0x${a.toString(16)}`).join(' ')}`, 16);
    return p;
}

// note: enable this if you want to use the same secret key for all tests
//let currentSecret = 1;
export function newKey(): KeyInfo {
    const secret = randFr();
    //let secret = new mcl.Fr();
    //secret.setHashOf((currentSecret++).toString(16));

    const g1pk = getG1PublicKey(secret);
    const g2pk = getG2PublicKey(secret);
    return { secret, g1pk, g2pk };
}

export function getG1PublicKey(privateKey: mcl.Fr): mcl.G1 {
    const pubkey: mcl.G1 = <any>mcl.mul(g1(), privateKey);
    pubkey.normalize();
    return pubkey;
}
// Function to derive a G2 public key from a private key
export function getG2PublicKey(privateKey: mcl.Fr): mcl.G2 {
    const pubkey: mcl.G2 = <any>mcl.mul(g2(), privateKey);
    pubkey.normalize();
    return pubkey;
}

// Function to sign a message using the private key (signature in G1)
export function signMessageG1(privateKey: mcl.Fr, message: string): mcl.G1 {
    const msgHash: mcl.G1 = hashToPoint(message, DOMAIN); // Hash the message to a point in G1
    const signature = mcl.mul(msgHash, privateKey); // Multiply the hashed message by the private key to create the signature
    signature.normalize();
    return signature;
}

// Function to aggregate G2 public keys
export function aggregateG2PublicKeys(publicKeys: mcl.G2[]): mcl.G2 {
    let aggregatedKey = new mcl.G2();
    aggregatedKey.clear(); // Start with the identity element for G2
    publicKeys.forEach(pk => {
        aggregatedKey = mcl.add(aggregatedKey, pk); // Add each G2 public key to the aggregate
    });
    aggregatedKey.normalize();
    return aggregatedKey;
}

// Function to aggregate G1 signatures
export function aggregateG1Signatures(signatures: mcl.G1[]): mcl.G1 {
    let aggregatedSignature = new mcl.G1();
    aggregatedSignature.clear(); // Start with the identity element for G1
    mcl.add(signatures[0], signatures[1]);
    signatures.forEach(sig => {
        aggregatedSignature = mcl.add(aggregatedSignature, sig);
    }); // Add each G1 signature to the aggregate
    aggregatedSignature.normalize();
    return aggregatedSignature;
}

// Function to verify a signature
export function verifySignature(
    signature: mcl.G1,
    pubkey: mcl.G2,
    message: string | mcl.G1
): boolean {
    // e(σ, g2) = e(H(m), G2pk)
    const msgHash = typeof(message) === 'string' ? hashToPoint(message, DOMAIN) : message;// Hash the message to G1
    return mcl.pairing(signature, g2()).isEqual(mcl.pairing(msgHash, pubkey));
}

// Function to verify a signature and veracity of the g1/g2 apks
export function verifySignatureAndVeracity(
    pk1: mcl.G1,
    signature: mcl.G1,
    message: string | mcl.G1,
    pk2: mcl.G2
) {
    const msgHash = typeof(message) === 'string' ? hashToPoint(message, DOMAIN) : message;

    const _g = toBigInt(keccak256(abiCoder.encode(['uint256[2]', 'uint256[2]', 'uint256[4]', 'uint256[2]'],[
        g1ToArray(msgHash), 
        g1ToArray(pk1), 
        g2ToArray(pk2),
        g1ToArray(signature)
    ]))) % 21888242871839275222246405745257275088696311157297823662689037894645226208583n;
    const gamma = new mcl.Fr();
    gamma.setStr(_g.toString(), 10);

    // e(σ + γ·pk₁, G₂) = e(H(m) + γ·G₁ , pk₂)
    return mcl.pairing(mcl.add(signature, mcl.mul(pk1, gamma)), g2()).isEqual(mcl.pairing(mcl.add(msgHash, mcl.mul(g1(), gamma)), pk2));
}
