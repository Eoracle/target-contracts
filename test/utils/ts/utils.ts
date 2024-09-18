import { randomBytes, hexlify, toBigInt } from "ethers";

export const FIELD_ORDER = toBigInt("0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47");

export function randHex(n: number): string {
  return hexlify(randomBytes(n));
}

export function to32Hex(n: bigint): string {
    return '0x' + n.toString(16).padStart(64, '0');
}

export function randFs(): bigint {
  const r = toBigInt(randomBytes(32));
  return r % FIELD_ORDER;
}
