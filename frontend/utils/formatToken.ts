import { formatUnits } from "ethers";

// decimals tiap token
const tokenDecimals: Record<string, number> = {
  BTC: 18,
  ETH: 18,
  USDT: 6,
  SOL: 9,
  ADA: 6,
};

// helper untuk convert scientific notation ke string utuh
function toFullString(value: string | number): string {
  if (typeof value === "number") return value.toLocaleString("fullwide", { useGrouping: false });
  if (typeof value === "string" && value.includes("e")) {
    return BigInt(value).toString(); // convert scientific to BigInt string
  }
  return value.toString();
}

export function formatTokenAmount(amount: string | number, token: string) {
  const decimals = tokenDecimals[token] ?? 18;
  const fullString = toFullString(amount);
  return formatUnits(fullString, decimals);
}
