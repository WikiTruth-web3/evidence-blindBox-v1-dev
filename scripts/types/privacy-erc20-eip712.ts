import { CallFunctionParams } from "./call-params";

/**
 * EIP712 签名相关的结构体
 */
export interface ISignatureRSV {
    r: string;
    s: string;
    v: number | bigint;
}

export interface IEIP712Permit {
    label: number; // 0=VIEW, 1=TRANSFER, 2=APPROVE
    owner: string;
    spender: string;
    amount: bigint | string;
    deadline: number | bigint;
    signature: ISignatureRSV;
}
