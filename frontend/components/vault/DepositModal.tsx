"use client";

import React, { useState } from "react";
import {
  Button,
  Stack,
  Box,
  Text,
  Input,
} from "@chakra-ui/react";
import {
  Modal,
  ModalOverlay,
  ModalContent,
  ModalHeader,
  ModalBody,
  ModalFooter,
  ModalCloseButton,
} from "@chakra-ui/modal";
import { ethers, Eip1193Provider } from "ethers";

// ================= TYPES =================

type AssetSymbol = "BTC" | "ETH" | "USDT" | "SOL" | "ADA";

type EthereumProvider = {
  request: (args: { method: string; params?: unknown[] }) => Promise<unknown>;
};

const TOKEN_ADDRESSES: Record<AssetSymbol, string> = {
  BTC: process.env.NEXT_PUBLIC_TOKEN_BTC!,
  ETH: process.env.NEXT_PUBLIC_TOKEN_ETH!,
  USDT: process.env.NEXT_PUBLIC_TOKEN_USDT!,
  SOL: process.env.NEXT_PUBLIC_TOKEN_SOL!,
  ADA: process.env.NEXT_PUBLIC_TOKEN_ADA!,
};

const TOKEN_DECIMALS: Record<AssetSymbol, number> = {
  BTC: 18,
  ETH: 18,
  USDT: 6,
  SOL: 18,
  ADA: 18,
};

const VAULT_ADDRESS = process.env.NEXT_PUBLIC_SPOT_VAULT!;

// minimal ABI: approve saja, tanpa allowance
const ERC20_ABI = [
  "function approve(address spender, uint256 amount) external returns (bool)",
];

const VAULT_ABI = [
  "function deposit(address token, uint256 amount) external",
];

interface DepositModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
  userAddress?: string; // biar kompatibel sama pemanggilan lain
}

export default function DepositModal({
  isOpen,
  onClose,
  onSuccess,
}: DepositModalProps) {
  const [asset, setAsset] = useState<AssetSymbol>("BTC");
  const [amount, setAmount] = useState("");
  const [submitting, setSubmitting] = useState(false);

  async function handleDeposit() {
    if (typeof window === "undefined") return;

    const eth = (window as unknown as { ethereum?: EthereumProvider }).ethereum;
    if (!eth) {
      alert("MetaMask not detected");
      return;
    }

    if (!amount || Number(amount) <= 0) return;

    try {
      setSubmitting(true);

      const provider = new ethers.BrowserProvider(
        eth as Eip1193Provider
      );
      const signer = await provider.getSigner();

      const tokenAddress = TOKEN_ADDRESSES[asset];
      if (!tokenAddress || !VAULT_ADDRESS) {
        throw new Error("Token or Vault address missing");
      }

      const decimals = TOKEN_DECIMALS[asset];
      const parsedAmount = ethers.parseUnits(amount, decimals);

      const token = new ethers.Contract(tokenAddress, ERC20_ABI, signer);
      const vault = new ethers.Contract(VAULT_ADDRESS, VAULT_ABI, signer);

      // ==== 1️⃣ RESET APPROVE UNTUK USDT-LIKE TOKEN ====
      if (asset === "USDT") {
        const resetTx = await token.approve(VAULT_ADDRESS, BigInt(0));
        await resetTx.wait();
      }

      // ==== 2️⃣ APPROVE AMOUNT YANG DIBUTUHKAN ====
      const approveTx = await token.approve(VAULT_ADDRESS, parsedAmount);
      await approveTx.wait();

      // ==== 3️⃣ DEPOSIT KE VAULT ====
      const depositTx = await vault.deposit(tokenAddress, parsedAmount);
      await depositTx.wait();

      onSuccess?.();
      setAmount("");
      setAsset("BTC");
      onClose();
    } catch (err) {
      console.error("[DepositModal] deposit failed:", err);
      alert("Transaction failed. Check console for details.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <Modal isOpen={isOpen} onClose={onClose} motionPreset="scale">
      <ModalOverlay bg="blackAlpha.600" />
      <ModalContent maxW="480px">
        <ModalHeader>Deposit Asset</ModalHeader>
        <ModalCloseButton />

        <ModalBody>
          <Stack gap={4}>
            <Box>
              <Text fontSize="sm">Asset</Text>
              <select
                value={asset}
                onChange={(e) => setAsset(e.target.value as AssetSymbol)}
                style={{ width: "100%", padding: 8 }}
              >
                <option value="BTC">BTC</option>
                <option value="ETH">ETH</option>
                <option value="USDT">USDT</option>
                <option value="SOL">SOL</option>
                <option value="ADA">ADA</option>
              </select>
            </Box>

            <Box>
              <Text fontSize="sm">Amount</Text>
              <Input
                type="number"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
              />
            </Box>
          </Stack>
        </ModalBody>

        <ModalFooter>
          <Button onClick={onClose} variant="outline" mr={3}>
            Cancel
          </Button>
          <Button
            colorScheme="blue"
            onClick={handleDeposit}
            disabled={submitting}
          >
            {submitting ? "Depositing..." : "Deposit"}
          </Button>
        </ModalFooter>
      </ModalContent>
    </Modal>
  );
}
